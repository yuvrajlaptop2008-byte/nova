import Foundation
import NovaChatUI
import NovaKit
import NovaProtocol
import OSLog

struct IOSGatewayChatTransport: NovaChatTransport {
    static let logger = Logger(subsystem: "ai.novafoundation.app", category: "ios.chat.transport")
    private let gateway: GatewayNodeSession
    private let widgetGateway: GatewayNodeSession?
    private let globalAgentId: String?
    private let outboxGatewayID: String?
    private let sessionMutationRequest: (@Sendable (NovaChatGatewayRequest) async throws -> Data)?

    var outboxRequiresSessionRoutingContract: Bool {
        true
    }

    init(
        gateway: GatewayNodeSession,
        widgetGateway: GatewayNodeSession? = nil,
        globalAgentId: String? = nil,
        outboxGatewayID: String? = nil,
        sessionMutationRequest: (@Sendable (NovaChatGatewayRequest) async throws -> Data)? = nil)
    {
        self.gateway = gateway
        self.widgetGateway = widgetGateway
        let normalized = globalAgentId?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.globalAgentId = normalized?.isEmpty == false ? normalized : nil
        let normalizedGatewayID = outboxGatewayID?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.outboxGatewayID = normalizedGatewayID?.isEmpty == false ? normalizedGatewayID : nil
        self.sessionMutationRequest = sessionMutationRequest
    }

    func acquireOutboxRouteLease() async -> NovaChatTransportRouteLeaseResult {
        guard let outboxGatewayID,
              let route = await gateway.currentRoute(ifGatewayID: outboxGatewayID)
        else { return .unavailable(reason: nil) }
        guard let supportsRoutingContract = await gateway.supportsServerCapability(
            .chatSendRoutingContract,
            ifCurrentRoute: route)
        else { return .unavailable(reason: nil) }
        guard supportsRoutingContract else {
            return .unavailable(reason: NovaChatTransportUpgradeMessage.routingContract)
        }
        let transport = self
        guard let routingContract = try? await transport.sessionRoutingContract(ifCurrentRoute: route)
        else { return .unavailable(reason: nil) }
        return .available(NovaChatTransportRouteLease(
            sendTargetedMessage: { sessionKey, agentID, message, thinking, idempotencyKey, attachments in
                try await transport.sendMessage(
                    sessionKey: sessionKey,
                    agentID: agentID,
                    expectedSessionRoutingContract: routingContract,
                    message: message,
                    thinking: thinking,
                    idempotencyKey: idempotencyKey,
                    attachments: attachments,
                    ifCurrentRoute: route,
                    distinguishPreDispatchRouteChange: true)
            },
            requestTargetedHistory: { sessionKey, agentID in
                try await transport.requestHistory(
                    sessionKey: sessionKey,
                    agentID: agentID,
                    ifCurrentRoute: route)
            },
            sessionRoutingContract: routingContract))
    }

    func acquireSessionSettingsRouteLease() async -> NovaChatSessionSettingsRouteLease? {
        let route = await self.currentSessionMutationRoute()
        guard let route else { return nil }
        let transport = self
        return NovaChatSessionSettingsRouteLease { sessionKey, agentID, patch in
            try await transport.patchSessionSettings(
                sessionKey: sessionKey,
                agentID: agentID,
                patch: patch,
                ifCurrentRoute: route)
        }
    }

    func acquireSessionMutationRouteLease() async -> NovaChatSessionMutationRouteLease? {
        guard let route = await self.currentSessionMutationRoute() else { return nil }
        let transport = self
        return NovaChatSessionMutationRouteLease(
            patchSession: { key, label, category, pinned, archived, unread in
                let target = transport.sessionTarget(for: key)
                let request = NovaChatGatewayRequests.patchSession(
                    sessionKey: target.sessionKey,
                    agentID: target.agentID,
                    label: label,
                    category: category,
                    pinned: pinned,
                    archived: archived,
                    unread: unread)
                _ = try await transport.requestSessionMutation(request, ifCurrentRoute: route)
            },
            deleteSession: { key in
                let target = transport.sessionTarget(for: key)
                let request = NovaChatGatewayRequests.deleteSession(
                    sessionKey: target.sessionKey,
                    agentID: target.agentID)
                _ = try await transport.requestSessionMutation(request, ifCurrentRoute: route)
            })
    }

    func acquireSessionGroupsRouteLease() async -> NovaChatSessionGroupsRouteLease? {
        guard let route = await self.currentSessionMutationRoute() else { return nil }
        let transport = self
        return Self.makeSessionGroupsRouteLease { request in
            try await transport.requestSessionMutation(request, ifCurrentRoute: route)
        }
    }

    func acquireNewSessionRouteLease() async -> NovaChatNewSessionRouteLease? {
        guard let route = await self.currentSessionMutationRoute() else { return nil }
        let transport = self
        let request: @Sendable (NovaChatGatewayRequest) async throws -> Data = { request in
            try await transport.requestSessionMutation(request, ifCurrentRoute: route)
        }
        return NovaChatNewSessionRouteLease(
            listAgents: {
                let data = try await request(NovaChatGatewayRequests.agentsList())
                let result = try JSONDecoder().decode(AgentsListResult.self, from: data)
                return NovaChatAgentsListResponse(
                    defaultId: result.defaultid,
                    agents: result.agents.map {
                        NovaChatAgentChoice(
                            id: $0.id,
                            name: $0.name,
                            workspaceGit: $0.workspacegit)
                    })
            },
            createSession: { key, label, agentID, parentSessionKey, worktree, worktreeBaseRef in
                let createRequest = transport.createSessionRequest(
                    key: key,
                    label: label,
                    agentID: agentID,
                    parentSessionKey: parentSessionKey,
                    worktree: worktree,
                    worktreeBaseRef: worktreeBaseRef)
                let data = try await request(createRequest)
                return try JSONDecoder().decode(NovaChatCreateSessionResponse.self, from: data)
            })
    }

    private func currentSessionMutationRoute() async -> GatewayNodeSessionRoute? {
        if let outboxGatewayID {
            return await self.gateway.currentRoute(ifGatewayID: outboxGatewayID)
        }
        return await self.gateway.currentRoute()
    }

    private func sessionRoutingContract(
        ifCurrentRoute route: GatewayNodeSessionRoute) async throws -> String
    {
        let data = try await gateway.request(
            NovaChatGatewayRequests.agentsList(),
            ifCurrentRoute: route)
        return try NovaChatGatewayPayloadCodec.decodeSessionRoutingIdentity(data).contract
    }

    typealias SessionTarget = NovaChatSessionTarget

    static func sessionTarget(
        for rawSessionKey: String,
        selectedAgentID: String?,
        overrideAgentID: String? = nil) -> SessionTarget
    {
        NovaChatSessionTarget.resolve(
            rawSessionKey,
            selectedAgentID: selectedAgentID,
            overrideAgentID: overrideAgentID,
            policy: .scopeBareKeysToSelectedAgent)
    }

    private func sessionTarget(
        for sessionKey: String,
        overrideAgentID: String? = nil) -> SessionTarget
    {
        Self.sessionTarget(
            for: sessionKey,
            selectedAgentID: self.globalAgentId,
            overrideAgentID: overrideAgentID)
    }

    private func requestSessionMutation(_ request: NovaChatGatewayRequest) async throws -> Data {
        if let sessionMutationRequest {
            return try await sessionMutationRequest(request)
        }
        return try await self.gateway.request(request)
    }

    private func requestSessionMutation(
        _ request: NovaChatGatewayRequest,
        ifCurrentRoute route: GatewayNodeSessionRoute) async throws -> Data
    {
        try await self.gateway.request(
            request,
            ifCurrentRoute: route,
            distinguishPreDispatchRouteChange: true)
    }

    static func makeSessionGroupsRouteLease(
        request: @escaping @Sendable (NovaChatGatewayRequest) async throws -> Data)
        -> NovaChatSessionGroupsRouteLease
    {
        NovaChatSessionGroupsRouteLease(
            listGroups: {
                let data = try await request(NovaChatGatewayRequests.sessionGroupsList())
                return try JSONDecoder().decode(NovaChatSessionGroupsResponse.self, from: data)
            },
            putGroups: { names in
                let data = try await request(NovaChatGatewayRequests.sessionGroupsPut(names: names))
                return try JSONDecoder().decode(NovaChatSessionGroupsMutationResponse.self, from: data)
            },
            renameGroup: { name, to in
                let data = try await request(NovaChatGatewayRequests.sessionGroupsRename(name: name, to: to))
                return try JSONDecoder().decode(NovaChatSessionGroupsMutationResponse.self, from: data)
            },
            deleteGroup: { name in
                let data = try await request(NovaChatGatewayRequests.sessionGroupsDelete(name: name))
                return try JSONDecoder().decode(NovaChatSessionGroupsMutationResponse.self, from: data)
            })
    }

    func createSession(
        key: String,
        label: String?,
        parentSessionKey: String?,
        worktree: Bool?) async throws -> NovaChatCreateSessionResponse
    {
        try await self.createSession(
            key: key,
            label: label,
            agentID: nil,
            parentSessionKey: parentSessionKey,
            worktree: worktree,
            worktreeBaseRef: nil)
    }

    func createSession(
        key: String,
        label: String?,
        agentID: String?,
        parentSessionKey: String?,
        worktree: Bool?,
        worktreeBaseRef: String?) async throws -> NovaChatCreateSessionResponse
    {
        let request = self.createSessionRequest(
            key: key,
            label: label,
            agentID: agentID,
            parentSessionKey: parentSessionKey,
            worktree: worktree,
            worktreeBaseRef: worktreeBaseRef)
        let res = try await self.requestSessionMutation(request)
        return try JSONDecoder().decode(NovaChatCreateSessionResponse.self, from: res)
    }

    private func createSessionRequest(
        key: String,
        label: String?,
        agentID: String?,
        parentSessionKey: String?,
        worktree: Bool?,
        worktreeBaseRef: String?) -> NovaChatGatewayRequest
    {
        let target = self.sessionTarget(for: key, overrideAgentID: agentID)
        let parentTarget = parentSessionKey.map { self.sessionTarget(for: $0) }
        let explicitAgentID = agentID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return NovaChatGatewayRequests.createSession(
            key: target.sessionKey,
            agentID: explicitAgentID?.isEmpty == false
                ? explicitAgentID
                : target.agentID ?? parentTarget?.agentID,
            label: label,
            parentSessionKey: parentTarget?.sessionKey,
            worktree: worktree,
            worktreeBaseRef: worktreeBaseRef)
    }

    func abortRun(sessionKey: String, runId: String) async throws {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.abortRun(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            runID: runId)
        _ = try await self.gateway.request(request)
    }

    func listSessions(
        limit: Int?,
        search: String?,
        archived: Bool) async throws -> NovaChatSessionsListResponse
    {
        let request = NovaChatGatewayRequests.sessionsList(
            limit: limit,
            search: search,
            archived: archived)
        let res = try await gateway.request(request)
        return try JSONDecoder().decode(NovaChatSessionsListResponse.self, from: res)
    }

    func listModels() async throws -> [NovaChatModelChoice] {
        let response = try await gateway.request(NovaChatGatewayRequests.modelsList())
        return try NovaChatGatewayPayloadCodec.decodeModelChoices(response)
    }

    func setSessionModel(sessionKey: String, model: String?) async throws {
        _ = try await self.patchSessionModel(sessionKey: sessionKey, agentID: nil, model: model)
    }

    func patchSessionModel(
        sessionKey: String,
        agentID: String?,
        model: String?) async throws -> NovaChatModelPatchResult?
    {
        try await self.patchSessionSettings(
            sessionKey: sessionKey,
            agentID: agentID,
            patch: NovaChatSessionSettingsPatch(model: .some(model)))
    }

    func patchSessionSettings(
        sessionKey: String,
        agentID: String?,
        patch: NovaChatSessionSettingsPatch) async throws -> NovaChatModelPatchResult?
    {
        try await self.patchSessionSettings(
            sessionKey: sessionKey,
            agentID: agentID,
            patch: patch,
            ifCurrentRoute: nil)
    }

    private func patchSessionSettings(
        sessionKey: String,
        agentID: String?,
        patch: NovaChatSessionSettingsPatch,
        ifCurrentRoute expectedRoute: GatewayNodeSessionRoute?) async throws -> NovaChatModelPatchResult?
    {
        let target = self.sessionTarget(for: sessionKey, overrideAgentID: agentID)
        let request = NovaChatGatewayRequests.patchSessionSettings(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            model: patch.model,
            thinkingLevel: patch.thinkingLevel,
            fastMode: patch.fastMode,
            verboseLevel: patch.verboseLevel)
        let response = if let expectedRoute {
            try await self.gateway.request(
                request,
                ifCurrentRoute: expectedRoute,
                distinguishPreDispatchRouteChange: true)
        } else {
            try await self.requestSessionMutation(request)
        }
        return try Self.decodeModelPatchResult(response)
    }

    static func decodeModelPatchResult(_ data: Data) throws -> NovaChatModelPatchResult {
        try JSONDecoder().decode(NovaChatModelPatchResult.self, from: data)
    }

    func setSessionThinking(sessionKey: String, thinkingLevel: String) async throws {
        let target = self.sessionTarget(for: sessionKey)
        _ = try await self.patchSessionSettings(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            patch: NovaChatSessionSettingsPatch(thinkingLevel: .some(thinkingLevel)))
    }

    func patchSession(
        key: String,
        label: String?? = nil,
        category: String?? = nil,
        pinned: Bool? = nil,
        archived: Bool? = nil,
        unread: Bool? = nil) async throws
    {
        let target = self.sessionTarget(for: key)
        let request = NovaChatGatewayRequests.patchSession(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            label: label,
            category: category,
            pinned: pinned,
            archived: archived,
            unread: unread)
        _ = try await self.requestSessionMutation(request)
    }

    func deleteSession(key: String) async throws {
        let target = self.sessionTarget(for: key)
        let request = NovaChatGatewayRequests.deleteSession(
            sessionKey: target.sessionKey,
            agentID: target.agentID)
        _ = try await self.requestSessionMutation(request)
    }

    func forkSession(parentKey: String) async throws -> String {
        let target = self.sessionTarget(for: parentKey)
        let childAgentID = target.agentID ?? NovaChatSessionKey.agentID(from: target.sessionKey)
        let request = NovaChatGatewayRequests.forkSession(
            parentSessionKey: target.sessionKey,
            agentID: childAgentID)
        let response = try await requestSessionMutation(request)
        return try JSONDecoder().decode(NovaChatCreateSessionResponse.self, from: response).key
    }

    func rewindSession(
        sessionKey: String,
        entryId: String) async throws -> NovaChatRewindResponse
    {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.rewindSession(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            entryId: entryId)
        let response = try await self.requestSessionMutation(request)
        return try JSONDecoder().decode(NovaChatRewindResponse.self, from: response)
    }

    func forkSessionAtMessage(
        sessionKey: String,
        entryId: String) async throws -> NovaChatForkAtMessageResponse
    {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.forkAtMessage(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            entryId: entryId)
        let response = try await self.requestSessionMutation(request)
        return try JSONDecoder().decode(NovaChatForkAtMessageResponse.self, from: response)
    }

    func setActiveSessionKey(_ sessionKey: String) async throws {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.subscribeSessionMessages(
            sessionKey: target.sessionKey,
            agentID: target.agentID)
        _ = try await self.gateway.request(request)
    }

    func resetSession(sessionKey: String) async throws {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.resetSession(
            sessionKey: target.sessionKey,
            agentID: target.agentID)
        _ = try await self.gateway.request(request)
    }

    func compactSession(sessionKey: String) async throws {
        let target = self.sessionTarget(for: sessionKey)
        let request = NovaChatGatewayRequests.compactSession(
            sessionKey: target.sessionKey,
            agentID: target.agentID)
        let response = try await gateway.request(request)
        try NovaSessionsCompactResponse.requireSuccess(from: response)
    }

    func requestHistory(sessionKey: String) async throws -> NovaChatHistoryPayload {
        try await self.requestHistory(sessionKey: sessionKey, agentID: nil, ifCurrentRoute: nil)
    }

    func resolveInlineWidgetResource(
        path: String,
        replacing failedResource: NovaChatWidgetResource?) async -> NovaChatWidgetResource?
    {
        let gateway = self.gateway
        let widgetGateway = self.widgetGateway
        return await NovaChatWidgetURLResolver.resolveResource(
            target: path,
            replacing: failedResource,
            currentSurfaceRoutes: {
                let node = await widgetGateway?.currentCanvasHostRoute()
                let operatorSurface = await gateway.currentCanvasHostRoute()
                return (node: node, operatorSurface: operatorSurface)
            },
            // Prefer the device's node route; operator rotation covers clients
            // whose node role is unavailable or intentionally disabled.
            refreshNodeSurfaceRoute: { observed in
                await widgetGateway?.refreshCanvasHostRoute(replacing: observed?.url)
            },
            refreshOperatorSurfaceRoute: { observed in
                await gateway.refreshCanvasHostRoute(replacing: observed?.url)
            })
    }

    func resolveInlineWidgetURL(path: String, replacing failedURL: URL?) async -> URL? {
        await self.resolveInlineWidgetResource(
            path: path,
            replacing: failedURL.map { NovaChatWidgetResource(url: $0) })?.url
    }

    func requestHistory(
        sessionKey: String,
        agentID: String? = nil,
        ifCurrentRoute expectedRoute: GatewayNodeSessionRoute?) async throws -> NovaChatHistoryPayload
    {
        let target = self.sessionTarget(for: sessionKey, overrideAgentID: agentID)
        let request = NovaChatGatewayRequests.history(
            sessionKey: target.sessionKey,
            agentID: target.agentID)
        let res = try await gateway.request(
            request,
            ifCurrentRoute: expectedRoute)
        return try JSONDecoder().decode(NovaChatHistoryPayload.self, from: res)
    }

    var supportsSlashCommandCatalog: Bool {
        true
    }

    func listCommands(sessionKey: String) async throws -> [NovaChatCommandChoice] {
        let request = NovaChatGatewayRequests.commandsList(
            sessionKey: sessionKey,
            fallbackAgentID: self.globalAgentId)
        let res = try await gateway.request(request)
        let decoded = try JSONDecoder().decode(CommandsListResult.self, from: res)
        return decoded.commands.map(NovaChatGatewayPayloadCodec.commandChoice)
    }

    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [NovaChatAttachmentPayload]) async throws -> NovaChatSendResponse
    {
        try await self.sendMessage(
            sessionKey: sessionKey,
            agentID: nil,
            message: message,
            thinking: thinking,
            idempotencyKey: idempotencyKey,
            attachments: attachments,
            ifCurrentRoute: nil)
    }

    func sendMessage(
        sessionKey: String,
        agentID: String?,
        expectedSessionRoutingContract: String?,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [NovaChatAttachmentPayload]) async throws -> NovaChatSendResponse
    {
        let route: GatewayNodeSessionRoute? = if let outboxGatewayID {
            await self.gateway.currentRoute(ifGatewayID: outboxGatewayID)
        } else {
            await self.gateway.currentRoute()
        }
        guard let route,
              let supportsRoutingContract = await gateway.supportsServerCapability(
                  .chatSendRoutingContract,
                  ifCurrentRoute: route)
        else { throw NovaChatTransportSendError.notDispatched }
        // Durable replay requires the atomic server guard and is blocked in
        // acquireOutboxRouteLease. Keep ordinary live chat compatible with
        // older gateways by retaining the captured route but omitting the
        // unsupported request field.
        let guardedContract = NovaChatSessionRoutingContract.expectedValue(
            expectedSessionRoutingContract,
            serverSupportsGuard: supportsRoutingContract)
        return try await self.sendMessage(
            sessionKey: sessionKey,
            agentID: agentID,
            expectedSessionRoutingContract: guardedContract,
            message: message,
            thinking: thinking,
            idempotencyKey: idempotencyKey,
            attachments: attachments,
            ifCurrentRoute: route,
            distinguishPreDispatchRouteChange: true)
    }

    func sendMessage(
        sessionKey: String,
        agentID: String? = nil,
        expectedSessionRoutingContract: String? = nil,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [NovaChatAttachmentPayload],
        ifCurrentRoute expectedRoute: GatewayNodeSessionRoute?,
        distinguishPreDispatchRouteChange: Bool = false) async throws -> NovaChatSendResponse
    {
        let target = self.sessionTarget(for: sessionKey, overrideAgentID: agentID)
        let startLogMessage =
            "chat.send start sessionKey=\(target.sessionKey) "
                + "len=\(message.count) attachments=\(attachments.count)"
        Self.logger.info(
            "\(startLogMessage, privacy: .public)")
        GatewayDiagnostics.log(startLogMessage)
        let request = NovaChatGatewayRequests.sendMessage(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            expectedSessionRoutingContract: expectedSessionRoutingContract,
            message: message,
            thinking: thinking,
            idempotencyKey: idempotencyKey,
            attachments: attachments)
        do {
            let res = try await gateway.request(
                request,
                ifCurrentRoute: expectedRoute,
                distinguishPreDispatchRouteChange: distinguishPreDispatchRouteChange)
            let decoded = try JSONDecoder().decode(NovaChatSendResponse.self, from: res)
            Self.logger.info("chat.send ok runId=\(decoded.runId, privacy: .public)")
            GatewayDiagnostics.log("chat.send ok runId=\(decoded.runId) status=\(decoded.status)")
            return decoded
        } catch is GatewayNodeSessionRequestError {
            Self.logger.info("chat.send skipped because the captured route changed before dispatch")
            GatewayDiagnostics.log("chat.send skipped before dispatch: route changed")
            throw NovaChatTransportSendError.notDispatched
        } catch {
            Self.logger.error("chat.send failed \(error.localizedDescription, privacy: .public)")
            GatewayDiagnostics.log("chat.send failed error=\(error.localizedDescription)")
            throw error
        }
    }

    func waitForRunCompletion(
        runId rawRunId: String,
        timeoutMs: Int) async -> NovaChatRunObservation
    {
        let route = await self.gateway.currentRoute()
        return await self.waitForRunCompletion(
            runId: rawRunId,
            timeoutMs: timeoutMs,
            ifCurrentRoute: route)
    }

    func waitForRunCompletion(
        runId rawRunId: String,
        timeoutMs: Int,
        ifCurrentRoute expectedRoute: GatewayNodeSessionRoute?) async -> NovaChatRunObservation
    {
        let runId = rawRunId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !runId.isEmpty, let expectedRoute else { return .unavailable }

        do {
            let request = NovaChatGatewayRequests.agentWait(runID: runId, timeoutMs: timeoutMs)
            GatewayDiagnostics.log("agent.wait start runId=\(runId)")
            let res = try await gateway.request(
                request,
                ifCurrentRoute: expectedRoute)
            let observation = try NovaChatGatewayPayloadCodec.decodeAgentWaitObservation(res)
            GatewayDiagnostics.log("agent.wait completed runId=\(runId) observation=\(observation)")
            return observation
        } catch {
            Self.logger.warning("agent.wait failed \(error.localizedDescription, privacy: .public)")
            GatewayDiagnostics.log("agent.wait failed runId=\(runId) error=\(error.localizedDescription)")
            return .unavailable
        }
    }

    func requestHealth(timeoutMs: Int) async throws -> Bool {
        let res = try await gateway.request(NovaChatGatewayRequests.health(timeoutMs: timeoutMs))
        return (try? JSONDecoder().decode(NovaGatewayHealthOK.self, from: res))?.ok ?? true
    }

    func listQuestions() async throws -> [QuestionRecord] {
        let data = try await self.gateway.request(NovaChatGatewayRequests.questionList())
        return try JSONDecoder().decode(QuestionListResult.self, from: data).questions
    }

    func getQuestion(id: String) async throws -> QuestionRecord {
        let data = try await self.gateway.request(NovaChatGatewayRequests.questionGet(id: id))
        return try JSONDecoder().decode(QuestionGetResult.self, from: data).question
    }

    func resolveQuestion(id: String, answers: [String: [String]]) async throws {
        _ = try await self.gateway.request(NovaChatGatewayRequests.resolveQuestion(id: id, answers: answers))
    }

    func cancelQuestion(id: String) async throws {
        _ = try await self.gateway.request(NovaChatGatewayRequests.cancelQuestion(id: id))
    }

    func events() -> AsyncStream<NovaChatTransportEvent> {
        AsyncStream { continuation in
            let task = Task {
                let stream = await self.gateway.subscribeServerEvents()
                for await evt in stream {
                    if Task.isCancelled { return }
                    if let mapped = NovaChatGatewayPayloadCodec.event(from: evt) {
                        continuation.yield(mapped)
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
