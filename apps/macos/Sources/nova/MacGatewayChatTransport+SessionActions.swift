import Foundation
import NovaChatUI
import NovaProtocol

extension MacGatewayChatTransport {
    func acquireNewSessionRouteLease() async -> NovaChatNewSessionRouteLease? {
        guard let serverLease = await GatewayConnection.shared.captureServerLease() else { return nil }
        if let outboxGatewayID {
            let currentGatewayID = await MainActor.run { MacChatTranscriptCache.currentGatewayID() }
            guard currentGatewayID == outboxGatewayID else { return nil }
        }
        let request: @Sendable (NovaChatGatewayRequest) async throws -> Data = { request in
            try await GatewayConnection.shared.request(
                method: request.method,
                params: request.params,
                timeoutMs: request.timeoutMs,
                ifCurrentServerLease: serverLease)
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
            createSession: { key, label, explicitAgentID, parentSessionKey, worktree, worktreeBaseRef in
                let agentID = explicitAgentID
                    ?? NovaChatSessionKey.agentID(from: key)
                    ?? parentSessionKey.flatMap { NovaChatSessionKey.agentID(from: $0) }
                let createRequest = NovaChatGatewayRequests.createSession(
                    key: key,
                    agentID: agentID,
                    label: label,
                    parentSessionKey: parentSessionKey,
                    worktree: worktree,
                    worktreeBaseRef: worktreeBaseRef)
                let data = try await request(createRequest)
                return try JSONDecoder().decode(NovaChatCreateSessionResponse.self, from: data)
            })
    }

    func acquireSessionGroupsRouteLease() async -> NovaChatSessionGroupsRouteLease? {
        guard let serverLease = await GatewayConnection.shared.captureServerLease() else { return nil }
        if let outboxGatewayID {
            let currentGatewayID = await MainActor.run { MacChatTranscriptCache.currentGatewayID() }
            guard currentGatewayID == outboxGatewayID else { return nil }
        }
        let request: @Sendable (NovaChatGatewayRequest) async throws -> Data = { request in
            try await GatewayConnection.shared.request(
                method: request.method,
                params: request.params,
                timeoutMs: request.timeoutMs,
                ifCurrentServerLease: serverLease)
        }
        return NovaChatSessionGroupsRouteLease(
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

    func acquireSessionMutationRouteLease() async -> NovaChatSessionMutationRouteLease? {
        guard let serverLease = await GatewayConnection.shared.captureServerLease() else { return nil }
        if let outboxGatewayID {
            let currentGatewayID = await MainActor.run { MacChatTranscriptCache.currentGatewayID() }
            guard currentGatewayID == outboxGatewayID else { return nil }
        }
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
                _ = try await GatewayConnection.shared.request(
                    method: request.method,
                    params: request.params,
                    timeoutMs: request.timeoutMs,
                    ifCurrentServerLease: serverLease)
            },
            deleteSession: { key in
                let target = transport.sessionTarget(for: key)
                let request = NovaChatGatewayRequests.deleteSession(
                    sessionKey: target.sessionKey,
                    agentID: target.agentID)
                _ = try await GatewayConnection.shared.request(
                    method: request.method,
                    params: request.params,
                    timeoutMs: request.timeoutMs,
                    ifCurrentServerLease: serverLease)
            })
    }

    private func requestSessionAction(_ request: NovaChatGatewayRequest) async throws -> Data {
        guard let serverLease = await GatewayConnection.shared.captureServerLease() else {
            throw NovaChatTransportSendError.notDispatched
        }
        if let outboxGatewayID {
            let currentGatewayID = await MainActor.run { MacChatTranscriptCache.currentGatewayID() }
            guard currentGatewayID == outboxGatewayID else {
                throw NovaChatTransportSendError.notDispatched
            }
        }
        return try await GatewayConnection.shared.request(
            method: request.method,
            params: request.params,
            timeoutMs: request.timeoutMs,
            ifCurrentServerLease: serverLease)
    }

    func forkSession(parentKey: String) async throws -> String {
        let target = self.sessionTarget(for: parentKey)
        let request = NovaChatGatewayRequests.forkSession(
            parentSessionKey: target.sessionKey,
            agentID: target.agentID)
        let data = try await self.requestSessionAction(request)
        return try JSONDecoder().decode(NovaChatCreateSessionResponse.self, from: data).key
    }

    func rewindSession(
        sessionKey: String,
        entryId: String) async throws -> NovaChatRewindResponse
    {
        let target = self.sessionTarget(for: sessionKey)
        let request = Self.rewindSessionRequest(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            entryId: entryId)
        let data = try await self.requestSessionAction(request)
        return try JSONDecoder().decode(NovaChatRewindResponse.self, from: data)
    }

    func forkSessionAtMessage(
        sessionKey: String,
        entryId: String) async throws -> NovaChatForkAtMessageResponse
    {
        let target = self.sessionTarget(for: sessionKey)
        let request = Self.forkSessionAtMessageRequest(
            sessionKey: target.sessionKey,
            agentID: target.agentID,
            entryId: entryId)
        let data = try await self.requestSessionAction(request)
        return try JSONDecoder().decode(NovaChatForkAtMessageResponse.self, from: data)
    }

    static func rewindSessionRequest(
        sessionKey: String,
        agentID: String?,
        entryId: String) -> NovaChatGatewayRequest
    {
        NovaChatGatewayRequests.rewindSession(
            sessionKey: sessionKey,
            agentID: agentID,
            entryId: entryId)
    }

    static func forkSessionAtMessageRequest(
        sessionKey: String,
        agentID: String?,
        entryId: String) -> NovaChatGatewayRequest
    {
        NovaChatGatewayRequests.forkAtMessage(
            sessionKey: sessionKey,
            agentID: agentID,
            entryId: entryId)
    }
}
