import Foundation
import NovaKit
import NovaProtocol
import Testing
@testable import NovaChatUI

private func chatTextMessage(
    role: String,
    text: String,
    timestamp: Double,
    contentId: String? = nil,
    idempotencyKey: String? = nil) -> AnyCodable
{
    var content: [String: Any] = ["type": "text", "text": text]
    if let contentId {
        content["id"] = contentId
    }
    var message: [String: Any] = [
        "role": role,
        "content": [content],
        "timestamp": timestamp,
    ]
    if let idempotencyKey {
        message["__nova"] = ["idempotencyKey": idempotencyKey]
    }
    return AnyCodable(message)
}

private func chatTextModelMessage(
    role: String,
    text: String,
    timestamp: Double,
    idempotencyKey: String? = nil) -> NovaChatMessage
{
    NovaChatMessage(
        role: role,
        content: [
            NovaChatMessageContent(
                type: "text",
                text: text,
                mimeType: nil,
                fileName: nil,
                content: nil),
        ],
        timestamp: timestamp,
        idempotencyKey: idempotencyKey)
}

private func chatErrorMessage(role: String, errorMessage: String, timestamp: Double) -> AnyCodable {
    AnyCodable([
        "role": role,
        "content": [],
        "timestamp": timestamp,
        "stopReason": "error",
        "errorMessage": errorMessage,
    ])
}

extension [NovaChatMessage] {
    fileprivate func containsUserText(_ text: String) -> Bool {
        contains { message in
            message.role == "user" &&
                message.content.contains { $0.text == text }
        }
    }
}

private func historyPayload(
    sessionKey: String = "main",
    sessionId: String? = "sess-main",
    messages: [AnyCodable] = [],
    supportsActiveRunState: Bool = true,
    hasActiveRun: Bool? = nil,
    activeRunIds: [String]? = nil,
    inFlightRun: NovaChatInFlightRun? = nil) -> NovaChatHistoryPayload
{
    NovaChatHistoryPayload(
        sessionKey: sessionKey,
        sessionId: sessionId,
        messages: messages,
        thinkingLevel: "off",
        sessionInfo: supportsActiveRunState
            ? NovaChatSessionInfo(
                hasActiveRun: hasActiveRun ?? (inFlightRun != nil),
                activeRunIds: activeRunIds ?? inFlightRun.map { [$0.runId] })
            : nil,
        inFlightRun: inFlightRun)
}

private func sessionEntry(
    key: String,
    updatedAt: Double,
    displayName: String? = nil,
    label: String? = nil,
    pinned: Bool = false,
    pinnedAt: Double? = nil,
    archived: Bool = false,
    totalTokens: Int? = nil,
    totalTokensFresh: Bool? = nil,
    contextTokens: Int? = nil) -> NovaChatSessionEntry
{
    NovaChatSessionEntry(
        key: key,
        kind: nil,
        displayName: displayName,
        surface: nil,
        subject: nil,
        room: nil,
        space: nil,
        updatedAt: updatedAt,
        sessionId: nil,
        systemSent: nil,
        abortedLastRun: nil,
        thinkingLevel: nil,
        verboseLevel: nil,
        inputTokens: nil,
        outputTokens: nil,
        totalTokens: totalTokens,
        totalTokensFresh: totalTokensFresh,
        modelProvider: nil,
        model: nil,
        contextTokens: contextTokens,
        label: label,
        pinned: pinned ? true : nil,
        pinnedAt: pinnedAt ?? (pinned ? updatedAt : nil),
        archived: archived ? true : nil,
        archivedAt: archived ? updatedAt : nil)
}

private func sessionsListResponse(_ sessions: [NovaChatSessionEntry]) -> NovaChatSessionsListResponse {
    NovaChatSessionsListResponse(
        ts: nil,
        path: nil,
        count: sessions.count,
        defaults: nil,
        sessions: sessions)
}

private func thinkingOption(_ id: String, label: String? = nil) -> NovaChatThinkingLevelOption {
    NovaChatThinkingLevelOption(id: id, label: label ?? id)
}

private func sessionEntry(
    key: String,
    updatedAt: Double,
    model: String?,
    modelProvider: String? = nil,
    thinkingLevel: String? = nil,
    thinkingLevels: [NovaChatThinkingLevelOption]? = nil,
    thinkingOptions: [String]? = nil,
    thinkingDefault: String? = nil,
    verboseLevel: String? = nil,
    fastMode: NovaChatFastMode? = nil,
    effectiveFastMode: NovaChatFastMode? = nil,
    totalTokens: Int? = nil,
    totalTokensFresh: Bool? = nil,
    contextTokens: Int? = nil) -> NovaChatSessionEntry
{
    NovaChatSessionEntry(
        key: key,
        kind: nil,
        displayName: nil,
        surface: nil,
        subject: nil,
        room: nil,
        space: nil,
        updatedAt: updatedAt,
        sessionId: nil,
        systemSent: nil,
        abortedLastRun: nil,
        thinkingLevel: thinkingLevel,
        verboseLevel: verboseLevel,
        inputTokens: nil,
        outputTokens: nil,
        totalTokens: totalTokens,
        totalTokensFresh: totalTokensFresh,
        modelProvider: modelProvider,
        model: model,
        contextTokens: contextTokens,
        thinkingLevels: thinkingLevels,
        thinkingOptions: thinkingOptions,
        thinkingDefault: thinkingDefault,
        fastMode: fastMode,
        effectiveFastMode: effectiveFastMode)
}

private func modelChoice(
    id: String,
    name: String,
    provider: String = "anthropic",
    reasoning: Bool? = nil) -> NovaChatModelChoice
{
    NovaChatModelChoice(
        modelID: id,
        name: name,
        provider: provider,
        contextWindow: nil,
        reasoning: reasoning)
}

private func sessionsResponse(
    _ session: NovaChatSessionEntry,
    defaults: NovaChatSessionsDefaults? = nil) -> NovaChatSessionsListResponse
{
    NovaChatSessionsListResponse(
        ts: 1,
        path: nil,
        count: 1,
        defaults: defaults,
        sessions: [session])
}

private func commandChoice(
    name: String,
    aliases: [String],
    description: String = "",
    source: NovaChatCommandChoice.Source = .command,
    acceptsArgs: Bool = false) -> NovaChatCommandChoice
{
    NovaChatCommandChoice(
        id: "\(source.rawValue):\(name)",
        name: name,
        textAliases: aliases,
        description: description,
        source: source,
        acceptsArgs: acceptsArgs)
}

private struct ToolActivityEvent: Equatable {
    var id: String
    var name: String
    var isActive: Bool
    var sessionKey: String
}

@MainActor
private final class ToolActivityRecorder {
    private(set) var events: [ToolActivityEvent] = []

    func record(id: String, name: String, isActive: Bool, sessionKey: String) {
        self.events.append(ToolActivityEvent(
            id: id,
            name: name,
            isActive: isActive,
            sessionKey: sessionKey))
    }
}

@MainActor
private func makeViewModel(
    sessionKey: String = "main",
    activeAgentId: String? = nil,
    historyResponses: [NovaChatHistoryPayload],
    sessionRoutingContract: String? = nil,
    sessionsResponses: [NovaChatSessionsListResponse] = [],
    modelResponses: [[NovaChatModelChoice]] = [],
    modelPatchResults: [NovaChatModelPatchResult?] = [],
    thinkingPatchResults: [NovaChatModelPatchResult?] = [],
    commandResponses: [[NovaChatCommandChoice]] = [],
    requestHistoryHook: (@Sendable (String) async throws -> Void)? = nil,
    historyResponseHook: (@Sendable (String, Int, [String]) async throws -> NovaChatHistoryPayload?)? = nil,
    setActiveSessionHook: (@Sendable (String) async throws -> Void)? = nil,
    createSessionHook: (@Sendable (String, String?) async throws -> Void)? = nil,
    resetSessionHook: (@Sendable (String) async throws -> Void)? = nil,
    compactSessionHook: (@Sendable (String) async throws -> Void)? = nil,
    setSessionModelHook: (@Sendable (String?) async throws -> Void)? = nil,
    setSessionThinkingHook: (@Sendable (String) async throws -> Void)? = nil,
    sessionSettingsPatchHook: (
        @Sendable (NovaChatSessionSettingsPatch) async throws -> NovaChatModelPatchResult?)? = nil,
    renameSessionHook: (@Sendable (String, String) async throws -> Void)? = nil,
    setSessionPinnedHook: (@Sendable (String, Bool) async throws -> Void)? = nil,
    setSessionArchivedHook: (@Sendable (String, Bool) async throws -> Void)? = nil,
    listSessionsHook: (
        @Sendable (TestSessionListQuery) async throws -> NovaChatSessionsListResponse?)? = nil,
    sendMessageHook: (@Sendable (String) async throws -> NovaChatSendResponse)? = nil,
    sendMessageStatus: String = "ok",
    waitForRunCompletionHook: (@Sendable (String, Int) async -> NovaChatRunObservation)? = nil,
    acquireSessionSettingsRouteLeaseHook: (@Sendable () async -> Void)? = nil,
    healthResponses: [Bool] = [true],
    initialThinkingLevel: String? = nil,
    initialVerboseLevel: String? = nil,
    modelPickerStore: ChatModelPickerStore? = nil,
    onSessionChanged: (@MainActor (String) -> Void)? = nil,
    onThinkingLevelChanged: (@MainActor @Sendable (String) -> Void)? = nil,
    onToolActivity: (@MainActor @Sendable (
        _ id: String,
        _ name: String,
        _ isActive: Bool,
        _ sessionKey: String) -> Void)? = nil,
    onThinkingPreferenceChanged: (@MainActor @Sendable (String?) -> Void)? = nil,
    onVerboseLevelChanged: (@MainActor @Sendable (String) -> Void)? = nil,
    onVerbosePreferenceChanged: (@MainActor @Sendable (String?) -> Void)? = nil) async
    -> (TestChatTransport, NovaChatViewModel)
{
    // Default to a throwaway suite so model selections in unrelated tests never
    // write favorites/recents into the test host's standard UserDefaults.
    let pickerStore = modelPickerStore
        ??
        ChatModelPickerStore(defaults: UserDefaults(suiteName: "ChatViewModelTests.\(UUID().uuidString)") ??
            .standard)
    let transport = TestChatTransport(
        historyResponses: historyResponses,
        sessionsResponses: sessionsResponses,
        modelResponses: modelResponses,
        modelPatchResults: modelPatchResults,
        thinkingPatchResults: thinkingPatchResults,
        commandResponses: commandResponses,
        requestHistoryHook: requestHistoryHook,
        historyResponseHook: historyResponseHook,
        setActiveSessionHook: setActiveSessionHook,
        createSessionHook: createSessionHook,
        resetSessionHook: resetSessionHook,
        compactSessionHook: compactSessionHook,
        setSessionModelHook: setSessionModelHook,
        setSessionThinkingHook: setSessionThinkingHook,
        sessionSettingsPatchHook: sessionSettingsPatchHook,
        renameSessionHook: renameSessionHook,
        setSessionPinnedHook: setSessionPinnedHook,
        setSessionArchivedHook: setSessionArchivedHook,
        listSessionsHook: listSessionsHook,
        sendMessageHook: sendMessageHook,
        sendMessageStatus: sendMessageStatus,
        waitForRunCompletionHook: waitForRunCompletionHook,
        acquireSessionSettingsRouteLeaseHook: acquireSessionSettingsRouteLeaseHook,
        healthResponses: healthResponses)
    let vm = NovaChatViewModel(
        sessionKey: sessionKey,
        transport: transport,
        activeAgentId: activeAgentId,
        sessionRoutingContract: sessionRoutingContract,
        modelPickerStore: pickerStore,
        initialThinkingLevel: initialThinkingLevel,
        initialVerboseLevel: initialVerboseLevel,
        onSessionChanged: onSessionChanged,
        onThinkingLevelChanged: onThinkingLevelChanged,
        onToolActivity: onToolActivity,
        onThinkingPreferenceChanged: onThinkingPreferenceChanged,
        onVerboseLevelChanged: onVerboseLevelChanged,
        onVerbosePreferenceChanged: onVerbosePreferenceChanged)
    return (transport, vm)
}

private func loadAndWaitBootstrap(
    vm: NovaChatViewModel,
    sessionId: String? = nil) async throws
{
    await MainActor.run { vm.load() }
    try await waitUntil("bootstrap") {
        await MainActor.run {
            vm.healthOK && (sessionId == nil || vm.sessionId == sessionId)
        }
    }
}

private func sendUserMessage(_ vm: NovaChatViewModel, text: String = "hi") async {
    await MainActor.run {
        vm.input = text
        vm.send()
    }
}

private func waitForLastSentRunId(_ transport: TestChatTransport) async throws -> String {
    try await waitUntil("transport send called") {
        await transport.lastSentRunId() != nil
    }
    return try #require(await transport.lastSentRunId())
}

private func waitForSentRunId(after sentRunCount: Int, _ transport: TestChatTransport) async throws -> String {
    try await waitUntil("transport send called") {
        await transport.sentRunIds().count > sentRunCount
    }
    return try #require(await transport.sentRunIds().last)
}

@discardableResult
private func sendMessageAndEmitFinal(
    transport: TestChatTransport,
    vm: NovaChatViewModel,
    text: String,
    sessionKey: String = "main") async throws -> String
{
    let sentRunCount = await transport.sentRunIds().count
    await sendUserMessage(vm, text: text)
    let runId = try await waitForSentRunId(after: sentRunCount, transport)
    try await waitUntil("send is pending or refreshed") {
        await MainActor.run {
            vm.pendingRunCount == 1 || (!vm.isSending && vm.pendingRunCount == 0)
        }
    }

    transport.emit(
        .chat(
            NovaChatEventPayload(
                runId: runId,
                sessionKey: sessionKey,
                state: "final",
                message: nil,
                errorMessage: nil)))
    return runId
}

private func emitAssistantText(
    transport: TestChatTransport,
    runId: String,
    text: String,
    seq: Int = 1)
{
    transport.emit(
        .agent(
            NovaAgentEventPayload(
                runId: runId,
                seq: seq,
                stream: "assistant",
                ts: Int(Date().timeIntervalSince1970 * 1000),
                data: ["text": AnyCodable(text)])))
}

private func emitToolStart(
    transport: TestChatTransport,
    runId: String,
    seq: Int = 2)
{
    transport.emit(
        .agent(
            NovaAgentEventPayload(
                runId: runId,
                seq: seq,
                stream: "tool",
                ts: Int(Date().timeIntervalSince1970 * 1000),
                data: [
                    "phase": AnyCodable("start"),
                    "name": AnyCodable("demo"),
                    "toolCallId": AnyCodable("t1"),
                    "args": AnyCodable(["x": 1]),
                ])))
}

private func emitAgentLifecycleEnd(
    transport: TestChatTransport,
    runId: String,
    seq: Int = 3)
{
    transport.emit(
        .agent(
            NovaAgentEventPayload(
                runId: runId,
                seq: seq,
                stream: "lifecycle",
                ts: Int(Date().timeIntervalSince1970 * 1000),
                data: ["phase": AnyCodable("end")])))
}

private func planStep(_ step: String, status: String) -> AnyCodable {
    AnyCodable([
        "step": AnyCodable(step),
        "status": AnyCodable(status),
    ])
}

private func emitPlan(
    transport: TestChatTransport,
    runId: String,
    steps: [AnyCodable],
    explanation: String? = nil,
    seq: Int = 2)
{
    var data: [String: AnyCodable] = [
        "phase": AnyCodable("update"),
        "steps": AnyCodable(steps),
    ]
    if let explanation {
        data["explanation"] = AnyCodable(explanation)
    }
    transport.emit(
        .agent(
            NovaAgentEventPayload(
                runId: runId,
                seq: seq,
                stream: "plan",
                ts: Int(Date().timeIntervalSince1970 * 1000),
                data: data)))
}

private func emitExternalFinal(
    transport: TestChatTransport,
    runId: String = "other-run",
    sessionKey: String = "main")
{
    transport.emit(
        .chat(
            NovaChatEventPayload(
                runId: runId,
                sessionKey: sessionKey,
                state: "final",
                message: nil,
                errorMessage: nil)))
}

@MainActor
private final class CallbackBox {
    var values: [String] = []
}

@MainActor
private final class OptionalCallbackBox {
    var values: [String?] = []
}

private actor AsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !self.isOpen else { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        self.isOpen = true
        self.continuation?.resume()
        self.continuation = nil
    }
}

private actor AsyncCounter {
    private var value: Int

    init(_ initialValue: Int = 0) {
        self.value = initialValue
    }

    func increment() -> Int {
        self.value += 1
        return self.value
    }

    func current() -> Int {
        self.value
    }
}

private actor AsyncStringRecorder {
    private var values: [String] = []

    func append(_ value: String) {
        self.values.append(value)
    }

    func current() -> [String] {
        self.values
    }
}

private actor SessionSubscribeGate {
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { continuation in
            self.waiters.append(continuation)
        }
    }

    func release() {
        let waiters = self.waiters
        self.waiters = []
        for waiter in waiters {
            waiter.resume()
        }
    }
}

private final class WeakReference<Value: AnyObject> {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}

private func weakReference<Value: AnyObject>(to value: Value?) throws -> WeakReference<Value> {
    let value = try #require(value)
    return WeakReference(value)
}

struct TestSessionListQuery: Equatable, Sendable {
    var limit: Int?
    var search: String?
    var archived: Bool
}

private actor TestChatTransportState {
    var historyCallCount: Int = 0
    var sessionsCallCount: Int = 0
    var modelsCallCount: Int = 0
    var commandsCallCount: Int = 0
    var healthCallCount: Int = 0
    var activeSessionKeys: [String] = []
    var createdSessionKeys: [String] = []
    var createdParentSessionKeys: [String?] = []
    var resetSessionKeys: [String] = []
    var compactSessionKeys: [String] = []
    var sentSessionKeys: [String] = []
    var sentAgentIDs: [String?] = []
    var sentRoutingContracts: [String?] = []
    var sentMessages: [String] = []
    var sentRunIds: [String] = []
    var commandSessionKeys: [String] = []
    var sentThinkingLevels: [String] = []
    var abortedRunIds: [String] = []
    var waitCompletionRunIds: [String] = []
    var patchedModels: [String?] = []
    var patchedModelTargets: [(sessionKey: String, agentID: String?)] = []
    var patchedThinkingLevels: [String] = []
    var listSessionsQueries: [TestSessionListQuery] = []
    var renamedLabelsByKey: [(key: String, label: String)] = []
    var pinnedChanges: [(key: String, pinned: Bool)] = []
    var archivedChanges: [(key: String, archived: Bool)] = []
    var sessionSettingsRouteGeneration: UInt64 = 0
    var capturedSessionSettingsRouteGenerations: [UInt64] = []
}

private final class TestChatTransport: @unchecked Sendable, NovaChatTransport {
    private let state = TestChatTransportState()
    private let historyResponses: [NovaChatHistoryPayload]
    private let sessionsResponses: [NovaChatSessionsListResponse]
    private let modelResponses: [[NovaChatModelChoice]]
    private let modelPatchResults: [NovaChatModelPatchResult?]
    private let thinkingPatchResults: [NovaChatModelPatchResult?]
    private let commandResponses: [[NovaChatCommandChoice]]
    private let requestHistoryHook: (@Sendable (String) async throws -> Void)?
    private let historyResponseHook:
        (@Sendable (String, Int, [String]) async throws -> NovaChatHistoryPayload?)?
    private let setActiveSessionHook: (@Sendable (String) async throws -> Void)?
    private let createSessionHook: (@Sendable (String, String?) async throws -> Void)?
    private let resetSessionHook: (@Sendable (String) async throws -> Void)?
    private let compactSessionHook: (@Sendable (String) async throws -> Void)?
    private let setSessionModelHook: (@Sendable (String?) async throws -> Void)?
    private let setSessionThinkingHook: (@Sendable (String) async throws -> Void)?
    private let sessionSettingsPatchHook:
        (@Sendable (NovaChatSessionSettingsPatch) async throws -> NovaChatModelPatchResult?)?
    private let renameSessionHook: (@Sendable (String, String) async throws -> Void)?
    private let setSessionPinnedHook: (@Sendable (String, Bool) async throws -> Void)?
    private let setSessionArchivedHook: (@Sendable (String, Bool) async throws -> Void)?
    private let listSessionsHook:
        (@Sendable (TestSessionListQuery) async throws -> NovaChatSessionsListResponse?)?
    private let sendMessageHook: (@Sendable (String) async throws -> NovaChatSendResponse)?
    private let sendMessageStatus: String
    private let waitForRunCompletionHook:
        (@Sendable (String, Int) async -> NovaChatRunObservation)?
    private let acquireSessionSettingsRouteLeaseHook: (@Sendable () async -> Void)?
    private let listQuestionsHook: (@Sendable () async throws -> [QuestionRecord])?
    private let getQuestionHook: (@Sendable (String) async throws -> QuestionRecord)?
    private let cancelQuestionHook: (@Sendable (String) async throws -> Void)?
    private let healthResponses: [Bool]

    private let stream: AsyncStream<NovaChatTransportEvent>
    private let continuation: AsyncStream<NovaChatTransportEvent>.Continuation

    init(
        historyResponses: [NovaChatHistoryPayload],
        sessionsResponses: [NovaChatSessionsListResponse] = [],
        modelResponses: [[NovaChatModelChoice]] = [],
        modelPatchResults: [NovaChatModelPatchResult?] = [],
        thinkingPatchResults: [NovaChatModelPatchResult?] = [],
        commandResponses: [[NovaChatCommandChoice]] = [],
        requestHistoryHook: (@Sendable (String) async throws -> Void)? = nil,
        historyResponseHook: (@Sendable (String, Int, [String]) async throws -> NovaChatHistoryPayload?)? = nil,
        setActiveSessionHook: (@Sendable (String) async throws -> Void)? = nil,
        createSessionHook: (@Sendable (String, String?) async throws -> Void)? = nil,
        resetSessionHook: (@Sendable (String) async throws -> Void)? = nil,
        compactSessionHook: (@Sendable (String) async throws -> Void)? = nil,
        setSessionModelHook: (@Sendable (String?) async throws -> Void)? = nil,
        setSessionThinkingHook: (@Sendable (String) async throws -> Void)? = nil,
        sessionSettingsPatchHook: (
            @Sendable (NovaChatSessionSettingsPatch) async throws -> NovaChatModelPatchResult?)? = nil,
        renameSessionHook: (@Sendable (String, String) async throws -> Void)? = nil,
        setSessionPinnedHook: (@Sendable (String, Bool) async throws -> Void)? = nil,
        setSessionArchivedHook: (@Sendable (String, Bool) async throws -> Void)? = nil,
        listSessionsHook: (
            @Sendable (TestSessionListQuery) async throws -> NovaChatSessionsListResponse?)? = nil,
        sendMessageHook: (@Sendable (String) async throws -> NovaChatSendResponse)? = nil,
        sendMessageStatus: String = "ok",
        waitForRunCompletionHook: (@Sendable (String, Int) async -> NovaChatRunObservation)? = nil,
        acquireSessionSettingsRouteLeaseHook: (@Sendable () async -> Void)? = nil,
        listQuestionsHook: (@Sendable () async throws -> [QuestionRecord])? = nil,
        getQuestionHook: (@Sendable (String) async throws -> QuestionRecord)? = nil,
        cancelQuestionHook: (@Sendable (String) async throws -> Void)? = nil,
        healthResponses: [Bool] = [true])
    {
        self.historyResponses = historyResponses
        self.sessionsResponses = sessionsResponses
        self.modelResponses = modelResponses
        self.modelPatchResults = modelPatchResults
        self.thinkingPatchResults = thinkingPatchResults
        self.commandResponses = commandResponses
        self.requestHistoryHook = requestHistoryHook
        self.historyResponseHook = historyResponseHook
        self.setActiveSessionHook = setActiveSessionHook
        self.createSessionHook = createSessionHook
        self.resetSessionHook = resetSessionHook
        self.compactSessionHook = compactSessionHook
        self.setSessionModelHook = setSessionModelHook
        self.setSessionThinkingHook = setSessionThinkingHook
        self.sessionSettingsPatchHook = sessionSettingsPatchHook
        self.renameSessionHook = renameSessionHook
        self.setSessionPinnedHook = setSessionPinnedHook
        self.setSessionArchivedHook = setSessionArchivedHook
        self.listSessionsHook = listSessionsHook
        self.sendMessageHook = sendMessageHook
        self.sendMessageStatus = sendMessageStatus
        self.waitForRunCompletionHook = waitForRunCompletionHook
        self.acquireSessionSettingsRouteLeaseHook = acquireSessionSettingsRouteLeaseHook
        self.listQuestionsHook = listQuestionsHook
        self.getQuestionHook = getQuestionHook
        self.cancelQuestionHook = cancelQuestionHook
        self.healthResponses = healthResponses
        var cont: AsyncStream<NovaChatTransportEvent>.Continuation!
        self.stream = AsyncStream { c in
            cont = c
        }
        self.continuation = cont
    }

    func events() -> AsyncStream<NovaChatTransportEvent> {
        self.stream
    }

    func setActiveSessionKey(_ sessionKey: String) async throws {
        await self.state.activeSessionKeysAppend(sessionKey)
        if let setActiveSessionHook {
            try await setActiveSessionHook(sessionKey)
        }
    }

    func createSession(
        key: String,
        label _: String?,
        parentSessionKey: String?,
        worktree _: Bool?) async throws -> NovaChatCreateSessionResponse
    {
        if let createSessionHook {
            try await createSessionHook(key, parentSessionKey)
        }
        await self.state.createdSessionKeysAppend(key)
        await self.state.createdParentSessionKeysAppend(parentSessionKey)
        return NovaChatCreateSessionResponse(ok: true, key: key, sessionId: "created-\(key)")
    }

    func requestHistory(sessionKey: String) async throws -> NovaChatHistoryPayload {
        let idx = await state.nextHistoryCallIndex()
        if let requestHistoryHook {
            try await requestHistoryHook(sessionKey)
        }
        if let historyResponseHook {
            let sentRunIds = await self.sentRunIds()
            if let response = try await historyResponseHook(sessionKey, idx, sentRunIds) {
                return response
            }
        }
        if idx < self.historyResponses.count {
            return self.historyResponses[idx]
        }
        return self.historyResponses.last ?? NovaChatHistoryPayload(
            sessionKey: sessionKey,
            sessionId: nil,
            messages: [],
            thinkingLevel: "off")
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
        await self.state.sentAgentIDsAppend(agentID)
        await self.state.sentRoutingContractsAppend(expectedSessionRoutingContract)
        return try await self.sendMessage(
            sessionKey: sessionKey,
            message: message,
            thinking: thinking,
            idempotencyKey: idempotencyKey,
            attachments: attachments)
    }

    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments _: [NovaChatAttachmentPayload]) async throws -> NovaChatSendResponse
    {
        await self.state.sentSessionKeysAppend(sessionKey)
        await self.state.sentMessagesAppend(message)
        await self.state.sentRunIdsAppend(idempotencyKey)
        await self.state.sentThinkingLevelsAppend(thinking)
        if let sendMessageHook {
            return try await sendMessageHook(idempotencyKey)
        }
        return NovaChatSendResponse(runId: idempotencyKey, status: self.sendMessageStatus)
    }

    func abortRun(sessionKey _: String, runId: String) async throws {
        await self.state.abortedRunIdsAppend(runId)
    }

    func listSessions(
        limit: Int?,
        search: String?,
        archived: Bool) async throws -> NovaChatSessionsListResponse
    {
        let query = TestSessionListQuery(limit: limit, search: search, archived: archived)
        // Single actor hop: bootstrap assertions in older tests race the
        // post-health sync, so this fake must not add suspension points.
        let idx = await state.recordSessionsCall(query)
        if let listSessionsHook, let response = try await listSessionsHook(query) {
            return response
        }
        if idx < self.sessionsResponses.count {
            return self.sessionsResponses[idx]
        }
        return self.sessionsResponses.last ?? NovaChatSessionsListResponse(
            ts: nil,
            path: nil,
            count: 0,
            defaults: nil,
            sessions: [])
    }

    func patchSession(
        key: String,
        label: String??,
        category _: String??,
        pinned: Bool?,
        archived: Bool?,
        unread _: Bool?) async throws
    {
        if let label, let label {
            await self.state.renamedLabelsAppend(key: key, label: label)
            if let renameSessionHook {
                try await renameSessionHook(key, label)
            }
        }
        if let pinned {
            await self.state.pinnedChangesAppend(key: key, pinned: pinned)
            if let setSessionPinnedHook {
                try await setSessionPinnedHook(key, pinned)
            }
        }
        if let archived {
            await self.state.archivedChangesAppend(key: key, archived: archived)
            if let setSessionArchivedHook {
                try await setSessionArchivedHook(key, archived)
            }
        }
    }

    func listModels() async throws -> [NovaChatModelChoice] {
        let idx = await state.nextModelsCallIndex()
        if idx < self.modelResponses.count {
            return self.modelResponses[idx]
        }
        return self.modelResponses.last ?? []
    }

    var supportsSlashCommandCatalog: Bool {
        !self.commandResponses.isEmpty
    }

    func listCommands(sessionKey: String) async throws -> [NovaChatCommandChoice] {
        await self.state.commandSessionKeysAppend(sessionKey)
        let idx = await state.nextCommandsCallIndex()
        if idx < self.commandResponses.count {
            return self.commandResponses[idx]
        }
        return self.commandResponses.last ?? []
    }

    func setSessionModel(sessionKey: String, model: String?) async throws {
        _ = try await self.patchSessionModel(sessionKey: sessionKey, agentID: nil, model: model)
    }

    func acquireSessionSettingsRouteLease() async -> NovaChatSessionSettingsRouteLease? {
        if let acquireSessionSettingsRouteLeaseHook {
            await acquireSessionSettingsRouteLeaseHook()
        }
        let generation = await state.captureSessionSettingsRouteGeneration()
        let transport = self
        return NovaChatSessionSettingsRouteLease { sessionKey, agentID, patch in
            guard await transport.state.sessionSettingsRouteGeneration == generation else {
                throw NovaChatTransportSendError.notDispatched
            }
            return try await transport.patchSessionSettings(
                sessionKey: sessionKey,
                agentID: agentID,
                patch: patch)
        }
    }

    func patchSessionModel(
        sessionKey: String,
        agentID: String?,
        model: String?) async throws -> NovaChatModelPatchResult?
    {
        let index = await state.recordPatchedModel(
            sessionKey: sessionKey,
            agentID: agentID,
            model: model)
        if let setSessionModelHook {
            try await setSessionModelHook(model)
        }
        if index < self.modelPatchResults.count {
            return self.modelPatchResults[index]
        }
        if let last = modelPatchResults.last {
            return last
        }
        return nil
    }

    func resetSession(sessionKey: String) async throws {
        await self.state.resetSessionKeysAppend(sessionKey)
        if let resetSessionHook {
            try await resetSessionHook(sessionKey)
        }
    }

    func compactSession(sessionKey: String) async throws {
        await self.state.compactSessionKeysAppend(sessionKey)
        if let compactSessionHook {
            try await compactSessionHook(sessionKey)
        }
    }

    func setSessionThinking(sessionKey: String, thinkingLevel: String) async throws {
        _ = try await self.patchSessionThinking(sessionKey: sessionKey, thinkingLevel: thinkingLevel)
    }

    func patchSessionSettings(
        sessionKey: String,
        agentID: String?,
        patch: NovaChatSessionSettingsPatch) async throws -> NovaChatModelPatchResult?
    {
        if let sessionSettingsPatchHook {
            return try await sessionSettingsPatchHook(patch)
        }
        var result: NovaChatModelPatchResult?
        if let model = patch.model {
            result = try await self.patchSessionModel(sessionKey: sessionKey, agentID: agentID, model: model)
        }
        if let thinkingLevelUpdate = patch.thinkingLevel {
            guard let thinkingLevel = thinkingLevelUpdate else {
                throw NSError(
                    domain: "TestChatTransport",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "thinkingLevel cannot be cleared"])
            }
            let thinkingResult = try await patchSessionThinking(
                sessionKey: sessionKey,
                thinkingLevel: thinkingLevel)
            result = NovaChatModelPatchResult(
                key: thinkingResult?.key ?? result?.key ?? sessionKey,
                modelProvider: thinkingResult?.modelProvider ?? result?.modelProvider,
                model: thinkingResult?.model ?? result?.model,
                thinkingLevel: thinkingResult?.thinkingLevel ?? thinkingLevel,
                thinkingLevels: thinkingResult?.thinkingLevels ?? result?.thinkingLevels)
        }
        return result
    }

    private func patchSessionThinking(
        sessionKey: String,
        thinkingLevel: String) async throws -> NovaChatModelPatchResult?
    {
        let index = await state.recordPatchedThinkingLevel(thinkingLevel)
        if let setSessionThinkingHook {
            try await setSessionThinkingHook(thinkingLevel)
        }
        if index < self.thinkingPatchResults.count {
            return self.thinkingPatchResults[index]
        }
        if let last = thinkingPatchResults.last {
            return last
        }
        return NovaChatModelPatchResult(
            key: sessionKey,
            modelProvider: nil,
            model: nil,
            thinkingLevel: thinkingLevel)
    }

    func requestHealth(timeoutMs _: Int) async throws -> Bool {
        let idx = await state.nextHealthCallIndex()
        if idx < self.healthResponses.count {
            return self.healthResponses[idx]
        }
        return self.healthResponses.last ?? true
    }

    func listQuestions() async throws -> [QuestionRecord] {
        try await self.listQuestionsHook?() ?? []
    }

    func getQuestion(id: String) async throws -> QuestionRecord {
        guard let getQuestionHook else {
            throw NSError(
                domain: "TestChatTransport",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "missing question.get fixture"])
        }
        return try await getQuestionHook(id)
    }

    func cancelQuestion(id: String) async throws {
        try await self.cancelQuestionHook?(id)
    }

    func waitForRunCompletion(
        runId: String,
        timeoutMs: Int) async -> NovaChatRunObservation
    {
        await self.state.waitCompletionRunIdsAppend(runId)
        return await self.waitForRunCompletionHook?(runId, timeoutMs) ?? .unavailable
    }

    func emit(_ evt: NovaChatTransportEvent) {
        self.continuation.yield(evt)
    }

    func lastSentRunId() async -> String? {
        let ids = await state.sentRunIds
        return ids.last
    }

    func sentRunIds() async -> [String] {
        await self.state.sentRunIds
    }

    func sentMessages() async -> [String] {
        await self.state.sentMessages
    }

    func sentAgentIDs() async -> [String?] {
        await self.state.sentAgentIDs
    }

    func sentRoutingContracts() async -> [String?] {
        await self.state.sentRoutingContracts
    }

    func commandSessionKeys() async -> [String] {
        await self.state.commandSessionKeys
    }

    func lastSentSessionKey() async -> String? {
        let keys = await state.sentSessionKeys
        return keys.last
    }

    func abortedRunIds() async -> [String] {
        await self.state.abortedRunIds
    }

    func sentThinkingLevels() async -> [String] {
        await self.state.sentThinkingLevels
    }

    func patchedModels() async -> [String?] {
        await self.state.patchedModels
    }

    func patchedModelTargets() async -> [(sessionKey: String, agentID: String?)] {
        await self.state.patchedModelTargets
    }

    func activeSessionKeys() async -> [String] {
        await self.state.activeSessionKeys
    }

    func patchedThinkingLevels() async -> [String] {
        await self.state.patchedThinkingLevels
    }

    func healthCallCount() async -> Int {
        await self.state.healthCallCount
    }

    func resetSessionKeys() async -> [String] {
        await self.state.resetSessionKeys
    }

    func compactSessionKeys() async -> [String] {
        await self.state.compactSessionKeys
    }

    func waitCompletionRunIds() async -> [String] {
        await self.state.waitCompletionRunIds
    }

    func createdSessionKeys() async -> [String] {
        await self.state.createdSessionKeys
    }

    func createdParentSessionKeys() async -> [String?] {
        await self.state.createdParentSessionKeys
    }

    func listSessionsQueries() async -> [TestSessionListQuery] {
        await self.state.listSessionsQueries
    }

    func renamedLabels() async -> [(key: String, label: String)] {
        await self.state.renamedLabelsByKey
    }

    func pinnedChanges() async -> [(key: String, pinned: Bool)] {
        await self.state.pinnedChanges
    }

    func archivedChanges() async -> [(key: String, archived: Bool)] {
        await self.state.archivedChanges
    }

    func replaceSessionSettingsRoute() async {
        await self.state.replaceSessionSettingsRoute()
    }

    func capturedSessionSettingsRouteGenerations() async -> [UInt64] {
        await self.state.capturedSessionSettingsRouteGenerations
    }
}

extension TestChatTransportState {
    fileprivate func captureSessionSettingsRouteGeneration() -> UInt64 {
        self.capturedSessionSettingsRouteGenerations.append(self.sessionSettingsRouteGeneration)
        return self.sessionSettingsRouteGeneration
    }

    fileprivate func replaceSessionSettingsRoute() {
        self.sessionSettingsRouteGeneration &+= 1
    }

    fileprivate func nextHistoryCallIndex() -> Int {
        defer { self.historyCallCount += 1 }
        return self.historyCallCount
    }

    private func nextSessionsCallIndex() -> Int {
        defer { self.sessionsCallCount += 1 }
        return self.sessionsCallCount
    }

    fileprivate func recordSessionsCall(_ query: TestSessionListQuery) -> Int {
        self.listSessionsQueries.append(query)
        return self.nextSessionsCallIndex()
    }

    fileprivate func nextModelsCallIndex() -> Int {
        defer { self.modelsCallCount += 1 }
        return self.modelsCallCount
    }

    fileprivate func nextCommandsCallIndex() -> Int {
        defer { self.commandsCallCount += 1 }
        return self.commandsCallCount
    }

    fileprivate func nextHealthCallIndex() -> Int {
        defer { self.healthCallCount += 1 }
        return self.healthCallCount
    }

    fileprivate func activeSessionKeysAppend(_ v: String) {
        self.activeSessionKeys.append(v)
    }

    fileprivate func sentRunIdsAppend(_ v: String) {
        self.sentRunIds.append(v)
    }

    fileprivate func commandSessionKeysAppend(_ v: String) {
        self.commandSessionKeys.append(v)
    }

    fileprivate func abortedRunIdsAppend(_ v: String) {
        self.abortedRunIds.append(v)
    }

    fileprivate func waitCompletionRunIdsAppend(_ v: String) {
        self.waitCompletionRunIds.append(v)
    }

    fileprivate func sentThinkingLevelsAppend(_ v: String) {
        self.sentThinkingLevels.append(v)
    }

    fileprivate func recordPatchedModel(
        sessionKey: String,
        agentID: String?,
        model: String?) -> Int
    {
        let index = self.patchedModels.count
        self.patchedModels.append(model)
        self.patchedModelTargets.append((sessionKey: sessionKey, agentID: agentID))
        return index
    }

    fileprivate func recordPatchedThinkingLevel(_ v: String) -> Int {
        let index = self.patchedThinkingLevels.count
        self.patchedThinkingLevels.append(v)
        return index
    }

    fileprivate func resetSessionKeysAppend(_ v: String) {
        self.resetSessionKeys.append(v)
    }

    fileprivate func compactSessionKeysAppend(_ v: String) {
        self.compactSessionKeys.append(v)
    }

    fileprivate func createdSessionKeysAppend(_ v: String) {
        self.createdSessionKeys.append(v)
    }

    fileprivate func createdParentSessionKeysAppend(_ v: String?) {
        self.createdParentSessionKeys.append(v)
    }

    fileprivate func sentSessionKeysAppend(_ v: String) {
        self.sentSessionKeys.append(v)
    }

    fileprivate func sentAgentIDsAppend(_ v: String?) {
        self.sentAgentIDs.append(v)
    }

    fileprivate func sentRoutingContractsAppend(_ v: String?) {
        self.sentRoutingContracts.append(v)
    }

    fileprivate func sentMessagesAppend(_ v: String) {
        self.sentMessages.append(v)
    }

    fileprivate func renamedLabelsAppend(key: String, label: String) {
        self.renamedLabelsByKey.append((key: key, label: label))
    }

    fileprivate func pinnedChangesAppend(key: String, pinned: Bool) {
        self.pinnedChanges.append((key: key, pinned: pinned))
    }

    fileprivate func archivedChangesAppend(key: String, archived: Bool) {
        self.archivedChanges.append((key: key, archived: archived))
    }
}

private actor QuestionListGate {
    private var continuation: CheckedContinuation<[QuestionRecord], Never>?

    var isWaiting: Bool {
        self.continuation != nil
    }

    func wait() async -> [QuestionRecord] {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with records: [QuestionRecord]) {
        self.continuation?.resume(returning: records)
        self.continuation = nil
    }
}

private actor QuestionListEventRace {
    private var firstContinuation: CheckedContinuation<[QuestionRecord], Never>?
    private var callCount = 0
    private let currentRecords: [QuestionRecord]

    init(currentRecords: [QuestionRecord]) {
        self.currentRecords = currentRecords
    }

    var firstIsWaiting: Bool {
        self.firstContinuation != nil
    }

    var calls: Int {
        self.callCount
    }

    func request() async -> [QuestionRecord] {
        self.callCount += 1
        if self.callCount == 1 {
            return await withCheckedContinuation { continuation in
                self.firstContinuation = continuation
            }
        }
        return self.currentRecords
    }

    func resumeFirst(with records: [QuestionRecord]) {
        self.firstContinuation?.resume(returning: records)
        self.firstContinuation = nil
    }
}

private func chatQuestionRecord(
    id: String,
    status: QuestionStatus = .pending,
    expiresAtMs: Int = 4_000_000_000_000,
    sessionKey: String? = "main",
    answers: QuestionAnswers? = nil) -> QuestionRecord
{
    QuestionRecord(
        id: id,
        questions: [
            Question(
                questionid: "choice",
                header: "Choice",
                question: "Choose",
                options: [QuestionOption(label: "One"), QuestionOption(label: "Two")]),
        ],
        agentid: "main",
        sessionkey: sessionKey,
        createdatms: 1,
        expiresatms: expiresAtMs,
        status: status,
        answers: answers)
}

@Suite(.serialized)
struct ChatViewModelTests {
    @Test @MainActor func `locally expired question remains in transcript`() {
        let viewModel = NovaChatViewModel(
            sessionKey: "main",
            transport: TestChatTransport(historyResponses: []))
        let expiresAt = Date(timeIntervalSince1970: 1500)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_local", expiresAtMs: 1_500_000))
        let model = viewModel.questionCards[0]

        viewModel.expireQuestionIfNeeded(model, at: expiresAt)
        #expect(viewModel.questionCards.map(\.id) == ["ask_local"])
        #expect(model.status(at: expiresAt) == .expired)

        viewModel.expireQuestionIfNeeded(
            model,
            at: expiresAt.addingTimeInterval(15))
        #expect(viewModel.questionCards.map(\.id) == ["ask_local"])
    }

    @Test @MainActor func `stale question list cannot overwrite a newer event`() async throws {
        let gate = QuestionListGate()
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: { await gate.wait() })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        let refresh = Task { await viewModel.refreshQuestions() }
        try await waitUntil("question list request") { await gate.isWaiting }

        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_new"))
        await gate.resume(with: [chatQuestionRecord(id: "ask_old")])
        await refresh.value

        #expect(viewModel.questionCards.map(\.id) == ["ask_new"])
    }

    @Test @MainActor func `definitive question list rejection clears stale cards`() async {
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                throw GatewayResponseError(
                    method: "question.list",
                    code: "INVALID_REQUEST",
                    message: "unknown method: question.list",
                    details: nil)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_stale"))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards.isEmpty)
    }

    @Test @MainActor func `structured missing question scope clears stale cards`() async {
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                throw GatewayResponseError(
                    method: "question.list",
                    code: "FORBIDDEN",
                    message: "permission denied",
                    details: [
                        "code": AnyCodable("MISSING_SCOPE"),
                        "missingScope": AnyCodable("operator.questions"),
                        "requiredScopes": AnyCodable(["operator.questions"]),
                    ])
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_stale"))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards.isEmpty)
    }

    @Test @MainActor func `transient question list rejection preserves event cards`() async {
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                throw GatewayResponseError(
                    method: "question.list",
                    code: "UNAVAILABLE",
                    message: "try again",
                    details: nil)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_live"))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards.map(\.id) == ["ask_live"])
    }

    @Test @MainActor func `question recovery does not block bootstrap history`() async throws {
        let questionGate = QuestionListGate()
        let historyCalls = AsyncCounter()
        let transport = TestChatTransport(
            historyResponses: [historyPayload()],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            listQuestionsHook: { await questionGate.wait() })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)

        viewModel.load()
        try await waitUntil("question recovery request") { await questionGate.isWaiting }
        try await waitUntil("history during question recovery") { await historyCalls.current() == 1 }
        await questionGate.resume(with: [])
    }

    @Test @MainActor func `resolved event reconciles after discarding older question list`() async throws {
        let race = QuestionListEventRace(currentRecords: [chatQuestionRecord(id: "ask_other")])
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: { await race.request() })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        let initialRefresh = Task { await viewModel.refreshQuestions() }
        try await waitUntil("first question list request") { await race.firstIsWaiting }

        viewModel.handleTransportEvent(.questionResolved(.init(id: "ask_done", status: .answered)))
        try await waitUntil("question event reconciliation") { await race.calls == 2 }
        await race.resumeFirst(with: [chatQuestionRecord(id: "ask_done")])
        await initialRefresh.value
        for _ in 0..<100 where viewModel.questionCards.map(\.id) != ["ask_other"] {
            await Task.yield()
        }
        #expect(viewModel.questionCards.map(\.id) == ["ask_other"])
    }

    @Test @MainActor func `question list retains resolved card persistently`() async {
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: { [] })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_done"))
        viewModel.resolveQuestionEvent(.init(id: "ask_done", status: .answered))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards.map(\.id) == ["ask_done"])
        #expect(viewModel.questionCards.first?.status() == .answeredElsewhere)
    }

    @Test @MainActor func `terminal question survives later empty list refresh`() async {
        let transport = TestChatTransport(historyResponses: [], listQuestionsHook: { [] })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_done"))
        viewModel.resolveQuestionEvent(.init(id: "ask_done", status: .answered))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards.map(\.id) == ["ask_done"])
        #expect(viewModel.questionCards[0].status() == .answeredElsewhere)
    }

    @Test @MainActor func `missing pending question uses question get fallback`() async {
        let answers = QuestionAnswers(answers: [
            "choice": AnyCodable(["Two"]),
        ])
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: { [] },
            getQuestionHook: { id in
                chatQuestionRecord(id: id, status: .answered, answers: answers)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_missing"))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards[0].status() == .answeredElsewhere)
        #expect(viewModel.questionCards[0].terminalSummaryText(
            for: viewModel.questionCards[0].record.questions[0]) == "Two")
    }

    @Test @MainActor func `missing question tombstone has unknown terminal outcome`() async {
        let getCalls = AsyncCounter()
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: { [] },
            getQuestionHook: { id in
                _ = await getCalls.increment()
                throw GatewayResponseError(
                    method: "question.get",
                    code: "INVALID_REQUEST",
                    message: "question '\(id)' was not found",
                    details: ["reason": AnyCodable("QUESTION_NOT_FOUND")])
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_missing"))

        await viewModel.refreshQuestions()

        #expect(viewModel.questionCards[0].status() == .unavailable)
        #expect(viewModel.questionCards[0].terminalSummaryText(
            for: viewModel.questionCards[0].record.questions[0]) == "Unavailable")

        await viewModel.refreshQuestions()

        #expect(await getCalls.current() == 1)
    }

    @Test @MainActor func `question refresh retries transport failure`() async throws {
        let listCalls = AsyncCounter()
        let getCalls = AsyncCounter()
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                let call = await listCalls.increment()
                if call == 1 {
                    throw GatewayResponseError(
                        method: "question.list",
                        code: "UNAVAILABLE",
                        message: "retry",
                        details: nil)
                }
                return []
            },
            getQuestionHook: { id in
                _ = await getCalls.increment()
                return chatQuestionRecord(id: id, status: .cancelled)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.questionRefreshRetryDelaysMs = [0]
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_retry"))

        await viewModel.refreshQuestions()
        try await waitUntil("question refresh retry") { await getCalls.current() == 1 }

        #expect(await listCalls.current() == 2)
        #expect(viewModel.questionCards[0].status() == .cancelled)
    }

    @Test @MainActor func `question refresh resets exhausted retry budget after overlapping skip`() async throws {
        let listCalls = AsyncCounter()
        let getStarted = AsyncCounter()
        let getCalls = AsyncCounter()
        let firstGetGate = AsyncGate()
        let recovering = chatQuestionRecord(id: "ask_recovering")
        let unrelated = chatQuestionRecord(id: "ask_unrelated")
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                let call = await listCalls.increment()
                if call == 1 {
                    throw GatewayResponseError(
                        method: "question.list",
                        code: "UNAVAILABLE",
                        message: "consume retry budget",
                        details: nil)
                }
                return [unrelated]
            },
            getQuestionHook: { id in
                let call = await getCalls.increment()
                if call == 1 {
                    _ = await getStarted.increment()
                    await firstGetGate.wait()
                }
                return chatQuestionRecord(id: id, status: .answered)
            },
            cancelQuestionHook: { _ in })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.questionRefreshRetryDelaysMs = [0]
        viewModel.upsertQuestion(recovering)
        viewModel.upsertQuestion(unrelated)

        let refresh = Task { await viewModel.refreshQuestions() }
        try await waitUntil("question get request") { await getStarted.current() == 1 }
        let unrelatedModel = try #require(viewModel.questionCards.first { $0.id == unrelated.id })
        await viewModel.skipQuestion(unrelatedModel)
        await firstGetGate.open()
        await refresh.value
        try await waitUntil("question reconciliation after skip") {
            await MainActor.run {
                viewModel.questionCards.first { $0.id == recovering.id }?.status() == .answeredElsewhere
            }
        }

        #expect(await getCalls.current() == 2)
        #expect(await listCalls.current() == 3)
    }

    @Test @MainActor func `question refresh resets exhausted retry budget after partial progress`() async throws {
        let listCalls = AsyncCounter()
        let recoveringCalls = AsyncCounter()
        let progressed = chatQuestionRecord(id: "ask_progressed")
        let recovering = chatQuestionRecord(id: "ask_recovering")
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                let call = await listCalls.increment()
                if call == 1 {
                    throw GatewayResponseError(
                        method: "question.list",
                        code: "UNAVAILABLE",
                        message: "consume retry budget",
                        details: nil)
                }
                return []
            },
            getQuestionHook: { id in
                if id == progressed.id {
                    return chatQuestionRecord(id: id, status: .answered)
                }
                let call = await recoveringCalls.increment()
                if call == 1 {
                    throw GatewayResponseError(
                        method: "question.get",
                        code: "UNAVAILABLE",
                        message: "partial failure",
                        details: nil)
                }
                return chatQuestionRecord(id: id, status: .cancelled)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.questionRefreshRetryDelaysMs = [0]
        viewModel.upsertQuestion(progressed)
        viewModel.upsertQuestion(recovering)

        await viewModel.refreshQuestions()
        try await waitUntil("question retry after partial progress") {
            await MainActor.run {
                viewModel.questionCards.first { $0.id == recovering.id }?.status() == .cancelled
            }
        }

        #expect(await listCalls.current() == 3)
        #expect(await recoveringCalls.current() == 2)
        #expect(viewModel.questionCards.first { $0.id == progressed.id }?.status() == .answeredElsewhere)
    }

    @Test @MainActor func `question refresh resets retry budget after state change during backoff`() async throws {
        let listCalls = AsyncCounter()
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                let call = await listCalls.increment()
                if call < 3 {
                    throw GatewayResponseError(
                        method: "question.list",
                        code: "UNAVAILABLE",
                        message: "retry",
                        details: nil)
                }
                return []
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.questionRefreshRetryDelaysMs = [25]
        let question = chatQuestionRecord(id: "ask_backoff")
        viewModel.upsertQuestion(question)

        await viewModel.refreshQuestions()
        viewModel.resolveQuestionEvent(.init(id: question.id, status: .cancelled))
        try await waitUntil("question retry budget reset after backoff mutation") {
            await listCalls.current() == 3
        }

        #expect(viewModel.questionCards[0].status() == .cancelled)
    }

    @Test @MainActor func `question refresh stops after bounded retries`() async throws {
        let listCalls = AsyncCounter()
        let transport = TestChatTransport(
            historyResponses: [],
            listQuestionsHook: {
                _ = await listCalls.increment()
                throw GatewayResponseError(
                    method: "question.list",
                    code: "UNAVAILABLE",
                    message: "retry",
                    details: nil)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.questionRefreshRetryDelaysMs = [0, 0, 0]

        await viewModel.refreshQuestions()
        try await waitUntil("bounded question refresh retries") { await listCalls.current() >= 4 }
        try await Task.sleep(for: .milliseconds(25))

        #expect(await listCalls.current() == 4)
        #expect(viewModel.questionRefreshRetryTask == nil)
    }

    @Test @MainActor func `visible questions filter by current session`() {
        let viewModel = NovaChatViewModel(
            sessionKey: "main",
            transport: TestChatTransport(historyResponses: []))
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_main"))
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_other", sessionKey: "other"))
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_unscoped", sessionKey: nil))

        #expect(viewModel.visibleQuestionCards.map(\.id) == ["ask_main", "ask_unscoped"])
    }

    @Test @MainActor func `skip sends question cancellation and retains summary`() async {
        let cancelledIDs = AsyncStringRecorder()
        let transport = TestChatTransport(
            historyResponses: [],
            cancelQuestionHook: { id in
                await cancelledIDs.append(id)
            })
        let viewModel = NovaChatViewModel(sessionKey: "main", transport: transport)
        viewModel.upsertQuestion(chatQuestionRecord(id: "ask_skip"))

        await viewModel.skipQuestion(viewModel.questionCards[0])

        #expect(await cancelledIDs.current() == ["ask_skip"])
        #expect(viewModel.questionCards[0].status() == .cancelled)
        #expect(viewModel.questionCards[0].terminalSummaryText(
            for: viewModel.questionCards[0].record.questions[0]) == "Skipped")
    }

    @Test func `context usage fraction validates freshness and token bounds`() {
        func fraction(total: Int?, fresh: Bool? = true, context: Int?) -> Double? {
            NovaChatViewModel.chatContextUsageFraction(
                for: sessionEntry(
                    key: "main",
                    updatedAt: 1,
                    totalTokens: total,
                    totalTokensFresh: fresh,
                    contextTokens: context))
        }

        #expect(fraction(total: nil, context: 100) == nil)
        #expect(fraction(total: 25, context: nil) == nil)
        #expect(fraction(total: 25, context: 0) == nil)
        #expect(fraction(total: 25, context: -100) == nil)
        #expect(fraction(total: -1, context: 100) == nil)
        #expect(fraction(total: 25, fresh: false, context: 100) == nil)
        #expect(fraction(total: 150, context: 100) == 1)
        #expect(fraction(total: 25, fresh: nil, context: 100) == 0.25)
    }

    @Test @MainActor func `event listener does not retain discarded view model`() async throws {
        let transport = TestChatTransport(historyResponses: [historyPayload()])
        var viewModel: NovaChatViewModel? = NovaChatViewModel(
            sessionKey: "main",
            transport: transport)
        transport.emit(.health(ok: true))
        for _ in 0..<100 where viewModel?.healthOK != true {
            await Task.yield()
        }
        #expect(viewModel?.healthOK == true)
        let discardedViewModel = try weakReference(to: viewModel)

        viewModel = nil
        await Task.yield()

        #expect(discardedViewModel.value == nil)
    }

    @Test func `decodes in-flight run from chat history`() throws {
        let data = #"{"sessionKey":"main","messages":[],"inFlightRun":{"runId":"run-active","text":"partial","plan":{"steps":[{"step":"Reconnect","status":"in_progress"}],"explanation":"Current work"}}}"#
            .data(using: .utf8)!

        let payload = try JSONDecoder().decode(NovaChatHistoryPayload.self, from: data)

        #expect(payload.inFlightRun?.runId == "run-active")
        #expect(payload.inFlightRun?.text == "partial")
        #expect(payload.inFlightRun?.plan?.steps == [
            NovaChatPlanStep(step: "Reconnect", status: .inProgress),
        ])
        #expect(payload.inFlightRun?.plan?.explanation == "Current work")
    }

    @Test func `decodes agent scope from chat event`() throws {
        let data = #"{"runId":"run-global","sessionKey":"global","agentId":"work","state":"delta"}"#
            .data(using: .utf8)!

        let payload = try JSONDecoder().decode(NovaChatEventPayload.self, from: data)

        #expect(payload.agentId == "work")
    }

    @Test func `bootstrap adopts active history run and consumes live events`() async throws {
        let activeHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "keep working", timestamp: 1)],
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "partial reply"))
        let completedHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "keep working", timestamp: 1),
                chatTextMessage(role: "assistant", text: "finished reply", timestamp: 2),
            ])
        let (transport, vm) = await makeViewModel(historyResponses: [activeHistory, completedHistory])

        try await loadAndWaitBootstrap(vm: vm)

        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == "partial reply")

        emitAssistantText(transport: transport, runId: "run-active", text: "newer partial")
        try await waitUntil("adopted run consumes live delta") {
            await MainActor.run { vm.streamingAssistantText == "newer partial" }
        }

        emitExternalFinal(transport: transport, runId: "run-active")
        try await waitUntil("adopted run completes") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.streamingAssistantText == nil &&
                    vm.messages.contains { $0.content.contains { $0.text == "finished reply" } }
            }
        }
    }

    @Test func `adopts Codex history run without buffered text`() async throws {
        let history = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-codex", text: ""))
        let (_, vm) = await makeViewModel(historyResponses: [history])

        try await loadAndWaitBootstrap(vm: vm)

        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == nil)
        #expect(await MainActor.run { !vm.canSend })
    }

    @Test func `bootstrap adopts in-flight plan snapshot`() async throws {
        let history = historyPayload(
            inFlightRun: NovaChatInFlightRun(
                runId: "run-plan",
                text: "working",
                plan: NovaChatPlanSnapshot(
                    steps: [
                        NovaChatPlanStep(step: "Inspect", status: .completed),
                        NovaChatPlanStep(step: "Reconnect", status: .inProgress),
                    ],
                    explanation: "Restore checklist")))
        let (_, vm) = await makeViewModel(historyResponses: [history])

        try await loadAndWaitBootstrap(vm: vm)

        #expect(await MainActor.run { vm.planRunId } == "run-plan")
        #expect(await MainActor.run { vm.planSteps } == [
            NovaChatPlanStep(step: "Inspect", status: .completed),
            NovaChatPlanStep(step: "Reconnect", status: .inProgress),
        ])
        #expect(await MainActor.run { vm.planExplanation } == "Restore checklist")
    }

    @Test func `history plan reconciliation contract`() async {
        let retainedSteps = [NovaChatPlanStep(step: "Retained", status: .inProgress)]
        let liveSteps = [NovaChatPlanStep(step: "New live plan", status: .inProgress)]
        let cases: [(
            name: String,
            payload: NovaChatHistoryPayload,
            expectedRunId: String?,
            expectedSteps: [NovaChatPlanStep],
            staleAfterLivePlan: Bool)] = [
            (
                "replace",
                historyPayload(
                    inFlightRun: NovaChatInFlightRun(
                        runId: "run-retained",
                        text: "working",
                        plan: NovaChatPlanSnapshot(
                            steps: [NovaChatPlanStep(step: "Replacement", status: .completed)]))),
                "run-retained",
                [NovaChatPlanStep(step: "Replacement", status: .completed)],
                false),
            (
                "legacy-preserve",
                historyPayload(
                    inFlightRun: NovaChatInFlightRun(runId: "run-retained", text: "working")),
                "run-retained",
                retainedSteps,
                false),
            (
                "superseded",
                historyPayload(
                    inFlightRun: NovaChatInFlightRun(
                        runId: "run-next",
                        text: "next",
                        plan: NovaChatPlanSnapshot(
                            steps: [NovaChatPlanStep(step: "Next run", status: .inProgress)]))),
                "run-next",
                [NovaChatPlanStep(step: "Next run", status: .inProgress)],
                false),
            (
                "active-preserve",
                historyPayload(hasActiveRun: true, activeRunIds: ["run-retained"]),
                "run-retained",
                retainedSteps,
                false),
            (
                "terminal-clear",
                historyPayload(hasActiveRun: false, activeRunIds: []),
                nil,
                [],
                false),
            (
                "no-evidence-preserve",
                historyPayload(supportsActiveRunState: false),
                "run-retained",
                retainedSteps,
                false),
            (
                "stale-response-does-not-clobber-newer-live-plan",
                historyPayload(hasActiveRun: false, activeRunIds: []),
                "run-live",
                liveSteps,
                true),
            (
                "explicit-empty-clears",
                historyPayload(
                    inFlightRun: NovaChatInFlightRun(
                        runId: "run-retained",
                        text: "working",
                        plan: NovaChatPlanSnapshot(steps: []))),
                nil,
                [],
                false),
        ]

        for testCase in cases {
            let (_, vm) = await makeViewModel(historyResponses: [])
            await MainActor.run {
                vm.applyPlanSnapshot(
                    runId: "run-retained",
                    steps: retainedSteps,
                    explanation: nil)
                let request = vm.beginHistoryRequest()
                if testCase.staleAfterLivePlan {
                    vm.invalidateRunSnapshots()
                    vm.adoptRun(runId: "run-live", bufferedText: "live")
                    vm.applyPlanSnapshot(runId: "run-live", steps: liveSteps, explanation: nil)
                }
                #expect(
                    vm.applyHistoryPayload(
                        testCase.payload,
                        for: request,
                        preservingOptimisticLocalMessages: true),
                    "\(testCase.name): history applies")
                #expect(vm.planRunId == testCase.expectedRunId, "\(testCase.name): run owner")
                #expect(vm.planSteps == testCase.expectedSteps, "\(testCase.name): steps")
            }
        }
    }

    @Test func `foreground history refreshes adopted run snapshot`() async throws {
        let firstHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "first partial"))
        let resumedHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "resumed partial"))
        let historyCalls = AsyncCounter()
        let (_, vm) = await makeViewModel(
            historyResponses: [firstHistory, resumedHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() })

        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial in-flight snapshot applied") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "first partial"
            }
        }
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("foreground history requested") {
            await historyCalls.current() == 2
        }

        try await waitUntil("foreground snapshot applied") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "resumed partial"
            }
        }
    }

    @Test func `active history retains repeated optimistic user when new row is absent`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let olderUser = chatTextMessage(
            role: "user",
            text: "repeat request",
            timestamp: now - 10000,
            idempotencyKey: "older:prompt")
        let olderAssistant = chatTextMessage(
            role: "assistant",
            text: "older reply",
            timestamp: now - 9000,
            idempotencyKey: "older:assistant")
        let existingHistory = historyPayload(messages: [olderUser, olderAssistant])
        let (_, vm) = await makeViewModel(
            historyResponses: [existingHistory],
            historyResponseHook: { _, index, sentRunIds in
                guard index > 0, let runId = sentRunIds.last else { return nil }
                return historyPayload(
                    messages: [olderUser, olderAssistant],
                    inFlightRun: NovaChatInFlightRun(runId: runId, text: "working"))
            },
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "repeat request")
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }

        try await waitUntil("repeated optimistic user survives incomplete active history") {
            await MainActor.run {
                vm.pendingRunCount == 1 &&
                    vm.messages.count(where: {
                        $0.role == "user" && $0.content.first?.text == "repeat request"
                    }) == 2 &&
                    vm.messages.contains(where: { $0.id == optimisticID })
            }
        }
    }

    @Test func `foreground discovers run started without local ownership`() async throws {
        let idleHistory = historyPayload()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-external", text: "external partial"))
        let (_, vm) = await makeViewModel(historyResponses: [idleHistory, activeHistory])

        try await loadAndWaitBootstrap(vm: vm)
        #expect(await MainActor.run { vm.pendingRunCount } == 0)
        await MainActor.run { vm.resumeFromForeground() }

        try await waitUntil("foreground external run discovered") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "external partial"
            }
        }
    }

    @Test func `foreground keeps active run with intermediate assistant history`() async throws {
        let idleHistory = historyPayload()
        let activeHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "use a tool", timestamp: 1),
                chatTextMessage(role: "assistant", text: "intermediate output", timestamp: 2),
            ],
            inFlightRun: NovaChatInFlightRun(runId: "run-tool", text: "still working"))
        let (_, vm) = await makeViewModel(historyResponses: [idleHistory, activeHistory])

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }

        try await waitUntil("foreground tool run discovered") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "still working"
            }
        }
        #expect(await MainActor.run { !vm.canSend })
    }

    @Test func `active session history preserves the known pending run`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let historyCalls = AsyncCounter()
        let userOnlyHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "quiet task", timestamp: now)],
            hasActiveRun: true)
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(), userOnlyHistory, userOnlyHistory, userOnlyHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            sendMessageStatus: "pending")

        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "quiet task")
        try await waitUntil("send refresh applies user-only history") {
            await historyCalls.current() == 2
        }
        #expect(await MainActor.run { vm.pendingRunCount == 1 })
        try await waitUntil("post-send fallback keeps known run ownership", timeoutSeconds: 7.0) {
            let historyCount = await historyCalls.current()
            let pendingRunCount = await MainActor.run { vm.pendingRunCount }
            return historyCount >= 3 && pendingRunCount == 1
        }
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("foreground history applies") {
            await historyCalls.current() >= 4
        }
        #expect(await MainActor.run { vm.pendingRunCount == 1 })
        #expect(await MainActor.run { !vm.hasActiveSessionRunWithoutChatSnapshot })
        await MainActor.run { vm.input = "another task" }
        #expect(await MainActor.run { !vm.canSend })
        await MainActor.run { vm.send() }
        await Task.yield()
        #expect(await transport.sentMessages() == ["quiet task"])

        let runId = try await waitForLastSentRunId(transport)
        emitAgentLifecycleEnd(transport: transport, runId: runId)
        try await waitUntil("terminal lifecycle clears known run activity") {
            await MainActor.run {
                vm.pendingRunCount == 0 && !vm.hasActiveSessionRunWithoutChatSnapshot
            }
        }
    }

    @Test func `foreground synthesizes activity when no run snapshot or local run exists`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let historyCalls = AsyncCounter()
        let userOnlyHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "quiet task", timestamp: now)],
            hasActiveRun: true)
        let (transport, vm) = await makeViewModel(
            historyResponses: [userOnlyHistory, userOnlyHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() })

        try await loadAndWaitBootstrap(vm: vm)
        #expect(await MainActor.run { vm.pendingRunCount == 0 })
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("foreground history applies") {
            await historyCalls.current() == 2
        }
        #expect(await MainActor.run { vm.hasActiveSessionRunWithoutChatSnapshot })

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "main",
                    message: chatTextModelMessage(role: "assistant", text: "done", timestamp: now + 1),
                    messageId: "msg-done",
                    messageSeq: 2)))
        try await waitUntil("assistant session message clears activity indicator") {
            await MainActor.run { !vm.hasActiveSessionRunWithoutChatSnapshot }
        }
    }

    @Test func `session switch clears active session activity indicator`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let historyCalls = AsyncCounter()
        let userOnlyHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "quiet task", timestamp: now)],
            hasActiveRun: true)
        let (_, vm) = await makeViewModel(
            historyResponses: [userOnlyHistory, userOnlyHistory, historyPayload(sessionKey: "other")],
            requestHistoryHook: { _ in _ = await historyCalls.increment() })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("foreground history applies") {
            await historyCalls.current() == 2
        }
        #expect(await MainActor.run { vm.hasActiveSessionRunWithoutChatSnapshot })

        await MainActor.run { vm.switchSession(to: "other") }
        try await waitUntil("other session bootstrap applies") {
            await historyCalls.current() == 3
        }
        await MainActor.run { vm.input = "new task" }
        #expect(await MainActor.run { !vm.hasActiveSessionRunWithoutChatSnapshot })
        #expect(await MainActor.run { vm.canSend })
    }

    @Test func `foreground clears completed run without assistant output`() async throws {
        let activeHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "quiet task", timestamp: 1)],
            inFlightRun: NovaChatInFlightRun(
                runId: "run-quiet",
                text: "",
                plan: NovaChatPlanSnapshot(
                    steps: [NovaChatPlanStep(step: "Finish", status: .inProgress)])))
        let completedHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "quiet task", timestamp: 1)],
            hasActiveRun: false)
        let (_, vm) = await makeViewModel(historyResponses: [activeHistory, completedHistory])

        try await loadAndWaitBootstrap(vm: vm)
        #expect(await MainActor.run { vm.pendingRunCount == 1 })
        #expect(await MainActor.run { vm.planRunId == "run-quiet" })
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("silent completed run clears") {
            await MainActor.run { vm.pendingRunCount == 0 }
        }
        #expect(await MainActor.run { !vm.hasActiveSessionRunWithoutChatSnapshot })
        #expect(await MainActor.run { vm.planSteps.isEmpty && vm.planRunId == nil })
    }

    @Test func `foreground active session with answered chat does not show activity indicator`() async throws {
        let answeredHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "done", timestamp: 1),
                chatTextMessage(role: "assistant", text: "finished", timestamp: 2),
            ],
            hasActiveRun: true)
        let (_, vm) = await makeViewModel(historyResponses: [historyPayload(), answeredHistory])

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("answered history applies") {
            await MainActor.run { vm.messages.count == 2 }
        }

        #expect(await MainActor.run { vm.pendingRunCount == 0 })
        #expect(await MainActor.run { !vm.hasActiveSessionRunWithoutChatSnapshot })
    }

    @Test func `foreground missing snapshot does not clear an in-flight send`() async throws {
        let sendGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "accepted"))
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(), historyPayload(), activeHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            sendMessageHook: { _ in
                await sendGate.wait()
                return NovaChatSendResponse(runId: "run-active", status: "pending")
            })

        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "send while resuming")
        try await waitUntil("send request is in flight") {
            await MainActor.run { vm.isSending && vm.pendingRunCount == 1 }
        }
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("foreground history applies") { await historyCalls.current() == 2 }
        #expect(await MainActor.run { vm.pendingRunCount == 1 })

        await sendGate.open()
        try await waitUntil("accepted run snapshot applies") {
            await MainActor.run {
                !vm.isSending && vm.pendingRunCount == 1 && vm.streamingAssistantText == "accepted"
            }
        }
    }

    @Test func `post-send history keeps active run with intermediate assistant output`() async throws {
        let activeHistory = historyPayload(
            messages: [chatTextMessage(role: "assistant", text: "intermediate", timestamp: 2)],
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "working"))
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(), activeHistory],
            sendMessageHook: { _ in
                NovaChatSendResponse(runId: "run-active", status: "pending")
            })

        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "do work")
        try await waitUntil("post-send active run remains pending") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "working"
            }
        }
    }

    @Test func `post-send stale inactive history preserves newer live plan`() async throws {
        let historyGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let inactiveHistory = historyPayload(hasActiveRun: false)
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(), inactiveHistory],
            requestHistoryHook: { _ in
                if await historyCalls.increment() == 2 {
                    await historyGate.wait()
                }
            },
            sendMessageStatus: "pending")

        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "finish while disconnected")
        let runId = try await waitForLastSentRunId(transport)
        try await waitUntil("post-send history starts") { await historyCalls.current() == 2 }
        emitPlan(
            transport: transport,
            runId: runId,
            steps: [planStep("Finish", status: "in_progress")])
        try await waitUntil("plan applies before inactive history") {
            await MainActor.run { vm.planRunId == runId }
        }

        await historyGate.open()
        try await Task.sleep(for: .milliseconds(50))
        #expect(await MainActor.run { vm.planRunId == runId })
        #expect(await MainActor.run { vm.planSteps == [
            NovaChatPlanStep(step: "Finish", status: .inProgress),
        ] })
    }

    @Test func `legacy history omission does not clear pending run`() async throws {
        let legacyHistory = historyPayload(supportsActiveRunState: false)
        let (_, vm) = await makeViewModel(
            historyResponses: [legacyHistory, legacyHistory, legacyHistory],
            sendMessageStatus: "pending")

        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "legacy gateway")
        try await waitUntil("legacy send remains pending") {
            await MainActor.run { !vm.isSending && vm.pendingRunCount == 1 }
        }
        try await Task.sleep(for: .milliseconds(1700))
        #expect(await MainActor.run { vm.pendingRunCount == 1 })
    }

    @Test func `external delta does not replace owned run`() async throws {
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm, text: "local work")
        let runId = try await waitForLastSentRunId(transport)
        try await waitUntil("local run owned") { await MainActor.run { vm.pendingRunCount == 1 } }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "other-run",
                    sessionKey: "main",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "other output", timestamp: 2),
                    errorMessage: nil)))
        try await Task.sleep(for: .milliseconds(50))
        #expect(await MainActor.run { vm.streamingAssistantText == nil })

        emitAssistantText(transport: transport, runId: runId, text: "local output")
        try await waitUntil("owned run still consumes deltas") {
            await MainActor.run { vm.streamingAssistantText == "local output" }
        }
    }

    @Test func `live chat delta owns run while bootstrap history is pending`() async throws {
        let historyGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let staleHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "older", timestamp: 1),
                chatTextMessage(role: "assistant", text: "same reply", timestamp: 2),
                chatTextMessage(role: "user", text: "current", timestamp: 3),
            ],
            inFlightRun: NovaChatInFlightRun(runId: "run-stale", text: "stale partial"))
        let (transport, vm) = await makeViewModel(
            historyResponses: [staleHistory],
            requestHistoryHook: { _ in
                _ = await historyCalls.increment()
                await historyGate.wait()
            })

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history starts") { await historyCalls.current() == 1 }
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-live",
                    sessionKey: "main",
                    state: "delta",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "live partial",
                        timestamp: 1),
                    errorMessage: nil)))

        try await waitUntil("live delta owns run") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "live partial"
            }
        }
        await historyGate.open()
        try await waitUntil("bootstrap completes") { await MainActor.run { vm.healthOK } }
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == "live partial")

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-live",
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(role: "assistant", text: "same reply", timestamp: 4),
                    errorMessage: nil)))
        try await waitUntil("live final remains scoped to current user") {
            await MainActor.run { vm.messages.count { $0.content.first?.text == "same reply" } == 2 }
        }
    }

    @Test func `global chat delta adopts only selected agent run`() async throws {
        let bareGlobalMatches = await MainActor.run {
            (
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "global",
                    agentId: "work",
                    current: "global",
                    mainSessionKey: "main",
                    activeAgentId: "main"),
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "global",
                    agentId: "main",
                    current: "global",
                    mainSessionKey: "main",
                    activeAgentId: "main"))
        }
        #expect(!bareGlobalMatches.0)
        #expect(bareGlobalMatches.1)
        #expect(await MainActor.run {
            !NovaChatViewModel.matchesCurrentSessionKey(
                incoming: "global",
                agentId: "work",
                current: "global",
                mainSessionKey: "main")
        })
        #expect(await MainActor.run {
            NovaChatViewModel.matchesCurrentSessionKey(
                incoming: "global",
                current: "global",
                mainSessionKey: "main",
                activeAgentId: "main")
        })
        #expect(await MainActor.run {
            NovaChatViewModel.matchesCurrentSessionKey(
                incoming: "global",
                current: "global",
                mainSessionKey: "main",
                activeAgentId: "work")
        })
        let globalAliasMatches = await MainActor.run {
            (
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "global",
                    agentId: "work",
                    current: "main",
                    mainSessionKey: "global",
                    activeAgentId: "main"),
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "global",
                    agentId: "main",
                    current: "main",
                    mainSessionKey: "global",
                    activeAgentId: "main"))
        }
        #expect(!globalAliasMatches.0)
        #expect(globalAliasMatches.1)
        #expect(await MainActor.run {
            !NovaChatViewModel.matchesCurrentSessionKey(
                incoming: "main",
                agentId: "work",
                current: "global",
                mainSessionKey: "global",
                activeAgentId: "main")
        })
        #expect(await MainActor.run {
            !NovaChatViewModel.matchesCurrentSessionKey(
                incoming: "global",
                current: "global",
                mainSessionKey: "main")
        })

        let (transport, vm) = await makeViewModel(
            sessionKey: "global",
            activeAgentId: "work",
            historyResponses: [historyPayload(sessionKey: "global")])
        try await loadAndWaitBootstrap(vm: vm)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-other",
                    sessionKey: "global",
                    agentId: "main",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "wrong agent", timestamp: 1),
                    errorMessage: nil)))
        try await Task.sleep(for: .milliseconds(50))
        #expect(await MainActor.run { vm.pendingRunCount } == 0)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-work",
                    sessionKey: "global",
                    agentId: "work",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "selected agent", timestamp: 2),
                    errorMessage: nil)))
        try await waitUntil("selected global run adopted") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "selected agent"
            }
        }

        let (lateTransport, lateVM) = await makeViewModel(
            sessionKey: "global",
            historyResponses: [historyPayload(sessionKey: "global")])
        try await loadAndWaitBootstrap(vm: lateVM)
        lateTransport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-late",
                    sessionKey: "global",
                    agentId: "work",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "late identity", timestamp: 3),
                    errorMessage: nil)))
        try await Task.sleep(for: .milliseconds(50))
        #expect(await MainActor.run { lateVM.pendingRunCount == 0 })
        await MainActor.run { lateVM.syncActiveAgentId("work") }
        lateTransport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-late",
                    sessionKey: "global",
                    agentId: "work",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "late identity", timestamp: 3),
                    errorMessage: nil)))
        try await waitUntil("late global agent identity adopts run") {
            await MainActor.run { lateVM.pendingRunCount == 1 }
        }
    }

    @Test func `global agent switch clears previous run ownership`() async throws {
        let (transport, vm) = await makeViewModel(
            sessionKey: "global",
            activeAgentId: "main",
            historyResponses: [
                historyPayload(sessionKey: "global"),
                historyPayload(sessionKey: "global"),
            ])
        try await loadAndWaitBootstrap(vm: vm)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-main",
                    sessionKey: "global",
                    agentId: "main",
                    state: "delta",
                    message: chatTextMessage(role: "assistant", text: "old partial", timestamp: 1),
                    errorMessage: nil)))
        try await waitUntil("main run becomes pending") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "old partial"
            }
        }

        await MainActor.run { vm.syncActiveAgentId("work") }

        #expect(await MainActor.run { vm.pendingRunCount } == 0)
        #expect(await MainActor.run { vm.streamingAssistantText } == nil)
        #expect(await MainActor.run { vm.messages.isEmpty })
    }

    @Test func `live send binds the captured agent and routing contract`() async throws {
        let contract = "per-sender|main|reviewer"
        let (transport, vm) = await makeViewModel(
            activeAgentId: "reviewer",
            historyResponses: [historyPayload(), historyPayload()],
            sessionRoutingContract: contract)
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "route safely")
        _ = try await waitForLastSentRunId(transport)

        #expect(await transport.sentAgentIDs() == ["reviewer"])
        #expect(await transport.sentRoutingContracts() == [contract])
    }

    @Test func `alias routing contract change restarts bootstrap`() async throws {
        let historyCalls = AsyncCounter()
        let oldHistory = historyPayload(messages: [
            chatTextMessage(role: "assistant", text: "old route", timestamp: 1),
        ])
        let newHistory = historyPayload(messages: [
            chatTextMessage(role: "assistant", text: "new route", timestamp: 2),
        ])
        let (_, vm) = await makeViewModel(
            activeAgentId: "main",
            historyResponses: [oldHistory, newHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() })
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial route history") {
            await MainActor.run { vm.messages.first?.content.first?.text == "old route" }
        }

        await MainActor.run {
            vm.syncDeliveryIdentity(
                activeAgentId: "work",
                sessionRoutingContract: "per-sender|work-main|work")
        }

        try await waitUntil("replacement route history") {
            guard await historyCalls.current() == 2 else { return false }
            return await MainActor.run { vm.messages.first?.content.first?.text == "new route" }
        }
    }

    @Test func `custom main routing contract change restarts bootstrap`() async throws {
        let historyCalls = AsyncCounter()
        let oldHistory = historyPayload(
            sessionKey: "agent:ops:work",
            messages: [chatTextMessage(role: "assistant", text: "old scope", timestamp: 1)])
        let newHistory = historyPayload(
            sessionKey: "agent:ops:work",
            messages: [chatTextMessage(role: "assistant", text: "new scope", timestamp: 2)])
        let (_, vm) = await makeViewModel(
            sessionKey: "agent:ops:work",
            activeAgentId: "ops",
            historyResponses: [oldHistory, newHistory],
            sessionRoutingContract: "global|work|ops",
            requestHistoryHook: { _ in _ = await historyCalls.increment() })
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial custom main history") {
            await MainActor.run { vm.messages.first?.content.first?.text == "old scope" }
        }

        await MainActor.run {
            vm.syncSessionRoutingContract("per-sender|work|ops")
        }

        try await waitUntil("replacement custom main history") {
            guard await historyCalls.current() == 2 else { return false }
            return await MainActor.run { vm.messages.first?.content.first?.text == "new scope" }
        }
    }

    @Test func `unscoped agent update replaces an active bootstrap`() async throws {
        let firstHistoryGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let firstHistory = historyPayload(
            sessionKey: "Matrix:!Room:example.org",
            messages: [chatTextMessage(role: "assistant", text: "old agent", timestamp: 1)])
        let replacementHistory = historyPayload(
            sessionKey: "Matrix:!Room:example.org",
            messages: [chatTextMessage(role: "assistant", text: "new agent", timestamp: 2)])
        let (_, vm) = await makeViewModel(
            sessionKey: "Matrix:!Room:example.org",
            historyResponses: [firstHistory, replacementHistory],
            requestHistoryHook: { _ in
                let call = await historyCalls.increment()
                if call == 1 {
                    await firstHistoryGate.wait()
                }
            })

        await MainActor.run { vm.load() }
        try await waitUntil("first unscoped bootstrap") { await historyCalls.current() == 1 }
        await MainActor.run { vm.syncActiveAgentId("work") }
        try await waitUntil("replacement unscoped bootstrap") {
            guard await historyCalls.current() == 2 else { return false }
            return await MainActor.run {
                !vm.isLoading && vm.messages.first?.content.first?.text == "new agent"
            }
        }
        await firstHistoryGate.open()
        try await Task.sleep(for: .milliseconds(25))
        #expect(await MainActor.run { vm.messages.first?.content.first?.text } == "new agent")
    }

    @Test func `intermediate session message preserves pending recovery snapshot`() async throws {
        let historyGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "active partial"))
        let (transport, vm) = await makeViewModel(
            historyResponses: [activeHistory],
            requestHistoryHook: { _ in
                _ = await historyCalls.increment()
                await historyGate.wait()
            })

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history starts") { await historyCalls.current() == 1 }
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "intermediate output",
                        timestamp: 1),
                    messageId: "msg-intermediate",
                    messageSeq: 1)))
        try await waitUntil("intermediate assistant message applies") {
            await MainActor.run { vm.messages.contains { $0.content.first?.text == "intermediate output" } }
        }

        await historyGate.open()
        try await waitUntil("bootstrap active run adopted") {
            await MainActor.run {
                vm.pendingRunCount == 1 &&
                    vm.streamingAssistantText == "active partial" &&
                    vm.messages.contains { $0.content.first?.text == "intermediate output" }
            }
        }
    }

    @Test func `manual refresh re-adopts active run after clearing local ownership`() async throws {
        let firstHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "first partial"))
        let refreshedHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "refreshed partial"))
        let (_, vm) = await makeViewModel(historyResponses: [firstHistory, refreshedHistory])

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.refresh() }

        try await waitUntil("manual refresh snapshot applied") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "refreshed partial"
            }
        }
    }

    @Test func `older history cannot replace newer run snapshot`() async throws {
        let olderGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let olderCompletions = AsyncCounter()
        let initialHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-initial", text: "initial"))
        let (_, vm) = await makeViewModel(
            historyResponses: [initialHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                if index == 1 {
                    await olderGate.wait()
                    _ = await olderCompletions.increment()
                    return historyPayload(
                        inFlightRun: NovaChatInFlightRun(runId: "run-older", text: "older"))
                }
                if index == 2 {
                    return historyPayload(
                        inFlightRun: NovaChatInFlightRun(runId: "run-newer", text: "newer"))
                }
                return nil
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("older foreground history starts") { await historyCalls.current() == 2 }
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("newer run snapshot applies") {
            await MainActor.run { vm.streamingAssistantText == "newer" }
        }

        await olderGate.open()
        try await waitUntil("older foreground history completes") { await olderCompletions.current() == 1 }
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == "newer")
    }

    @Test func `delayed history cannot overwrite newer live run text`() async throws {
        let staleGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let staleCompletions = AsyncCounter()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "initial"))
        let (transport, vm) = await makeViewModel(
            historyResponses: [activeHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                await staleGate.wait()
                _ = await staleCompletions.increment()
                return historyPayload(
                    inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "stale"))
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("stale foreground history starts") { await historyCalls.current() == 2 }

        emitAssistantText(transport: transport, runId: "run-active", text: "live newer")
        try await waitUntil("newer live run text applies") {
            await MainActor.run { vm.streamingAssistantText == "live newer" }
        }

        await staleGate.open()
        try await waitUntil("stale foreground history completes") { await staleCompletions.current() == 1 }
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == "live newer")
    }

    @Test func `stale foreground completion cannot clear newer live run`() async throws {
        let staleGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let activeHistory = historyPayload(
            messages: [chatTextMessage(role: "user", text: "keep going", timestamp: 1)],
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "initial"))
        let staleCompletedHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "keep going", timestamp: 1),
                chatTextMessage(role: "assistant", text: "stale completion", timestamp: 2),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [activeHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                await staleGate.wait()
                return staleCompletedHistory
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("stale foreground history starts") { await historyCalls.current() == 2 }
        emitAssistantText(transport: transport, runId: "run-active", text: "live newer")
        try await waitUntil("newer live run text applies") {
            await MainActor.run { vm.streamingAssistantText == "live newer" }
        }

        await staleGate.open()
        try await waitUntil("stale history transcript applies") {
            await MainActor.run { vm.messages.contains { $0.content.first?.text == "stale completion" } }
        }
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.streamingAssistantText } == "live newer")
    }

    @Test func `terminal event invalidates delayed active run snapshot`() async throws {
        let staleGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let staleCompletions = AsyncCounter()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "working"))
        let completedHistory = historyPayload(
            messages: [chatTextMessage(role: "assistant", text: "done", timestamp: 2)])
        let (transport, vm) = await makeViewModel(
            historyResponses: [activeHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                if index == 1 {
                    await staleGate.wait()
                    _ = await staleCompletions.increment()
                    return activeHistory
                }
                return index == 2 ? completedHistory : nil
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("stale foreground history starts") { await historyCalls.current() == 2 }

        emitExternalFinal(transport: transport, runId: "run-active")
        try await waitUntil("terminal history applies") {
            await MainActor.run {
                vm.pendingRunCount == 0 && vm.messages.contains { $0.content.contains { $0.text == "done" } }
            }
        }

        await staleGate.open()
        try await waitUntil("stale foreground history completes") { await staleCompletions.current() == 1 }
        #expect(await MainActor.run { vm.pendingRunCount } == 0)
        #expect(await MainActor.run { vm.streamingAssistantText } == nil)
    }

    @Test func `delayed history cannot erase terminal event message`() async throws {
        let staleGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let staleCompletions = AsyncCounter()
        let activeHistory = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "older turn", timestamp: 0),
                chatTextMessage(role: "assistant", text: "live final", timestamp: 0.5),
                chatTextMessage(role: "user", text: "finish this", timestamp: 1),
            ],
            inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "working"))
        let (transport, vm) = await makeViewModel(
            historyResponses: [activeHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                if index == 1 {
                    await staleGate.wait()
                    _ = await staleCompletions.increment()
                    return historyPayload(
                        messages: [
                            chatTextMessage(role: "user", text: "older turn", timestamp: 0),
                            chatTextMessage(role: "assistant", text: "live final", timestamp: 0.5),
                            chatTextMessage(role: "user", text: "finish this", timestamp: 1),
                        ],
                        inFlightRun: NovaChatInFlightRun(runId: "run-active", text: "stale"))
                }
                if index == 2 {
                    throw NSError(domain: "test", code: 1)
                }
                return nil
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("stale foreground history starts") { await historyCalls.current() == 2 }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "run-active",
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(role: "assistant", text: "live final", timestamp: 2),
                    errorMessage: nil)))
        try await waitUntil("terminal event message appears") {
            await MainActor.run { vm.messages.count { $0.content.first?.text == "live final" } == 2 }
        }
        try await waitUntil("terminal refresh attempted") { await historyCalls.current() == 3 }

        await staleGate.open()
        try await waitUntil("stale foreground history completes") { await staleCompletions.current() == 1 }
        #expect(await MainActor.run { vm.messages.count { $0.content.first?.text == "live final" } == 2 })
        #expect(await MainActor.run { vm.pendingRunCount } == 0)
    }

    @Test func `external terminal event protects current run from delayed snapshot`() async throws {
        let staleGate = AsyncGate()
        let historyCalls = AsyncCounter()
        let staleCompletions = AsyncCounter()
        let currentHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-current", text: "current"))
        let (transport, vm) = await makeViewModel(
            historyResponses: [currentHistory],
            requestHistoryHook: { _ in _ = await historyCalls.increment() },
            historyResponseHook: { _, index, _ in
                if index == 1 {
                    await staleGate.wait()
                    _ = await staleCompletions.increment()
                    return historyPayload(
                        inFlightRun: NovaChatInFlightRun(runId: "run-finished", text: "stale"))
                }
                if index == 2 {
                    throw NSError(domain: "test", code: 1)
                }
                return nil
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.resumeFromForeground() }
        try await waitUntil("stale foreground history starts") { await historyCalls.current() == 2 }

        emitExternalFinal(transport: transport, runId: "run-finished")
        try await waitUntil("terminal refresh attempted") { await historyCalls.current() == 3 }
        await staleGate.open()
        try await waitUntil("stale foreground history completes") { await staleCompletions.current() == 1 }

        emitAssistantText(transport: transport, runId: "run-current", text: "current live")
        try await waitUntil("current run still owns live events") {
            await MainActor.run { vm.streamingAssistantText == "current live" }
        }
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
    }

    @Test func `sequence gap re-adopts active run from history`() async throws {
        let initialHistory = historyPayload()
        let recoveredHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(runId: "run-recovered", text: "recovered partial"))
        let (transport, vm) = await makeViewModel(historyResponses: [initialHistory, recoveredHistory])

        try await loadAndWaitBootstrap(vm: vm)
        transport.emit(.seqGap)

        try await waitUntil("sequence gap run recovered") {
            await MainActor.run {
                vm.pendingRunCount == 1 && vm.streamingAssistantText == "recovered partial"
            }
        }
    }

    @Test func `keeps distinct idempotent user turns with identical timestamps and content`() async throws {
        let history = historyPayload(
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same words",
                    timestamp: 1,
                    idempotencyKey: "client-a:user"),
                chatTextMessage(
                    role: "user",
                    text: "same words",
                    timestamp: 1,
                    idempotencyKey: "client-b:user"),
            ])
        let (_, vm) = await makeViewModel(historyResponses: [history])

        try await loadAndWaitBootstrap(vm: vm)

        #expect(await MainActor.run { vm.messages.count } == 2)
    }

    @Test func `timeline revision advances when visible history changes`() async throws {
        let history = historyPayload(
            sessionId: "revision-session",
            messages: [chatTextMessage(role: "user", text: "hello", timestamp: 1)])
        let (_, vm) = await makeViewModel(historyResponses: [history])
        let before = await MainActor.run { vm.timelineRevision }

        try await loadAndWaitBootstrap(vm: vm, sessionId: "revision-session")

        let after = await MainActor.run { vm.timelineRevision }
        #expect(after > before)
    }

    @Test func `timeline revision ignores identical history refresh`() async throws {
        let message = chatTextMessage(role: "user", text: "hello", timestamp: 1)
        let firstHistory = historyPayload(sessionId: "revision-session-1", messages: [message])
        let secondHistory = historyPayload(sessionId: "revision-session-2", messages: [message])
        let (_, vm) = await makeViewModel(historyResponses: [firstHistory, secondHistory])
        try await loadAndWaitBootstrap(vm: vm, sessionId: "revision-session-1")
        let before = await MainActor.run { vm.timelineRevision }

        await MainActor.run { vm.refresh() }
        try await waitUntil("identical history refresh") {
            await MainActor.run { vm.sessionId == "revision-session-2" }
        }

        let after = await MainActor.run { vm.timelineRevision }
        #expect(after == before)
    }

    @Test func `displays error message fallback only for assistant error turns`() throws {
        func decodeMessage(role: String, stopReason: String, contentText: String? = nil) throws -> NovaChatMessage {
            let contentJSON = contentText.map { #"[{"type":"text","text":"\#($0)"}]"# } ?? "[]"
            let data = """
            {
              "role": "\(role)",
              "content": \(contentJSON),
              "timestamp": 1,
              "stopReason": "\(stopReason)",
              "errorMessage": "stale provider failure"
            }
            """.data(using: .utf8)!
            return try JSONDecoder().decode(NovaChatMessage.self, from: data)
        }

        let assistantError = try decodeMessage(role: "assistant", stopReason: "error")
        #expect(assistantError.content.isEmpty)
        #expect(
            NovaChatMessage.errorDisplayText(
                role: assistantError.role,
                stopReason: assistantError.stopReason,
                errorMessage: assistantError.errorMessage) == "stale provider failure")
        #expect(
            NovaChatMessage.displayText(
                contentText: "",
                role: assistantError.role,
                stopReason: assistantError.stopReason,
                errorMessage: assistantError.errorMessage) == "stale provider failure")

        let sentinelAssistant = try decodeMessage(
            role: "assistant",
            stopReason: "error",
            contentText: "[assistant turn failed before producing content]")
        #expect(
            NovaChatMessage.displayText(
                contentText: sentinelAssistant.content.compactMap(\.text).joined(separator: "\n"),
                role: sentinelAssistant.role,
                stopReason: sentinelAssistant.stopReason,
                errorMessage: sentinelAssistant.errorMessage) == "stale provider failure")

        let partialAssistant = try decodeMessage(
            role: "assistant",
            stopReason: "error",
            contentText: "partial answer")
        #expect(
            NovaChatMessage.displayText(
                contentText: partialAssistant.content.compactMap(\.text).joined(separator: "\n"),
                role: partialAssistant.role,
                stopReason: partialAssistant.stopReason,
                errorMessage: partialAssistant.errorMessage) == "partial answer")

        let stoppedAssistant = try decodeMessage(role: "assistant", stopReason: "stop")
        #expect(stoppedAssistant.errorMessage == "stale provider failure")
        #expect(stoppedAssistant.content.isEmpty)
        #expect(
            NovaChatMessage.errorDisplayText(
                role: stoppedAssistant.role,
                stopReason: stoppedAssistant.stopReason,
                errorMessage: stoppedAssistant.errorMessage) == nil)

        let toolUseAssistant = try decodeMessage(role: "assistant", stopReason: "toolUse")
        #expect(toolUseAssistant.errorMessage == "stale provider failure")
        #expect(toolUseAssistant.content.isEmpty)
        #expect(
            NovaChatMessage.errorDisplayText(
                role: toolUseAssistant.role,
                stopReason: toolUseAssistant.stopReason,
                errorMessage: toolUseAssistant.errorMessage) == nil)
    }

    @Test func `streams assistant and clears on final`() async throws {
        let sessionId = "sess-main"
        let history1 = historyPayload(sessionId: sessionId)
        let history2 = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "final answer",
                    timestamp: Date().timeIntervalSince1970 * 1000),
            ])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm)
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)

        emitAssistantText(transport: transport, runId: runId, text: "streaming…")

        try await waitUntil("assistant stream visible") {
            await MainActor.run { vm.streamingAssistantText == "streaming…" }
        }

        emitToolStart(transport: transport, runId: runId)

        try await waitUntil("tool call pending") { await MainActor.run { vm.pendingToolCalls.count == 1 } }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: nil,
                    errorMessage: nil)))

        try await waitUntil("pending run clears") { await MainActor.run { vm.pendingRunCount == 0 } }
        try await waitUntil("history refresh") {
            await MainActor.run { vm.messages.contains(where: { $0.role == "assistant" }) }
        }
        #expect(await MainActor.run { vm.streamingAssistantText } == nil)
        #expect(await MainActor.run { vm.pendingToolCalls.isEmpty })
    }

    @Test func `dictation completion only updates its originating session`() async {
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionKey: "other", sessionId: "sess-other")])
        await MainActor.run {
            let startingSession = vm.currentSessionSnapshot()
            vm.switchSession(to: "other")
            vm.appendDictationTranscript("belongs to main", for: startingSession)
            #expect(vm.input.isEmpty)
            vm.appendDictationTranscript("belongs to other", for: vm.currentSessionSnapshot())
            #expect(vm.input == "belongs to other")
        }
    }

    @Test func `dictation completion cannot cross a same-session agent change`() async {
        let (_, vm) = await makeViewModel(
            activeAgentId: "alpha",
            historyResponses: [historyPayload(), historyPayload()])
        await MainActor.run {
            let alphaSession = vm.currentSessionSnapshot()
            vm.syncActiveAgentId("beta")
            vm.appendDictationTranscript("belongs to alpha", for: alphaSession)
            #expect(vm.input.isEmpty)
            vm.appendDictationTranscript("belongs to beta", for: vm.currentSessionSnapshot())
            #expect(vm.input == "belongs to beta")
        }
    }

    @Test func `dictation failure only updates its originating session`() async {
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionKey: "other", sessionId: "sess-other")])
        await MainActor.run {
            let startingSession = vm.currentSessionSnapshot()
            vm.switchSession(to: "other")
            vm.setDictationError(
                NSError(domain: "Dictation", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "stale dictation failure",
                ]),
                for: startingSession)
            #expect(vm.errorText == nil)
        }
    }

    @Test func `composer presentation owner changes when the model is replaced for the same session`() async {
        let (_, first) = await makeViewModel(historyResponses: [historyPayload()])
        let (_, replacement) = await makeViewModel(historyResponses: [historyPayload()])

        let firstOwner = await MainActor.run {
            NovaChatComposerPresentationOwner(viewModel: first)
        }
        let replacementOwner = await MainActor.run {
            NovaChatComposerPresentationOwner(viewModel: replacement)
        }

        #expect(firstOwner.session.key == replacementOwner.session.key)
        #expect(firstOwner != replacementOwner)
    }

    @Test func `composer presentation owner changes with same-session agent routing`() async {
        let (_, vm) = await makeViewModel(
            activeAgentId: "alpha",
            historyResponses: [historyPayload(), historyPayload()])

        let alphaOwner = await MainActor.run {
            NovaChatComposerPresentationOwner(viewModel: vm)
        }
        let betaOwner = await MainActor.run {
            vm.syncActiveAgentId("beta")
            return NovaChatComposerPresentationOwner(viewModel: vm)
        }

        #expect(alphaOwner.session.key == betaOwner.session.key)
        #expect(alphaOwner != betaOwner)
    }

    @Test func `camera attachment completion only updates its originating session`() async {
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionKey: "other", sessionId: "sess-other")])
        let originalSession = await MainActor.run {
            let session = vm.currentSessionSnapshot()
            vm.switchSession(to: "other")
            return session
        }

        await vm.addImageAttachment(
            data: Data([0]),
            fileName: "stale-camera.jpg",
            mimeType: "image/jpeg",
            for: originalSession)

        #expect(await MainActor.run { vm.attachments.isEmpty })
        #expect(await MainActor.run { vm.errorText == nil })
    }

    @Test func `camera attachment completion cannot cross a same-session agent change`() async {
        let (_, vm) = await makeViewModel(
            activeAgentId: "alpha",
            historyResponses: [historyPayload(), historyPayload()])
        let alphaSession = await MainActor.run {
            let session = vm.currentSessionSnapshot()
            vm.syncActiveAgentId("beta")
            return session
        }

        await vm.addImageAttachment(
            data: Data([0]),
            fileName: "stale-camera.jpg",
            mimeType: "image/jpeg",
            for: alphaSession)

        #expect(await MainActor.run { vm.attachments.isEmpty })
        #expect(await MainActor.run { vm.errorText == nil })
    }

    @Test func `file attachment completion cannot cross a same-session agent change`() async {
        let (_, vm) = await makeViewModel(
            activeAgentId: "alpha",
            historyResponses: [historyPayload(), historyPayload()])
        let alphaSession = await MainActor.run {
            let session = vm.currentSessionSnapshot()
            vm.syncActiveAgentId("beta")
            return session
        }

        await vm.loadAttachments(
            urls: [URL(fileURLWithPath: "/does-not-exist/stale-file.jpg")],
            expectedSession: alphaSession)

        #expect(await MainActor.run { vm.attachments.isEmpty })
        #expect(await MainActor.run { vm.errorText == nil })
    }

    @Test func `attachment staging defers a same-session agent change`() async {
        let (_, vm) = await makeViewModel(
            activeAgentId: "alpha",
            historyResponses: [historyPayload(), historyPayload()])

        await MainActor.run {
            let alphaSession = vm.currentSessionSnapshot()
            vm.beginAttachmentStaging()
            vm.syncActiveAgentId("beta")
            #expect(vm.activeAgentId == "alpha")
            #expect(vm.isCurrentSession(alphaSession))

            vm.endAttachmentStaging()
            #expect(vm.activeAgentId == "beta")
            #expect(!vm.isCurrentSession(alphaSession))
        }
    }

    @Test func `balances tool activity when a terminal event clears pending calls`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId)
        let recorder = await MainActor.run { ToolActivityRecorder() }
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending",
            onToolActivity: { id, name, isActive, sessionKey in
                recorder.record(id: id, name: name, isActive: isActive, sessionKey: sessionKey)
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm)
        let runId = try await waitForLastSentRunId(transport)

        emitToolStart(transport: transport, runId: runId)
        try await waitUntil("tool activity starts") {
            await MainActor.run { recorder.events.count == 1 }
        }

        transport.emit(.chat(NovaChatEventPayload(
            runId: runId,
            sessionKey: "main",
            state: "final",
            message: nil,
            errorMessage: nil)))

        try await waitUntil("tool activity ends") {
            await MainActor.run { recorder.events.count == 2 }
        }
        #expect(await MainActor.run { recorder.events } == [
            ToolActivityEvent(id: "t1", name: "demo", isActive: true, sessionKey: "main"),
            ToolActivityEvent(id: "t1", name: "demo", isActive: false, sessionKey: "main"),
        ])
    }

    @Test func `session switch ends tool activity under its original session`() async throws {
        let recorder = await MainActor.run { ToolActivityRecorder() }
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionKey: "main", sessionId: "sess-main"),
                historyPayload(sessionKey: "other", sessionId: "sess-other"),
            ],
            sendMessageStatus: "pending",
            onToolActivity: { id, name, isActive, sessionKey in
                recorder.record(id: id, name: name, isActive: isActive, sessionKey: sessionKey)
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")
        await sendUserMessage(vm)
        let runId = try await waitForLastSentRunId(transport)

        emitToolStart(transport: transport, runId: runId)
        try await waitUntil("tool activity starts") {
            await MainActor.run { recorder.events.count == 1 }
        }
        await MainActor.run { vm.switchSession(to: "other") }
        try await waitUntil("tool activity ends during session switch") {
            await MainActor.run { recorder.events.count == 2 }
        }

        #expect(await MainActor.run { recorder.events } == [
            ToolActivityEvent(id: "t1", name: "demo", isActive: true, sessionKey: "main"),
            ToolActivityEvent(id: "t1", name: "demo", isActive: false, sessionKey: "main"),
        ])
    }

    @Test func `renders final chat event message when history is stale`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "reply from final event",
                        timestamp: Date().timeIntervalSince1970 * 1000),
                    errorMessage: nil)))

        try await waitUntil("final event message visible") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.contains { message in
                        message.role == "assistant" &&
                            message.content.contains { $0.text == "reply from final event" }
                    }
            }
        }
    }

    @Test func `duplicate final events append one provisional reply`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "hello")
        let runId = try await waitForLastSentRunId(transport)
        let final = NovaChatEventPayload(
            runId: runId,
            sessionKey: "main",
            state: "final",
            message: chatTextMessage(
                role: "assistant",
                text: "one reply",
                timestamp: Date().timeIntervalSince1970 * 1000),
            errorMessage: nil)

        transport.emit(.chat(final))
        transport.emit(.chat(final))
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(await MainActor.run {
            vm.messages.count(where: { message in
                message.role == "assistant" && message.content.first?.text == "one reply"
            }) == 1
        })
    }

    @Test func `provider canonical history adopts provisional final reply`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionId: sessionId)],
            historyResponseHook: { _, index, sentRunIds in
                guard index > 0, let runId = sentRunIds.last else { return nil }
                if index == 1 {
                    return historyPayload(
                        sessionId: sessionId,
                        messages: [
                            chatTextMessage(
                                role: "user",
                                text: "provider-bound request",
                                timestamp: now + 1,
                                idempotencyKey: "\(runId):user"),
                        ],
                        inFlightRun: NovaChatInFlightRun(runId: runId, text: "working"))
                }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "provider-bound request",
                            timestamp: now + 1,
                            idempotencyKey: "\(runId):user"),
                        chatTextMessage(
                            role: "assistant",
                            text: "provider-bound reply",
                            timestamp: now + 2,
                            idempotencyKey: "provider-session:assistant"),
                    ])
            },
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "provider-bound request")
        let runId = try await waitForLastSentRunId(transport)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "provider-bound reply",
                        timestamp: now),
                    errorMessage: nil)))

        try await waitUntil("provider canonical history replaces provisional reply") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: { message in
                        message.role == "assistant" && message.content.first?.text == "provider-bound reply"
                    }) == 1 &&
                    vm.messages.contains(where: { $0.idempotencyKey == "provider-session:assistant" })
            }
        }
    }

    @Test func `incomplete history cannot adopt older identical reply as provisional final`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let olderHistory = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "older request",
                    timestamp: now - 2000,
                    idempotencyKey: "older:user"),
                chatTextMessage(
                    role: "assistant",
                    text: "same reply",
                    timestamp: now - 1000,
                    idempotencyKey: "older:assistant"),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [olderHistory],
            historyResponseHook: { _, index, _ in index > 0 ? olderHistory : nil },
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "current request")
        let runId = try await waitForLastSentRunId(transport)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "same reply",
                        timestamp: now),
                    errorMessage: nil)))

        try await waitUntil("incomplete history retains the current turn and provisional final") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: {
                        $0.role == "assistant" && $0.content.first?.text == "same reply"
                    }) == 2 &&
                    vm.messages.contains(where: {
                        $0.role == "user" && $0.content.first?.text == "current request"
                    })
            }
        }
    }

    @Test func `session message adopts provisional final event reply`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 2 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "dedupe me",
                        timestamp: now + 1,
                        contentId: "live-final-content"),
                    errorMessage: nil)))

        try await waitUntil("provisional final visible once") {
            await MainActor.run {
                vm.messages.count(where: { msg in
                    msg.role == "assistant" && msg.content.first?.text == "dedupe me"
                }) == 1
            }
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(role: "assistant", text: "dedupe me", timestamp: now + 2),
                    messageId: "msg-assistant-final",
                    messageSeq: 2)))

        try await waitUntil("canonical session message adopted final event row") {
            await MainActor.run {
                let matches = vm.messages.filter { msg in
                    msg.role == "assistant" && msg.content.first?.text == "dedupe me"
                }
                return matches.count == 1 && matches.first?.timestamp == now + 2
            }
        }

        await finalRefreshGate.release()
    }

    @Test func `final event does not duplicate canonical assistant session message`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 2 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(role: "assistant", text: "canonical first", timestamp: now + 2),
                    messageId: "msg-assistant-first",
                    messageSeq: 2)))

        try await waitUntil("canonical assistant visible once") {
            await MainActor.run {
                vm.messages.count(where: { msg in
                    msg.role == "assistant" && msg.content.first?.text == "canonical first"
                }) == 1
            }
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(role: "assistant", text: "canonical first", timestamp: now + 1),
                    errorMessage: nil)))

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(await MainActor.run {
            let matches = vm.messages.filter { msg in
                msg.role == "assistant" && msg.content.first?.text == "canonical first"
            }
            return matches.count == 1 && matches.first?.timestamp == now + 2
        })

        await finalRefreshGate.release()
    }

    @Test func `later identical session reply does not adopt prior turn provisional final`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageHook: { runId in
                NovaChatSendResponse(runId: runId, status: "pending")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "first turn")
        try await waitUntil("first pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let firstRunId = try await waitForLastSentRunId(transport)
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: firstRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(role: "assistant", text: "OK", timestamp: now + 1),
                    errorMessage: nil)))

        try await waitUntil("first provisional final visible") {
            await MainActor.run {
                vm.messages.count(where: { msg in
                    msg.role == "assistant" && msg.content.first?.text == "OK"
                }) == 1
            }
        }

        await sendUserMessage(vm, text: "second turn")
        try await waitUntil("second pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(role: "assistant", text: "OK", timestamp: now + 4),
                    messageId: "msg-second-assistant",
                    messageSeq: 4)))

        try await waitUntil("second identical reply appends after second user") {
            await MainActor.run {
                let okReplies = vm.messages.filter { msg in
                    msg.role == "assistant" && msg.content.first?.text == "OK"
                }
                return okReplies.count == 2 && vm.messages.last?.timestamp == now + 4
            }
        }
    }

    @Test func `completion wait refreshes history and clears pending run`() async throws {
        let sessionId = "sess-main"
        let now = (Date().timeIntervalSince1970 * 1000) + 10000
        let history1 = historyPayload(sessionId: sessionId)
        let history2 = historyPayload(sessionId: sessionId, messages: [])
        let history3 = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "completed after wait",
                    timestamp: now + 60000),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2, history3],
            sendMessageStatus: "pending",
            waitForRunCompletionHook: { _, _ in .terminal(.completed) })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("agent wait called") {
            await !(transport.waitCompletionRunIds()).isEmpty
        }

        let runId = try await waitForLastSentRunId(transport)
        #expect(await transport.waitCompletionRunIds() == [runId])
        try await waitUntil("completion wait refresh clears pending run") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.contains { message in
                        message.role == "assistant" &&
                            message.content.contains { $0.text == "completed after wait" }
                    }
            }
        }
    }

    @Test func `terminal wait keeps ownership until history becomes available`() async throws {
        let historyCalls = AsyncCounter()
        let waitCalls = AsyncCounter()
        let sessionId = "sess-main"
        let now = (Date().timeIntervalSince1970 * 1000) + 10000
        let empty = historyPayload(sessionId: sessionId)
        let completed = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "recovered after history failure",
                    timestamp: now + 1),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [empty, empty, empty, completed],
            requestHistoryHook: { _ in
                let count = await historyCalls.increment()
                if count == 3 {
                    throw NSError(domain: "ChatViewModelTests", code: 1)
                }
            },
            sendMessageStatus: "pending",
            waitForRunCompletionHook: { _, _ in
                await waitCalls.increment() == 1 ? .terminal(.completed) : .unavailable
            })
        await MainActor.run {
            vm.pendingRunTerminalRetryMs = 10
            vm.pendingRunRefreshDelaysMs = [60000]
        }
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("terminal observation retries failed history") {
            let waits = await transport.waitCompletionRunIds()
            return await MainActor.run {
                waits.count >= 2 &&
                    vm.pendingRunCount == 0 &&
                    vm.messages.contains { message in
                        message.content.contains { $0.text == "recovered after history failure" }
                    }
            }
        }
        #expect(await MainActor.run { vm.errorText == nil })
    }

    @Test func `terminal wait surfaces a missed lifecycle failure`() async throws {
        let historyCalls = AsyncCounter()
        let sessionId = "sess-main"
        let empty = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [empty, empty, empty],
            requestHistoryHook: { _ in
                if await historyCalls.increment() >= 3 {
                    throw NSError(domain: "ChatViewModelTests", code: 2)
                }
            },
            sendMessageStatus: "pending",
            waitForRunCompletionHook: { _, _ in
                .terminal(.failed(message: "Provider rejected the request"))
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("terminal failure clears pending run") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.errorText == "Provider rejected the request"
            }
        }
        #expect(await !(transport.waitCompletionRunIds()).isEmpty)
    }

    @Test func `terminal wait retires a confirmed no-output completion`() async throws {
        let sessionId = "sess-main"
        let empty = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [empty, empty, empty, empty],
            sendMessageStatus: "pending",
            waitForRunCompletionHook: { _, _ in .terminal(.completed) })
        await MainActor.run {
            vm.pendingRunTerminalRetryMs = 10
            vm.pendingRunTerminalHistoryGraceMs = 10
            vm.pendingRunRefreshDelaysMs = [60000]
        }
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("confirmed no-output completion clears pending run") {
            let waits = await transport.waitCompletionRunIds()
            return await MainActor.run {
                waits.count >= 2 && vm.pendingRunCount == 0 && vm.errorText == nil
            }
        }
    }

    @Test func `agent lifecycle end refreshes history and clears pending run`() async throws {
        let sessionId = "sess-main"
        let now = (Date().timeIntervalSince1970 * 1000) + 10000
        let history1 = historyPayload(sessionId: sessionId)
        let history2 = historyPayload(sessionId: sessionId, messages: [])
        let history3 = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "completed from lifecycle",
                    timestamp: now + 60000),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2, history3],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)

        emitAssistantText(transport: transport, runId: runId, text: "streaming reply")
        emitToolStart(transport: transport, runId: runId)
        emitAgentLifecycleEnd(transport: transport, runId: runId)

        try await waitUntil("lifecycle end refresh clears pending run") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.streamingAssistantText == nil &&
                    vm.pendingToolCalls.isEmpty &&
                    vm.messages.contains { message in
                        message.role == "assistant" &&
                            message.content.contains { $0.text == "completed from lifecycle" }
                    }
            }
        }
    }

    @Test func `plan event parses typed and legacy steps`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "make a plan")
        try await waitUntil("pending run starts") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        let runId = try await waitForLastSentRunId(transport)

        emitPlan(
            transport: transport,
            runId: runId,
            steps: [
                planStep("  Inspect state  ", status: "in_progress"),
                AnyCodable("Write fix"),
                planStep("Verify", status: "completed"),
                planStep("Duplicate active", status: "in_progress"),
                planStep("   ", status: "pending"),
                planStep("Invalid status", status: "blocked"),
                AnyCodable(42),
            ],
            explanation: "  Working through the change  ")

        try await waitUntil("plan snapshot applies") {
            await MainActor.run { vm.planSteps.count == 3 }
        }
        #expect(await MainActor.run { vm.planSteps } == [
            NovaChatPlanStep(step: "Inspect state", status: .inProgress),
            NovaChatPlanStep(step: "Write fix", status: .pending),
            NovaChatPlanStep(step: "Verify", status: .completed),
        ])
        #expect(await MainActor.run { vm.planExplanation } == "Working through the change")
    }

    @Test func `plan snapshots replace and empty snapshot clears`() async throws {
        let history = historyPayload()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        await sendUserMessage(vm, text: "replace plan")
        try await waitUntil("pending run starts") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        let runId = try await waitForLastSentRunId(transport)
        emitPlan(
            transport: transport,
            runId: runId,
            steps: [
                planStep("First", status: "completed"),
                planStep("Second", status: "in_progress"),
            ],
            explanation: "Initial")
        try await waitUntil("first plan snapshot applies") {
            await MainActor.run { vm.planSteps.count == 2 }
        }

        emitPlan(
            transport: transport,
            runId: runId,
            steps: [planStep("Replacement", status: "pending")],
            seq: 3)
        try await waitUntil("replacement plan snapshot applies") {
            await MainActor.run {
                vm.planSteps == [NovaChatPlanStep(step: "Replacement", status: .pending)] &&
                    vm.planExplanation == nil
            }
        }

        emitPlan(
            transport: transport,
            runId: runId,
            steps: [],
            explanation: "Explanation only",
            seq: 4)
        try await waitUntil("empty plan snapshot clears") {
            await MainActor.run { vm.planSteps.isEmpty && vm.planExplanation == nil }
        }
    }

    @Test func `agent lifecycle end clears plan`() async throws {
        let history = historyPayload()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        await sendUserMessage(vm, text: "finish plan")
        try await waitUntil("pending run starts") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        let runId = try await waitForLastSentRunId(transport)
        emitPlan(
            transport: transport,
            runId: runId,
            steps: [planStep("Finish", status: "in_progress")])
        try await waitUntil("plan snapshot applies") {
            await MainActor.run { !vm.planSteps.isEmpty }
        }

        emitAgentLifecycleEnd(transport: transport, runId: runId, seq: 3)

        try await waitUntil("lifecycle end clears plan") {
            await MainActor.run {
                vm.pendingRunCount == 0 && vm.planSteps.isEmpty && vm.planExplanation == nil
            }
        }
    }

    @Test func `plan event for wrong run is ignored`() async throws {
        let history = historyPayload()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        await sendUserMessage(vm, text: "ignore wrong plan")
        try await waitUntil("pending run starts") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        emitPlan(
            transport: transport,
            runId: "other-run",
            steps: [planStep("Wrong run", status: "in_progress")])

        try await Task.sleep(for: .milliseconds(50))
        #expect(await MainActor.run { vm.planSteps.isEmpty })
        #expect(await MainActor.run { vm.planExplanation == nil })
    }

    @Test func `terminal event for another run preserves active plan`() async throws {
        let activeRunId = "active-run"
        let initialHistory = historyPayload()
        let activeHistory = historyPayload(
            inFlightRun: NovaChatInFlightRun(
                runId: activeRunId,
                text: "",
                plan: NovaChatPlanSnapshot(
                    steps: [NovaChatPlanStep(step: "Keep working", status: .inProgress)])))
        let (transport, vm) = await makeViewModel(
            historyResponses: [initialHistory, activeHistory, activeHistory],
            sendMessageHook: { _ in
                NovaChatSendResponse(runId: activeRunId, status: "pending")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        await sendUserMessage(vm, text: "keep active plan")
        try await waitUntil("remote run is adopted") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        emitPlan(
            transport: transport,
            runId: activeRunId,
            steps: [planStep("Keep working", status: "in_progress")])
        try await waitUntil("active plan applies") {
            await MainActor.run { vm.planSteps.first?.step == "Keep working" }
        }

        emitExternalFinal(transport: transport, runId: "older-run")

        try await Task.sleep(for: .milliseconds(100))
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.planSteps } == [
            NovaChatPlanStep(step: "Keep working", status: .inProgress),
        ])
    }

    @Test func `pending run blocks second main send`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId, messages: [])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "first")
        try await waitUntil("first send becomes pending") {
            await MainActor.run { vm.pendingRunCount == 1 && !vm.isSending }
        }
        let firstRunIds = await transport.sentRunIds()
        #expect(firstRunIds.count == 1)
        #expect(await MainActor.run { !vm.canSend })

        await MainActor.run {
            vm.input = "second"
            vm.send()
        }
        try await Task.sleep(for: .milliseconds(50))

        #expect(await transport.sentRunIds() == firstRunIds)
        #expect(await MainActor.run { vm.pendingRunCount } == 1)
        #expect(await MainActor.run { vm.input } == "second")
    }

    @Test func `terminal ok send ack clears pending run without waiting for completion`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId, messages: [])
        let (transport, vm) = await makeViewModel(historyResponses: [history, history])
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "cached")
        try await waitUntil("terminal ok ack clears pending run") {
            await MainActor.run { vm.pendingRunCount == 0 && !vm.isSending }
        }

        #expect(await MainActor.run { vm.errorText } == nil)
        #expect(await transport.waitCompletionRunIds().isEmpty)
        #expect(await MainActor.run { vm.messages.containsUserText("cached") })
    }

    @Test func `rekeys optimistic user message when gateway reuses active run`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionId: sessionId)],
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "same active request",
                            timestamp: now + 5000,
                            idempotencyKey: "\(remoteRunId):user"),
                    ])
            },
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }
        await responseGate.open()

        try await waitUntil("reused run adopts one canonical user row") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" }) == 1 &&
                    vm.messages.contains(where: { message in
                        message.id == optimisticID &&
                            message.timestamp == now + 5000 &&
                            message.idempotencyKey == "\(remoteRunId):user"
                    })
            }
        }
    }

    @Test func `reused run preserves canonical event received before acknowledgement`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionId: sessionId),
                historyPayload(sessionId: sessionId, messages: []),
            ],
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }
        let canonicalTimestamp = now + 5000
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "canonical active request",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: canonicalTimestamp,
                        idempotencyKey: "\(remoteRunId):user"),
                    messageId: "srv-reused-run-user",
                    messageSeq: 1)))
        try await waitUntil("canonical event arrives before send acknowledgement") {
            await MainActor.run { vm.messages.count(where: { $0.role == "user" }) == 2 }
        }
        await responseGate.open()

        try await waitUntil("reused run preserves canonical event data") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" }) == 1 &&
                    vm.messages.contains(where: { message in
                        message.id == optimisticID &&
                            message.content.first?.text == "canonical active request" &&
                            message.timestamp == canonicalTimestamp &&
                            message.idempotencyKey == "\(remoteRunId):user"
                    })
            }
        }
    }

    @Test func `reused run final stays scoped to surviving canonical user turn`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let activeUser = chatTextMessage(
            role: "user",
            text: "same active request",
            timestamp: now + 1,
            idempotencyKey: "\(remoteRunId):user")
        let activeReply = chatTextMessage(
            role: "assistant",
            text: "active reply",
            timestamp: now + 2,
            idempotencyKey: remoteRunId)
        let newerUser = chatTextMessage(
            role: "user",
            text: "newer request from another client",
            timestamp: now + 3,
            idempotencyKey: "other-client-run:user")
        let initialHistory = historyPayload(sessionId: sessionId, messages: [activeUser])
        let canonicalHistory = historyPayload(
            sessionId: sessionId,
            messages: [activeUser, activeReply, newerUser])
        let responseGate = AsyncGate()
        let (transport, vm) = await makeViewModel(
            historyResponses: [initialHistory, canonicalHistory, canonicalHistory],
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "active reply",
                        timestamp: now + 2,
                        idempotencyKey: remoteRunId),
                    messageId: "srv-active-reply",
                    messageSeq: 2)))
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "user",
                        text: "newer request from another client",
                        timestamp: now + 3,
                        idempotencyKey: "other-client-run:user"),
                    messageId: "srv-newer-user",
                    messageSeq: 3)))
        try await waitUntil("newer user arrives before reused-run acknowledgement") {
            await MainActor.run { vm.messages.containsUserText("newer request from another client") }
        }
        await responseGate.open()
        try await waitUntil("reused run collapses onto earlier canonical user") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" && $0.content.first?.text == "same active request" }) == 1
            }
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: activeReply,
                    errorMessage: nil)))

        try await waitUntil("reused final does not duplicate earlier canonical reply") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages
                    .count(where: { $0.role == "assistant" && $0.content.first?.text == "active reply" }) == 1
            }
        }
    }

    @Test func `newer identical reply does not suppress reused run final`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let history = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same active request",
                    timestamp: now - 3000,
                    idempotencyKey: "\(remoteRunId):user"),
                chatTextMessage(
                    role: "user",
                    text: "newer request from another client",
                    timestamp: now - 2000,
                    idempotencyKey: "other-client-run:user"),
                chatTextMessage(
                    role: "assistant",
                    text: "OK",
                    timestamp: now - 1000),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 3 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        try await waitUntil("duplicate request is optimistic") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" && $0.content.first?.text == "same active request" }) == 2
            }
        }
        await responseGate.open()
        try await waitUntil("duplicate request collapses onto older active user") {
            guard await historyCount.current() >= 2 else { return false }
            return await MainActor.run {
                vm.messages.count(where: {
                    $0.role == "user" && $0.content.first?.text == "same active request"
                }) == 1
            }
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "OK",
                        timestamp: now + 4,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))

        try await waitUntil("reused final remains distinct from newer turn reply") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: { $0.role == "assistant" && $0.content.first?.text == "OK" }) == 2
            }
        }
        await finalRefreshGate.release()
    }

    @Test func `correlated reply after metadata free steering suppresses reused final duplicate`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let history = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same active request",
                    timestamp: now - 3000,
                    idempotencyKey: "\(remoteRunId):user"),
                chatTextMessage(
                    role: "user",
                    text: "steer the active run",
                    timestamp: now - 2000),
                chatTextMessage(
                    role: "assistant",
                    text: "steered reply",
                    timestamp: now - 1000,
                    idempotencyKey: remoteRunId),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        try await waitUntil("steered duplicate request is optimistic") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" && $0.content.first?.text == "same active request" }) == 2
            }
        }
        await responseGate.open()
        try await waitUntil("steered duplicate request collapses onto active user") {
            await MainActor.run {
                vm.messages.count(where: {
                    $0.role == "user" && $0.content.first?.text == "same active request"
                }) == 1
            }
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "steered reply",
                        timestamp: now + 1,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))

        try await waitUntil("steering row remains inside reused run scope") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: {
                        $0.role == "assistant" && $0.content.first?.text == "steered reply"
                    }) == 1
            }
        }
    }

    @Test func `canonical projected reply after steering adopts reused provisional final`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let history = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same active request",
                    timestamp: now - 1000,
                    idempotencyKey: "\(remoteRunId):user"),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 3 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageHook: { _ in
                NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        try await waitUntil("steering adoption send refresh completes") {
            await historyCount.current() >= 2
        }
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "steered reply",
                        timestamp: now + 1,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))
        try await waitUntil("provisional reply precedes steering row") {
            await MainActor.run {
                vm.messages.contains { $0.role == "assistant" && $0.content.first?.text == "steered reply" }
            }
        }
        let provisionalID = try await MainActor.run {
            try #require(vm.messages.first(where: {
                $0.role == "assistant" && $0.content.first?.text == "steered reply"
            })?.id)
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "user",
                        text: "steer the active run",
                        timestamp: now + 2),
                    messageId: "srv-steering-user",
                    messageSeq: 2)))
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "canonical steered reply",
                        timestamp: now + 3,
                        idempotencyKey: remoteRunId),
                    messageId: "srv-steered-reply",
                    messageSeq: 3)))

        try await waitUntil("canonical reply after steering adopts provisional row") {
            await MainActor.run {
                guard vm.messages.count(where: { $0.role == "assistant" }) == 1,
                      let reply = vm.messages.first(where: { $0.id == provisionalID }),
                      reply.content.first?.text == "canonical steered reply",
                      reply.timestamp == now + 3,
                      let steeringIndex = vm.messages.firstIndex(where: {
                          $0.role == "user" && $0.content.first?.text == "steer the active run"
                      }),
                      let replyIndex = vm.messages.firstIndex(where: { $0.id == provisionalID })
                else {
                    return false
                }
                return steeringIndex < replyIndex
            }
        }
        await finalRefreshGate.release()
    }

    @Test func `metadata free channel turn does not adopt reused provisional final`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let history = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same active request",
                    timestamp: now - 1000,
                    idempotencyKey: "\(remoteRunId):user"),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 3 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageHook: { _ in
                NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        try await waitUntil("channel boundary send refresh completes") {
            await historyCount.current() >= 2
        }
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "same reply",
                        timestamp: now + 1,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))
        try await waitUntil("reused provisional reply is visible") {
            await MainActor.run {
                vm.messages.contains { $0.role == "assistant" && $0.content.first?.text == "same reply" }
            }
        }
        let provisionalID = try await MainActor.run {
            try #require(vm.messages.first(where: {
                $0.role == "assistant" && $0.content.first?.text == "same reply"
            })?.id)
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "user",
                        text: "independent channel request",
                        timestamp: now + 2),
                    messageId: "srv-channel-user",
                    messageSeq: 2)))
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "same reply",
                        timestamp: now + 3),
                    messageId: "srv-channel-reply",
                    messageSeq: 3)))

        try await waitUntil("independent channel reply remains distinct") {
            await MainActor.run {
                let replies = vm.messages.filter {
                    $0.role == "assistant" && $0.content.first?.text == "same reply"
                }
                guard replies.count == 2, replies.first?.id == provisionalID else { return false }
                guard let userIndex = vm.messages.firstIndex(where: {
                    $0.role == "user" && $0.content.first?.text == "independent channel request"
                }),
                    let canonicalIndex = vm.messages.firstIndex(where: { $0.id == replies[1].id })
                else {
                    return false
                }
                return userIndex < canonicalIndex
            }
        }
        await finalRefreshGate.release()
    }

    @Test func `late transformed canonical user keeps reused run final scope`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let finalRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let emptyHistory = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [emptyHistory, emptyHistory],
            requestHistoryHook: { _ in
                let count = await historyCount.increment()
                if count == 3 {
                    await finalRefreshGate.wait()
                }
            },
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        await responseGate.open()
        try await waitUntil("optimistic user adopts reused run identity") {
            await MainActor.run {
                vm.messages.contains(where: { message in
                    message.role == "user" && message.idempotencyKey == "\(remoteRunId):user"
                })
            }
        }
        try await waitUntil("post-ack history refresh completes") {
            await historyCount.current() >= 2
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "user",
                        text: "canonical redacted request",
                        timestamp: now + 1,
                        idempotencyKey: "\(remoteRunId):user"),
                    messageId: "srv-transformed-user",
                    messageSeq: 1)))
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "active reply",
                        timestamp: now + 2,
                        idempotencyKey: remoteRunId),
                    messageId: "srv-active-reply",
                    messageSeq: 2)))
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "user",
                        text: "newer request from another client",
                        timestamp: now + 3,
                        idempotencyKey: "other-client-run:user"),
                    messageId: "srv-newer-user",
                    messageSeq: 3)))
        try await waitUntil("canonical user transformation and newer turn arrive") {
            await MainActor.run {
                vm.messages.containsUserText("canonical redacted request") &&
                    vm.messages.containsUserText("newer request from another client")
            }
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "active reply",
                        timestamp: now + 4,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))

        try await waitUntil("late canonical adoption does not duplicate reused final") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages
                    .count(where: { $0.role == "assistant" && $0.content.first?.text == "active reply" }) == 1
            }
        }
        await finalRefreshGate.release()
    }

    @Test func `history reconciled early final stays in canonical order after delayed event`() async throws {
        let sessionId = "sess-main"
        let remoteRunId = "existing-active-run"
        let now = Date().timeIntervalSince1970 * 1000
        let responseGate = AsyncGate()
        let historyGate = AsyncGate()
        let emptyHistory = historyPayload(sessionId: sessionId)
        let canonicalHistory = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "user",
                    text: "same active request",
                    timestamp: now,
                    idempotencyKey: "\(remoteRunId):user"),
                chatTextMessage(
                    role: "assistant",
                    text: "early final reply",
                    timestamp: now + 2,
                    idempotencyKey: remoteRunId),
                chatTextMessage(
                    role: "user",
                    text: "newer channel request",
                    timestamp: now + 3),
            ])
        let (transport, vm) = await makeViewModel(
            historyResponses: [emptyHistory, canonicalHistory],
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                await historyGate.wait()
                return canonicalHistory
            },
            sendMessageHook: { _ in
                await responseGate.wait()
                return NovaChatSendResponse(runId: remoteRunId, status: "in_flight")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "same active request")
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: remoteRunId,
                    sessionKey: "main",
                    state: "final",
                    message: chatTextMessage(
                        role: "assistant",
                        text: "early final reply",
                        timestamp: now + 1,
                        idempotencyKey: remoteRunId),
                    errorMessage: nil)))
        try await waitUntil("early final is visible before acknowledgement") {
            await MainActor.run {
                vm.messages.contains {
                    $0.role == "assistant" && $0.content.first?.text == "early final reply"
                }
            }
        }
        let provisionalID = try await MainActor.run {
            try #require(vm.messages.first(where: {
                $0.role == "assistant" && $0.content.first?.text == "early final reply"
            })?.id)
        }

        await historyGate.open()
        try await waitUntil("history adopts early final before newer user") {
            await MainActor.run {
                guard let replyIndex = vm.messages.firstIndex(where: { $0.id == provisionalID }),
                      let newerUserIndex = vm.messages.firstIndex(where: {
                          $0.role == "user" && $0.content.first?.text == "newer channel request"
                      })
                else {
                    return false
                }
                return replyIndex < newerUserIndex && vm.messages[replyIndex].timestamp == now + 2
            }
        }

        await responseGate.open()
        try await waitUntil("early final run acknowledgement rekeys optimistic user") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: {
                        $0.role == "user" && $0.idempotencyKey == "\(remoteRunId):user"
                    }) == 1
            }
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: chatTextModelMessage(
                        role: "assistant",
                        text: "early final reply",
                        timestamp: now + 4,
                        idempotencyKey: remoteRunId),
                    messageId: "srv-early-final-reply",
                    messageSeq: 2)))

        try await waitUntil("delayed canonical event preserves history order") {
            await MainActor.run {
                guard vm.messages.count(where: {
                    $0.role == "assistant" && $0.idempotencyKey == remoteRunId
                }) == 1,
                    let replyIndex = vm.messages.firstIndex(where: { $0.id == provisionalID }),
                    let newerUserIndex = vm.messages.firstIndex(where: {
                        $0.role == "user" && $0.content.first?.text == "newer channel request"
                    })
                else {
                    return false
                }
                return replyIndex < newerUserIndex && vm.messages[replyIndex].timestamp == now + 2
            }
        }
    }

    @Test func `terminal timeout send ack surfaces error and allows next send`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId, messages: [])
        let sendCount = AsyncCounter()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sendMessageHook: { runId in
                let count = await sendCount.increment()
                return NovaChatSendResponse(
                    runId: runId,
                    status: count == 1 ? "timeout" : "ok")
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        await sendUserMessage(vm, text: "first")
        try await waitUntil("timeout ack clears pending run") {
            await MainActor.run { vm.pendingRunCount == 0 && !vm.isSending }
        }
        #expect(await transport.sentRunIds().count == 1)
        #expect(await MainActor.run { vm.errorText } == "Chat failed before the run started; try again.")
        #expect(await MainActor.run { !vm.messages.containsUserText("first") })

        await sendUserMessage(vm, text: "second")
        try await waitUntil("second send is accepted after timeout ack") {
            await transport.sentRunIds().count == 2
        }
    }

    @Test func `keeps optimistic user message when final refresh returns only assistant history`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload(sessionId: sessionId)
        let history2 = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "final answer",
                    timestamp: now + 1),
            ])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        try await sendMessageAndEmitFinal(
            transport: transport,
            vm: vm,
            text: "hello from mac webchat")

        try await waitUntil("assistant history refreshes without dropping user message") {
            await MainActor.run {
                let texts = vm.messages.map { message in
                    (message.role, message.content.compactMap(\.text).joined(separator: "\n"))
                }
                return texts.contains(where: { $0.0 == "assistant" && $0.1 == "final answer" }) &&
                    texts.contains(where: { $0.0 == "user" && $0.1 == "hello from mac webchat" })
            }
        }
    }

    @Test func `keeps optimistic user message when final refresh history is temporarily empty`() async throws {
        let sessionId = "sess-main"
        let history1 = historyPayload(sessionId: sessionId)
        let history2 = historyPayload(sessionId: sessionId, messages: [])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        try await sendMessageAndEmitFinal(
            transport: transport,
            vm: vm,
            text: "hello from mac webchat")

        try await waitUntil("empty refresh does not clear optimistic user message") {
            await MainActor.run {
                vm.messages.contains { message in
                    message.role == "user" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "hello from mac webchat"
                }
            }
        }
    }

    @Test func `does not duplicate user message when refresh returns canonical timestamp`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let refreshGate = AsyncGate()
        let historyCallCount = AsyncCounter()
        let history1 = historyPayload(
            sessionId: sessionId,
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "earlier answer",
                    timestamp: now + 1000),
            ])
        let (_, vm) = await makeViewModel(
            historyResponses: [history1],
            requestHistoryHook: { _ in
                if await historyCallCount.increment() == 2 {
                    await refreshGate.wait()
                }
            },
            historyResponseHook: { _, index, sentRunIds in
                guard index == 1, let runId = sentRunIds.last else { return nil }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "assistant",
                            text: "earlier answer",
                            timestamp: now + 1000),
                        chatTextMessage(
                            role: "user",
                            text: "hello from mac webchat",
                            timestamp: now + 5000,
                            idempotencyKey: "\(runId):user"),
                        chatTextMessage(
                            role: "assistant",
                            text: "final answer",
                            timestamp: now + 6000),
                    ])
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "hello from mac webchat")
        try await waitUntil("canonical refresh starts") { await historyCallCount.current() == 2 }
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }
        await refreshGate.open()

        try await waitUntil("send acknowledgement refresh keeps one user message") {
            await MainActor.run {
                let userMessages = vm.messages.filter { message in
                    message.role == "user" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "hello from mac webchat"
                }
                let hasAssistant = vm.messages.contains { message in
                    message.role == "assistant" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "final answer"
                }
                return hasAssistant && userMessages.count == 1
            }
        }
        #expect(await MainActor.run { vm.messages.last(where: { $0.role == "user" })?.id } == optimisticID)
    }

    @Test func `metadata free canonical refresh keeps ambiguous user turns distinct`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let refreshGate = AsyncGate()
        let historyCallCount = AsyncCounter()
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionId: sessionId)],
            requestHistoryHook: { _ in
                if await historyCallCount.increment() == 2 {
                    await refreshGate.wait()
                }
            },
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "legacy echo",
                            timestamp: now + 5000),
                        chatTextMessage(
                            role: "assistant",
                            text: "legacy answer",
                            timestamp: now + 6000),
                    ])
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "legacy echo")
        try await waitUntil("legacy refresh starts") { await historyCallCount.current() == 2 }
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }
        await refreshGate.open()

        try await waitUntil("metadata free canonical refresh preserves both user rows") {
            await MainActor.run {
                vm.messages.count(where: { message in
                    message.role == "user" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "legacy echo"
                }) == 2 && vm.messages.contains(where: { message in
                    message.role == "assistant" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "legacy answer"
                })
            }
        }
        #expect(await MainActor.run { vm.messages.contains(where: { $0.id == optimisticID }) })
    }

    @Test func `preserves local echo when another client sends identical text during refresh`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(sessionId: sessionId)],
            historyResponseHook: { _, index, _ in
                guard index == 1 else { return nil }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "same words",
                            timestamp: now + 5000,
                            idempotencyKey: "other-client:user"),
                        chatTextMessage(
                            role: "assistant",
                            text: "other client's answer",
                            timestamp: now + 6000),
                    ])
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        await sendUserMessage(vm, text: "same words")

        try await waitUntil("foreign identical turn and local echo both survive") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.count(where: { message in
                        message.role == "user" &&
                            message.content.compactMap(\.text).joined(separator: "\n") == "same words"
                    }) == 2
            }
        }
        #expect(await transport.sentRunIds().count == 1)
    }

    @Test func `preserves repeated optimistic user messages with identical content during refresh`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(
            historyResponses: [history1],
            historyResponseHook: { _, index, sentRunIds in
                guard index > 0, let firstRunId = sentRunIds.first else { return nil }
                return historyPayload(
                    sessionId: sessionId,
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "retry",
                            timestamp: now + 5000,
                            idempotencyKey: "\(firstRunId):user"),
                        chatTextMessage(
                            role: "assistant",
                            text: "first answer",
                            timestamp: now + 6000),
                    ])
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        try await sendMessageAndEmitFinal(
            transport: transport,
            vm: vm,
            text: "retry")
        try await waitUntil("first retry completes") {
            await MainActor.run {
                vm.pendingRunCount == 0 &&
                    vm.messages.contains { message in
                        message.role == "assistant" &&
                            message.content.compactMap(\.text).joined(separator: "\n") == "first answer"
                    }
            }
        }
        try await sendMessageAndEmitFinal(
            transport: transport,
            vm: vm,
            text: "retry")

        try await waitUntil("repeated optimistic user message is preserved") {
            await MainActor.run {
                let retryMessages = vm.messages.filter { message in
                    message.role == "user" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "retry"
                }
                let hasAssistant = vm.messages.contains { message in
                    message.role == "assistant" &&
                        message.content.compactMap(\.text).joined(separator: "\n") == "first answer"
                }
                return hasAssistant && retryMessages.count == 2
            }
        }
    }

    @Test func `run refresh does not resurrect old user turns omitted by bounded history`() async throws {
        let sessionId = "sess-main"
        let now = Date().timeIntervalSince1970 * 1000
        let oldMessages = [
            chatTextMessage(role: "user", text: "old question", timestamp: now - 2000),
            chatTextMessage(role: "assistant", text: "old answer", timestamp: now - 1000),
        ]
        let boundedRefreshMessages = [
            chatTextMessage(role: "user", text: "current question", timestamp: now + 5000),
            chatTextMessage(role: "assistant", text: "current answer", timestamp: now + 6000),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionId: sessionId, messages: oldMessages),
                historyPayload(sessionId: sessionId, messages: boundedRefreshMessages),
            ])
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)
        try await sendMessageAndEmitFinal(
            transport: transport,
            vm: vm,
            text: "current question")

        try await waitUntil("bounded refresh replaces old history") {
            await MainActor.run {
                let texts = vm.messages.map { message in
                    message.content.compactMap(\.text).joined(separator: "\n")
                }
                return texts.contains("current answer") &&
                    !texts.contains("old question") &&
                    !texts.contains("old answer")
            }
        }
    }

    @Test @MainActor func `bounded repeated same text reply invalidates older stale refresh`() async throws {
        let sessionId = "sess-main"
        let staleRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let staleRefreshReleasedCount = AsyncCounter()
        let now = (Date().timeIntervalSince1970 * 1000) + 10000
        let firstTurn = [
            chatTextMessage(role: "user", text: "retry", timestamp: now),
            chatTextMessage(role: "assistant", text: "first answer", timestamp: now + 1),
        ]
        let latestBoundedTurn = [
            chatTextMessage(role: "user", text: "retry", timestamp: now + 2),
            chatTextMessage(role: "assistant", text: "second answer", timestamp: now + 3),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionId: sessionId, messages: firstTurn),
                historyPayload(sessionId: sessionId, messages: firstTurn),
                historyPayload(sessionId: sessionId, messages: latestBoundedTurn),
            ],
            requestHistoryHook: { sessionKey in
                guard sessionKey == "main" else { return }
                let count = await historyCount.increment()
                if count == 2 {
                    await staleRefreshGate.wait()
                    _ = await staleRefreshReleasedCount.increment()
                }
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        transport.emit(NovaChatTransportEvent.seqGap)
        try await waitUntil("stale refresh is in flight") {
            await historyCount.current() == 2
        }

        vm.input = "retry"
        vm.send()
        _ = try await waitForLastSentRunId(transport)
        try await waitUntil("bounded second answer applies") {
            await MainActor.run {
                vm.sessionId == sessionId &&
                    vm.messages.contains { message in
                        message.content.contains { $0.text == "second answer" }
                    }
            }
        }

        await staleRefreshGate.release()
        try await waitUntil("stale refresh resumes") {
            await staleRefreshReleasedCount.current() == 1
        }

        #expect(await MainActor.run {
            vm.messages.contains { message in
                message.content.contains { $0.text == "second answer" }
            }
        })
    }

    @Test @MainActor func `transformed canonical reply invalidates older stale refresh`() async throws {
        let staleRefreshGate = SessionSubscribeGate()
        let historyCount = AsyncCounter()
        let now = Date().timeIntervalSince1970 * 1000
        let staleTurn = [
            chatTextMessage(role: "user", text: "older question", timestamp: now - 2),
            chatTextMessage(role: "assistant", text: "older answer", timestamp: now - 1),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionId: "sess-bootstrap", messages: staleTurn),
                historyPayload(sessionId: "sess-stale", messages: staleTurn),
            ],
            requestHistoryHook: { sessionKey in
                guard sessionKey == "main" else { return }
                let count = await historyCount.increment()
                if count == 2 {
                    await staleRefreshGate.wait()
                }
            },
            historyResponseHook: { _, index, sentRunIds in
                guard index == 2, let runId = sentRunIds.first else { return nil }
                return historyPayload(
                    sessionId: "sess-canonical",
                    messages: [
                        chatTextMessage(
                            role: "user",
                            text: "canonical redacted request",
                            timestamp: now,
                            idempotencyKey: "\(runId):user"),
                        chatTextMessage(
                            role: "assistant",
                            text: "canonical answer",
                            timestamp: now + 1,
                            idempotencyKey: runId),
                    ])
            })
        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-bootstrap")

        transport.emit(NovaChatTransportEvent.seqGap)
        try await waitUntil("stale transformed refresh is in flight") {
            await historyCount.current() == 2
        }

        vm.input = "original request"
        vm.send()
        _ = try await waitForLastSentRunId(transport)
        try await waitUntil("transformed canonical answer applies") {
            await MainActor.run {
                vm.sessionId == "sess-canonical" &&
                    vm.messages.containsUserText("canonical redacted request") &&
                    vm.messages.contains { $0.content.contains { $0.text == "canonical answer" } }
            }
        }

        let healthCallsBeforeRelease = await transport.healthCallCount()
        await staleRefreshGate.release()
        try await waitUntil("older transformed refresh completes") {
            await transport.healthCallCount() > healthCallsBeforeRelease
        }

        #expect(vm.sessionId == "sess-canonical")
        #expect(vm.messages.containsUserText("canonical redacted request"))
        #expect(vm.messages.contains { $0.content.contains { $0.text == "canonical answer" } })
    }

    @Test func `accepts canonical session key events for own pending run`() async throws {
        let history1 = historyPayload()
        let history2 = historyPayload(
            messages: [
                chatTextMessage(
                    role: "assistant",
                    text: "from history",
                    timestamp: Date().timeIntervalSince1970 * 1000),
            ])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm)
        await sendUserMessage(vm)
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }

        let runId = try await waitForLastSentRunId(transport)
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "agent:main:main",
                    state: "final",
                    message: nil,
                    errorMessage: nil)))

        try await waitUntil("pending run clears") { await MainActor.run { vm.pendingRunCount == 0 } }
        try await waitUntil("history refresh") {
            await MainActor.run { vm.messages.contains(where: { $0.role == "assistant" }) }
        }
    }

    @Test func `surfaces assistant error message after own run refresh`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload()
        let history2 = historyPayload(
            messages: [
                chatErrorMessage(
                    role: "assistant",
                    errorMessage: "You have hit your ChatGPT usage limit (plus plan). Try again in ~28 min.",
                    timestamp: now),
            ])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm)
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }

        let runId = try await waitForLastSentRunId(transport)
        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "error",
                    message: nil,
                    errorMessage: "You have hit your ChatGPT usage limit (plus plan). Try again in ~28 min.")))

        try await waitUntil("pending run clears after error") {
            await MainActor.run { vm.pendingRunCount == 0 }
        }
        try await waitUntil("history refresh shows assistant error message") {
            await MainActor.run {
                vm.messages.contains(where: { message in
                    message.role == "assistant" &&
                        NovaChatMessage.displayText(
                            contentText: message.content.compactMap(\.text).joined(separator: "\n"),
                            role: message.role,
                            stopReason: message.stopReason,
                            errorMessage: message.errorMessage)
                        .contains("You have hit your ChatGPT usage limit")
                })
            }
        }
    }

    @Test func `accepts canonical session key events for external runs`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload(messages: [chatTextMessage(role: "user", text: "first", timestamp: now)])
        let history2 = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "first", timestamp: now),
                chatTextMessage(role: "assistant", text: "from external run", timestamp: now + 1),
            ])

        let (transport, vm) = await makeViewModel(historyResponses: [history1, history2])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.count == 1 } }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: "external-run",
                    sessionKey: "agent:main:main",
                    state: "final",
                    message: nil,
                    errorMessage: nil)))

        try await waitUntil("history refresh after canonical external event") {
            await MainActor.run { vm.messages.count == 2 }
        }
    }

    @Test func `appends external session user message for active session`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            sessionKey: "agent:aiden:main",
            historyResponses: [historyPayload(sessionKey: "agent:aiden:main")])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:aiden:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "spoken transcript",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now),
                    messageId: "msg-1",
                    messageSeq: 1)))

        try await waitUntil("external transcript visible") {
            await MainActor.run {
                vm.messages.count == 1 &&
                    vm.messages.first?.role == "user" &&
                    vm.messages.first?.content.first?.text == "spoken transcript"
            }
        }
    }

    @Test func `appends global session user message for selected agent`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            sessionKey: "agent:work:global",
            historyResponses: [historyPayload(sessionKey: "agent:work:global")])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "global",
                    agentId: "work",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "global transcript",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now),
                    messageId: "msg-global-work",
                    messageSeq: 1)))

        try await waitUntil("selected agent global transcript visible") {
            await MainActor.run {
                vm.messages.count == 1 &&
                    vm.messages.first?.role == "user" &&
                    vm.messages.first?.content.first?.text == "global transcript"
            }
        }
    }

    @Test func `ignores global session user message for different agent`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            sessionKey: "agent:work:global",
            historyResponses: [historyPayload(sessionKey: "agent:work:global")])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "global",
                    agentId: "main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "wrong global transcript",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now),
                    messageId: "msg-global-main",
                    messageSeq: 1)))

        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await MainActor.run { vm.messages.isEmpty })
    }

    @Test func `exact ordinary session matches before agent bootstrap`() async {
        let matches = await MainActor.run {
            (
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "main",
                    agentId: "work",
                    current: "main",
                    mainSessionKey: "main"),
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "main",
                    agentId: "work",
                    current: "main",
                    mainSessionKey: "main",
                    activeAgentId: "main"))
        }
        #expect(matches.0)
        #expect(!matches.1)
    }

    @Test func `agent scoped opaque event matches only its presentation owner`() async {
        let matches = await MainActor.run {
            (
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "agent:reviewer:Matrix:Channel:!MixedRoom:example.org",
                    current: "Matrix:Channel:!MixedRoom:example.org",
                    mainSessionKey: "main",
                    activeAgentId: "reviewer"),
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "agent:reviewer:Matrix:Channel:!MixedRoom:example.org",
                    agentId: "work",
                    current: "Matrix:Channel:!MixedRoom:example.org",
                    mainSessionKey: "main",
                    activeAgentId: "reviewer"),
                NovaChatViewModel.matchesCurrentSessionKey(
                    incoming: "agent:reviewer:Matrix:Channel:!MixedRoom:example.org",
                    current: "Matrix:Channel:!MixedRoom:example.org",
                    mainSessionKey: "main",
                    activeAgentId: "work"))
        }

        #expect(matches.0)
        #expect(!matches.1)
        #expect(!matches.2)
    }

    @Test func `ignores agent main session message for different current main alias`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(historyResponses: [historyPayload()])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:sentinel:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "wrong agent transcript",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now),
                    messageId: "msg-other-agent",
                    messageSeq: 1)))

        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await MainActor.run { vm.messages.isEmpty })
    }

    @Test func `appends external session assistant message while run pending`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sendMessageStatus: "pending")

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        await sendUserMessage(vm, text: "ping")
        try await waitUntil("local run pending") { await MainActor.run { vm.pendingRunCount == 1 } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "assistant",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "agent reply",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now + 1),
                    messageId: "msg-assistant-1",
                    messageSeq: 2)))

        try await waitUntil("assistant transcript visible while pending") {
            await MainActor.run {
                vm.messages.contains(where: { msg in
                    msg.role == "assistant" &&
                        msg.content.first?.text == "agent reply"
                })
            }
        }
    }

    @Test func `dedupes gateway echo of local user message`() async throws {
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sendMessageHook: { runId in
                NovaChatSendResponse(runId: runId, status: "pending")
            })

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        await sendUserMessage(vm, text: "echo me")
        let runId = try await waitForLastSentRunId(transport)
        try await waitUntil("optimistic user message visible") {
            await MainActor.run {
                vm.messages.count == 1 && vm.messages.first?.content.first?.text == "echo me"
            }
        }

        // Gateway echoes the same user turn over the session-message stream with a
        // server-assigned timestamp that differs from the optimistic local one.
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "echo me",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: Date().timeIntervalSince1970 * 1000 + 5000,
                        idempotencyKey: "\(runId):user"),
                    messageId: "srv-echo-1",
                    messageSeq: 1)))

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(await MainActor.run {
            vm.messages.count(where: { msg in
                msg.role == "user" && msg.content.first?.text == "echo me"
            }) == 1
        })
    }

    @Test func `late correlated user echo replaces optimistic row after final`() async throws {
        let history = historyPayload()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history, history],
            sendMessageStatus: "pending")

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        await sendUserMessage(vm, text: "sensitive draft")
        let runId = try await waitForLastSentRunId(transport)
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }

        transport.emit(
            .chat(
                NovaChatEventPayload(
                    runId: runId,
                    sessionKey: "main",
                    state: "final",
                    message: nil,
                    errorMessage: nil)))
        try await waitUntil("final clears pending correlation bookkeeping") {
            await MainActor.run { vm.pendingRunCount == 0 }
        }

        let canonicalTimestamp = Date().timeIntervalSince1970 * 1000 + 5000
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "redacted canonical text",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: canonicalTimestamp,
                        idempotencyKey: "\(runId):user"),
                    messageId: "srv-late-user-echo",
                    messageSeq: 2)))

        try await waitUntil("late canonical echo replaces optimistic row") {
            await MainActor.run {
                vm.messages.count(where: { $0.role == "user" }) == 1 &&
                    vm.messages.contains(where: { message in
                        message.id == optimisticID &&
                            message.content.first?.text == "redacted canonical text" &&
                            message.timestamp == canonicalTimestamp
                    })
            }
        }
    }

    @Test func `metadata free same text event cannot consume pending local identity`() async throws {
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sendMessageStatus: "pending")

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        await sendUserMessage(vm, text: "legacy echo")
        let runId = try await waitForLastSentRunId(transport)
        let optimisticID = try await MainActor.run {
            try #require(vm.messages.last(where: { $0.role == "user" })?.id)
        }
        let canonicalTimestamp = Date().timeIntervalSince1970 * 1000 + 5000

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "legacy echo",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: canonicalTimestamp),
                    messageId: "srv-legacy-echo-1",
                    messageSeq: 1)))

        try await waitUntil("ambiguous metadata free event remains distinct") {
            await MainActor.run {
                vm.messages.count(where: { message in
                    message.role == "user" && message.content.first?.text == "legacy echo"
                }) == 2
            }
        }

        let localCanonicalTimestamp = canonicalTimestamp + 1000
        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "legacy echo",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: localCanonicalTimestamp,
                        idempotencyKey: "\(runId):user"),
                    messageId: "srv-local-echo-1",
                    messageSeq: 2)))

        try await waitUntil("later correlated local echo adopts only the optimistic row") {
            await MainActor.run {
                vm.messages.count(where: { message in
                    message.role == "user" && message.content.first?.text == "legacy echo"
                }) == 2 && vm.messages.contains(where: { message in
                    message.id == optimisticID &&
                        message.timestamp == localCanonicalTimestamp &&
                        message.idempotencyKey == "\(runId):user"
                }) && vm.messages.contains(where: { message in
                    message.timestamp == canonicalTimestamp && message.idempotencyKey == nil
                })
            }
        }
    }

    @Test func `appends same content user transcript when it is not local echo`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(messages: [
                    chatTextMessage(role: "user", text: "repeat", timestamp: now),
                ]),
            ])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") {
            await MainActor.run { vm.messages.count == 1 }
        }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "agent:main:main",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "repeat",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now + 1000),
                    messageId: "msg-repeat-2",
                    messageSeq: 2)))

        try await waitUntil("repeated user transcript appended") {
            await MainActor.run {
                vm.messages.count(where: { msg in
                    msg.role == "user" && msg.content.first?.text == "repeat"
                }) == 2
            }
        }
    }

    @Test func `ignores external session user message for other session`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let (transport, vm) = await makeViewModel(historyResponses: [historyPayload()])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.isEmpty } }

        transport.emit(
            .sessionMessage(
                NovaSessionMessageEventPayload(
                    sessionKey: "other",
                    message: NovaChatMessage(
                        role: "user",
                        content: [
                            NovaChatMessageContent(
                                type: "text",
                                text: "other transcript",
                                mimeType: nil,
                                fileName: nil,
                                content: nil),
                        ],
                        timestamp: now),
                    messageId: "msg-2",
                    messageSeq: 2)))

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(await MainActor.run { vm.messages.isEmpty })
    }

    @Test func `preserves message I ds across history refreshes`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload(messages: [chatTextMessage(role: "user", text: "hello", timestamp: now)])
        let history2 = historyPayload(
            messages: [
                chatTextMessage(role: "user", text: "hello", timestamp: now),
                chatTextMessage(role: "assistant", text: "world", timestamp: now + 1),
            ])

        let (transport, vm) = await makeViewModel(historyResponses: [history1, history2])

        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap history loaded") { await MainActor.run { vm.messages.count == 1 } }
        let firstIdBefore = try #require(await MainActor.run { vm.messages.first?.id })

        emitExternalFinal(transport: transport)

        try await waitUntil("history refresh") { await MainActor.run { vm.messages.count == 2 } }
        let firstIdAfter = try #require(await MainActor.run { vm.messages.first?.id })
        #expect(firstIdAfter == firstIdBefore)
    }

    @Test func `clears streaming on external final event`() async throws {
        let sessionId = "sess-main"
        let history = historyPayload(sessionId: sessionId)
        let (transport, vm) = await makeViewModel(historyResponses: [history, history])
        try await loadAndWaitBootstrap(vm: vm, sessionId: sessionId)

        emitAssistantText(transport: transport, runId: sessionId, text: "external stream")
        emitToolStart(transport: transport, runId: sessionId)

        try await waitUntil("streaming active") {
            await MainActor.run { vm.streamingAssistantText == "external stream" }
        }
        try await waitUntil("tool call pending") { await MainActor.run { vm.pendingToolCalls.count == 1 } }

        emitExternalFinal(transport: transport)

        try await waitUntil("streaming cleared") { await MainActor.run { vm.streamingAssistantText == nil } }
        #expect(await MainActor.run { vm.pendingToolCalls.isEmpty })
    }

    @Test func `seq gap clears pending runs and auto refreshes history`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history1 = historyPayload()
        let history2 = historyPayload(messages: [chatTextMessage(
            role: "assistant",
            text: "resynced after gap",
            timestamp: now)])

        let (transport, vm) = await makeViewModel(
            historyResponses: [history1, history2],
            sendMessageStatus: "pending")

        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("pending run starts") { await MainActor.run { vm.pendingRunCount == 1 } }
        let runId = try await waitForLastSentRunId(transport)
        emitAssistantText(transport: transport, runId: runId, text: "stale partial")
        emitToolStart(transport: transport, runId: runId)
        try await waitUntil("pre-gap transient state") {
            await MainActor.run {
                vm.streamingAssistantText == "stale partial" && vm.pendingToolCalls.count == 1
            }
        }

        transport.emit(.seqGap)

        try await waitUntil("pending run clears on seqGap") {
            await MainActor.run { vm.pendingRunCount == 0 }
        }
        try await waitUntil("history refreshes on seqGap") {
            await MainActor.run { vm.messages.contains(where: { $0.role == "assistant" }) }
        }
        #expect(await MainActor.run { vm.streamingAssistantText } == nil)
        #expect(await MainActor.run { vm.pendingToolCalls.isEmpty })
        #expect(await MainActor.run { vm.errorText == nil })
    }

    @Test func `session choices prefer main and recent`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let recent = now - (2 * 60 * 60 * 1000)
        let recentOlder = now - (5 * 60 * 60 * 1000)
        let stale = now - (26 * 60 * 60 * 1000)
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 4,
            defaults: nil,
            sessions: [
                sessionEntry(key: "recent-1", updatedAt: recent),
                sessionEntry(key: "main", updatedAt: stale),
                sessionEntry(key: "recent-2", updatedAt: recentOlder),
                sessionEntry(key: "old-1", updatedAt: stale),
            ])

        let (_, vm) = await makeViewModel(historyResponses: [history], sessionsResponses: [sessions])
        await MainActor.run { vm.load() }
        try await waitUntil("sessions loaded") { await MainActor.run { !vm.sessions.isEmpty } }

        let keys = await MainActor.run { vm.sessionChoices.map(\.key) }
        #expect(keys == ["main", "recent-1", "recent-2"])
    }

    @Test func `context usage follows active session switches`() async throws {
        let sessions = NovaChatSessionsListResponse(
            ts: 1,
            path: nil,
            count: 2,
            defaults: nil,
            sessions: [
                sessionEntry(
                    key: "main",
                    updatedAt: 2,
                    totalTokens: 20,
                    totalTokensFresh: true,
                    contextTokens: 100),
                sessionEntry(
                    key: "other",
                    updatedAt: 1,
                    totalTokens: 80,
                    totalTokensFresh: true,
                    contextTokens: 100),
            ])
        let (_, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionKey: "main", sessionId: "sess-main"),
                historyPayload(sessionKey: "other", sessionId: "sess-other"),
            ],
            sessionsResponses: [sessions, sessions])

        await MainActor.run { vm.load() }
        try await waitUntil("main context usage loaded") {
            await MainActor.run { vm.contextUsageFraction == 0.2 }
        }

        await MainActor.run { vm.switchSession(to: "other") }
        try await waitUntil("other context usage selected") {
            await MainActor.run { vm.contextUsageFraction == 0.8 }
        }
    }

    @Test func `session choices include current when missing`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let recent = now - (30 * 60 * 1000)
        let history = historyPayload(sessionKey: "custom", sessionId: "sess-custom")
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "main", updatedAt: recent),
            ])

        let (_, vm) = await makeViewModel(
            sessionKey: "custom",
            historyResponses: [history],
            sessionsResponses: [sessions])
        await MainActor.run { vm.load() }
        try await waitUntil("sessions loaded") { await MainActor.run { !vm.sessions.isEmpty } }

        let keys = await MainActor.run { vm.sessionChoices.map(\.key) }
        #expect(keys == ["main", "custom"])
    }

    @Test func `session choices use resolved main session key instead of literal main`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let recent = now - (30 * 60 * 1000)
        let recentOlder = now - (90 * 60 * 1000)
        let history = historyPayload(sessionKey: "Luke’s MacBook Pro", sessionId: "sess-main")
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 2,
            defaults: NovaChatSessionsDefaults(
                model: nil,
                contextTokens: nil,
                mainSessionKey: "Luke’s MacBook Pro"),
            sessions: [
                NovaChatSessionEntry(
                    key: "Luke’s MacBook Pro",
                    kind: nil,
                    displayName: "Luke’s MacBook Pro",
                    surface: nil,
                    subject: nil,
                    room: nil,
                    space: nil,
                    updatedAt: recent,
                    sessionId: nil,
                    systemSent: nil,
                    abortedLastRun: nil,
                    thinkingLevel: nil,
                    verboseLevel: nil,
                    inputTokens: nil,
                    outputTokens: nil,
                    totalTokens: nil,
                    modelProvider: nil,
                    model: nil,
                    contextTokens: nil),
                sessionEntry(key: "recent-1", updatedAt: recentOlder),
            ])

        let (_, vm) = await makeViewModel(
            sessionKey: "Luke’s MacBook Pro",
            historyResponses: [history],
            sessionsResponses: [sessions])
        await MainActor.run { vm.load() }
        try await waitUntil("sessions loaded") { await MainActor.run { !vm.sessions.isEmpty } }

        let keys = await MainActor.run { vm.sessionChoices.map(\.key) }
        #expect(keys == ["Luke’s MacBook Pro", "recent-1"])
    }

    @Test func `session choices hide internal onboarding session`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let recent = now - (2 * 60 * 1000)
        let recentOlder = now - (5 * 60 * 1000)
        let history = historyPayload(sessionKey: "agent:main:main", sessionId: "sess-main")
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 2,
            defaults: NovaChatSessionsDefaults(
                model: nil,
                contextTokens: nil,
                mainSessionKey: "agent:main:main"),
            sessions: [
                NovaChatSessionEntry(
                    key: "agent:main:onboarding",
                    kind: nil,
                    displayName: "Luke’s MacBook Pro",
                    surface: nil,
                    subject: nil,
                    room: nil,
                    space: nil,
                    updatedAt: recent,
                    sessionId: nil,
                    systemSent: nil,
                    abortedLastRun: nil,
                    thinkingLevel: nil,
                    verboseLevel: nil,
                    inputTokens: nil,
                    outputTokens: nil,
                    totalTokens: nil,
                    modelProvider: nil,
                    model: nil,
                    contextTokens: nil),
                NovaChatSessionEntry(
                    key: "agent:main:main",
                    kind: nil,
                    displayName: "Luke’s MacBook Pro",
                    surface: nil,
                    subject: nil,
                    room: nil,
                    space: nil,
                    updatedAt: recentOlder,
                    sessionId: nil,
                    systemSent: nil,
                    abortedLastRun: nil,
                    thinkingLevel: nil,
                    verboseLevel: nil,
                    inputTokens: nil,
                    outputTokens: nil,
                    totalTokens: nil,
                    modelProvider: nil,
                    model: nil,
                    contextTokens: nil),
            ])

        let (_, vm) = await makeViewModel(
            sessionKey: "agent:main:main",
            historyResponses: [history],
            sessionsResponses: [sessions])
        await MainActor.run { vm.load() }
        try await waitUntil("sessions loaded") { await MainActor.run { !vm.sessions.isEmpty } }

        let keys = await MainActor.run { vm.sessionChoices.map(\.key) }
        #expect(keys == ["agent:main:main"])
    }

    @Test func `new trigger starts fresh agent session without admin reset`() async throws {
        let before = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "before new", timestamp: 1),
            ])
        let after = historyPayload(sessionKey: "agent:aiden:ios-new", sessionId: nil, messages: [])
        let sessions = NovaChatSessionsListResponse(
            ts: nil,
            path: nil,
            count: 1,
            defaults: NovaChatSessionsDefaults(
                model: nil,
                contextTokens: nil,
                mainSessionKey: "agent:aiden:main"),
            sessions: [
                sessionEntry(key: "agent:aiden:main", updatedAt: 1),
            ])

        let (transport, vm) = await makeViewModel(
            historyResponses: [before, after],
            sessionsResponses: [sessions])
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial history loaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "before new" }
        }

        await MainActor.run {
            vm.input = "/new"
            vm.send()
        }

        try await waitUntil("fresh agent session selected") {
            await MainActor.run { vm.sessionKey.hasPrefix("agent:aiden:ios-") && vm.messages.isEmpty }
        }
        let createdKeys = await transport.createdSessionKeys()
        #expect(createdKeys.count == 1)
        #expect(createdKeys.first?.hasPrefix("agent:aiden:ios-") == true)
        #expect(await transport.createdParentSessionKeys() == ["main"])
        #expect(await transport.resetSessionKeys().isEmpty)
        #expect(await transport.lastSentRunId() == nil)

        await sendUserMessage(vm, text: "hello fresh session")
        try await waitUntil("send uses fresh session") {
            let key = await transport.lastSentSessionKey()
            return key?.hasPrefix("agent:aiden:ios-") == true
        }
    }

    @Test func `new trigger falls back to reset when create session is unsupported`() async throws {
        let before = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "before new", timestamp: 1),
            ])
        let after = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "after reset fallback", timestamp: 2),
            ])
        let unsupported = NSError(
            domain: "NovaChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "sessions.create not supported by this transport"])

        let (transport, vm) = await makeViewModel(
            historyResponses: [before, after],
            createSessionHook: { _, _ in throw unsupported })
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial history loaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "before new" }
        }

        await MainActor.run {
            vm.input = "/new"
            vm.send()
        }

        try await waitUntil("reset fallback called") {
            await transport.resetSessionKeys() == ["main"]
        }
        try await waitUntil("history reloaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "after reset fallback" }
        }
        #expect(await transport.createdSessionKeys().isEmpty)
        #expect(await MainActor.run { vm.sessionKey } == "main")
        #expect(await MainActor.run { vm.errorText } == nil)
        #expect(await transport.lastSentRunId() == nil)
    }

    @Test func `default create session overload rejects unsupported agent and base ref options`() async throws {
        let (transport, _) = await makeViewModel(historyResponses: [historyPayload()])

        await #expect(throws: (any Error).self) {
            _ = try await transport.createSession(
                key: "next",
                label: nil,
                agentID: nil,
                parentSessionKey: nil,
                worktree: true,
                worktreeBaseRef: "release/2026.7")
        }
        await #expect(throws: (any Error).self) {
            _ = try await transport.createSession(
                key: "next",
                label: nil,
                agentID: "reviewer",
                parentSessionKey: nil,
                worktree: nil,
                worktreeBaseRef: nil)
        }
        #expect(await transport.createdSessionKeys().isEmpty)

        let created = try await transport.createSession(
            key: "next",
            label: nil,
            agentID: nil,
            parentSessionKey: nil,
            worktree: nil,
            worktreeBaseRef: nil)
        #expect(created.key == "next")
        #expect(await transport.createdSessionKeys() == ["next"])
    }

    @Test func `new trigger keeps selected global agent scope`() async throws {
        let (transport, vm) = await makeViewModel(
            sessionKey: "global",
            activeAgentId: "reviewer",
            historyResponses: [historyPayload(sessionKey: "global"), historyPayload()])
        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run {
            vm.input = "/new"
            vm.send()
        }

        try await waitUntil("fresh selected-agent session created") {
            await MainActor.run { vm.sessionKey.hasPrefix("agent:reviewer:ios-") }
        }
        #expect(await transport.createdSessionKeys().first?.hasPrefix("agent:reviewer:ios-") == true)
        #expect(await transport.createdParentSessionKeys() == ["global"])
    }

    @Test func `new trigger prefers explicit session agent over ambient agent`() async throws {
        let (transport, vm) = await makeViewModel(
            sessionKey: "agent:alice:main",
            activeAgentId: "main",
            historyResponses: [historyPayload(sessionKey: "agent:alice:main"), historyPayload()])
        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run {
            vm.input = "/new"
            vm.send()
        }

        try await waitUntil("fresh explicit-agent session created") {
            await MainActor.run { vm.sessionKey.hasPrefix("agent:alice:ios-") }
        }
        #expect(await transport.createdSessionKeys().first?.hasPrefix("agent:alice:ios-") == true)
        #expect(await transport.createdParentSessionKeys() == ["agent:alice:main"])
    }

    @Test func `send attempts request when cached health is stale false`() async throws {
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            healthResponses: [false])
        await MainActor.run { vm.load() }
        try await waitUntil("bootstrap records stale health") {
            await MainActor.run { vm.sessionId == "sess-main" && !vm.healthOK }
        }

        await sendUserMessage(vm, text: "hello despite stale health")

        try await waitUntil("send reaches transport") {
            await transport.lastSentSessionKey() == "main"
        }
        #expect(await MainActor.run { vm.errorText } == nil)
    }

    @Test func `reset trigger resets session and reloads history`() async throws {
        let before = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "before reset", timestamp: 1),
            ])
        let after = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "after reset", timestamp: 2),
            ])

        let (transport, vm) = await makeViewModel(historyResponses: [before, after])
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial history loaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "before reset" }
        }

        await MainActor.run {
            vm.input = "/reset"
            vm.send()
        }

        try await waitUntil("reset called") {
            await transport.resetSessionKeys() == ["main"]
        }
        try await waitUntil("history reloaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "after reset" }
        }
        #expect(await transport.lastSentRunId() == nil)
    }

    @Test func `compact trigger compacts session and reloads history`() async throws {
        let before = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "before compact", timestamp: 1),
            ])
        let after = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "after compact", timestamp: 2),
            ])

        let (transport, vm) = await makeViewModel(historyResponses: [before, after])
        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("initial history loaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "before compact" }
        }

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("compact called") {
            await transport.compactSessionKeys() == ["main"]
        }
        try await waitUntil("history reloaded") {
            await MainActor.run { vm.messages.first?.content.first?.text == "after compact" }
        }
        #expect(await transport.lastSentRunId() == nil)
    }

    @Test func `compact trigger shows generic error message on failure`() async throws {
        let history = historyPayload()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            compactSessionHook: { _ in
                throw NSError(
                    domain: "TestCompact",
                    code: 42,
                    userInfo: [NSLocalizedDescriptionKey: "backend details should not leak"])
            })
        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("compact attempted") {
            await transport.compactSessionKeys() == ["main"]
        }
        #expect(await MainActor.run { vm.errorText } == "Unable to compact the thread. Please try again.")
    }

    @Test func `compact trigger ignores concurrent and immediate repeat requests`() async throws {
        let before = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "before compact", timestamp: 1),
            ])
        let after = historyPayload(
            messages: [
                chatTextMessage(role: "assistant", text: "after compact", timestamp: 2),
            ])
        let gate = AsyncGate()
        let (transport, vm) = await makeViewModel(
            historyResponses: [before, after],
            compactSessionHook: { _ in
                await gate.wait()
            })
        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("single compact request issued") {
            await transport.compactSessionKeys() == ["main"]
        }
        #expect(await MainActor.run { vm.errorText } == nil)

        await gate.open()
        try await waitUntil("history reloaded after compact") {
            await MainActor.run {
                vm.messages.first?.content.first?.text == "after compact" && !vm.isLoading
            }
        }

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("compact cooldown rejects immediate retry") {
            await MainActor.run {
                vm.errorText == "Please wait before compacting this thread again."
            }
        }
        #expect(await transport.compactSessionKeys() == ["main"])
    }

    @Test func `compact trigger allows immediate retry after failure`() async throws {
        let history = historyPayload()
        let attemptCount = AsyncCounter()
        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            compactSessionHook: { _ in
                let next = await attemptCount.increment()
                if next == 1 {
                    throw NSError(
                        domain: "TestCompact",
                        code: 42,
                        userInfo: [NSLocalizedDescriptionKey: "temporary failure"])
                }
            })
        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("first compact attempted") {
            await transport.compactSessionKeys() == ["main"]
        }
        #expect(await MainActor.run { vm.errorText } == "Unable to compact the thread. Please try again.")

        await MainActor.run {
            vm.input = "/compact"
            vm.send()
        }

        try await waitUntil("second compact attempted") {
            await transport.compactSessionKeys() == ["main", "main"]
        }
        #expect(await MainActor.run { vm.errorText } == nil)
    }

    @Test func `slash command catalog filters commands and skills`() async throws {
        let commands = [
            commandChoice(
                name: "compact",
                aliases: ["/compact"],
                description: "Compact the session",
                source: .command),
            commandChoice(
                name: "review",
                aliases: ["/review"],
                description: "Review the current change",
                source: .skill,
                acceptsArgs: true),
        ]
        let (_, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            commandResponses: [commands])

        await MainActor.run { vm.loadSlashCommandsIfNeeded() }
        try await waitUntil("slash commands loaded") {
            await MainActor.run { vm.hasLoadedSlashCommands }
        }

        let allMatches = await MainActor.run {
            vm.slashCommandMatches(query: "/", filter: .all).map(\.name)
        }
        #expect(allMatches == ["compact", "review"])

        let commandMatches = await MainActor.run {
            vm.slashCommandMatches(query: "/co", filter: .commands).map(\.name)
        }
        #expect(commandMatches == ["compact"])

        let skillMatches = await MainActor.run {
            vm.slashCommandMatches(query: "/skill re", filter: .all).map(\.name)
        }
        #expect(skillMatches == ["review"])

        await MainActor.run {
            vm.applySlashCommandSelection(commands[1])
        }
        #expect(await MainActor.run { vm.input } == "/review ")
    }

    @Test func `known slash command sends through chat send`() async throws {
        let commands = [
            commandChoice(
                name: "model",
                aliases: ["/model"],
                description: "Change model",
                source: .command,
                acceptsArgs: true),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(), historyPayload()],
            commandResponses: [commands])
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "/model gpt-5")
        _ = try await waitForLastSentRunId(transport)

        #expect(await transport.sentMessages() == ["/model gpt-5"])
    }

    @Test func `slash command catalog loads for current session`() async throws {
        let commands = [
            commandChoice(name: "model", aliases: ["/model"], source: .command, acceptsArgs: true),
        ]
        let (transport, vm) = await makeViewModel(
            sessionKey: "agent:reviewer:main",
            historyResponses: [historyPayload()],
            commandResponses: [commands])

        await MainActor.run { vm.loadSlashCommandsIfNeeded() }
        try await waitUntil("slash commands loaded") {
            await MainActor.run { vm.hasLoadedSlashCommands }
        }

        #expect(await transport.commandSessionKeys() == ["agent:reviewer:main"])
    }

    @Test func `unknown leading slash is sent to gateway after command catalog loads`() async throws {
        let commands = [
            commandChoice(name: "model", aliases: ["/model"], source: .command, acceptsArgs: true),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(), historyPayload()],
            commandResponses: [commands])
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "/does-not-exist")
        _ = try await waitForLastSentRunId(transport)

        #expect(await transport.sentMessages() == ["/does-not-exist"])
    }

    @Test func `double slash sends as ordinary text`() async throws {
        let commands = [
            commandChoice(name: "model", aliases: ["/model"], source: .command, acceptsArgs: true),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload(), historyPayload()],
            commandResponses: [commands])
        try await loadAndWaitBootstrap(vm: vm)

        await sendUserMessage(vm, text: "//does-not-trigger")
        _ = try await waitForLastSentRunId(transport)

        #expect(await transport.sentMessages() == ["//does-not-trigger"])
    }

    @Test func `bootstraps model selection from session and defaults`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: NovaChatSessionsDefaults(model: "openai/gpt-4.1-mini", contextTokens: nil),
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: "anthropic/claude-opus-4-6"),
            ])
        let models = [
            modelChoice(id: "anthropic/claude-opus-4-6", name: "Claude Opus 4.6"),
            modelChoice(id: "openai/gpt-4.1-mini", name: "GPT-4.1 mini", provider: "openai"),
        ]

        let (_, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models])

        try await loadAndWaitBootstrap(vm: vm)
        try await waitUntil("model metadata bootstrap") {
            await MainActor.run {
                vm.showsModelPicker
                    && vm.modelSelectionID == "anthropic/claude-opus-4-6"
                    && vm.defaultModelLabel == "Default: openai/gpt-4.1-mini"
            }
        }

        #expect(await MainActor.run { vm.showsModelPicker })
        #expect(await MainActor.run { vm.modelSelectionID } == "anthropic/claude-opus-4-6")
        #expect(await MainActor.run { vm.defaultModelLabel } == "Default: openai/gpt-4.1-mini")
    }

    @Test func `selecting default model patches nil and updates selection`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: NovaChatSessionsDefaults(model: "openai/gpt-4.1-mini", contextTokens: nil),
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: "anthropic/claude-opus-4-6"),
            ])
        let models = [
            modelChoice(id: "anthropic/claude-opus-4-6", name: "Claude Opus 4.6"),
            modelChoice(id: "openai/gpt-4.1-mini", name: "GPT-4.1 mini", provider: "openai"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models])

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel(NovaChatViewModel.defaultModelSelectionID) }

        try await waitUntil("session model patched") {
            let patched = await transport.patchedModels()
            return patched == [nil]
        }

        #expect(await MainActor.run { vm.modelSelectionID } == NovaChatViewModel.defaultModelSelectionID)
    }

    @Test @MainActor func `successful model selection records recent and selected pin updates sections`() async throws {
        let suiteName = "ChatViewModelTests.modelPicker.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let modelPickerStore = ChatModelPickerStore(defaults: defaults)
        let now = Date().timeIntervalSince1970 * 1000
        let selectedID = "openai/gpt-5.4"
        let models = [
            modelChoice(id: "gpt-5.4", name: "GPT-5.4", provider: "openai"),
            modelChoice(id: "claude-opus-4-6", name: "Claude Opus 4.6"),
        ]
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [sessionEntry(key: "main", updatedAt: now, model: nil)])
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sessionsResponses: [sessions],
            modelResponses: [models],
            modelPickerStore: modelPickerStore)

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run { vm.selectModel(selectedID) }
        try await waitUntil("successful model selection recorded as recent") {
            await MainActor.run { vm.modelPickerSections.recent.map(\.selectionID) == [selectedID] }
        }
        #expect(await transport.patchedModels() == [selectedID])
        #expect(modelPickerStore.recents == [selectedID])

        await MainActor.run { vm.toggleSelectedModelPinned() }
        #expect(await MainActor.run { vm.isSelectedModelPinned })
        #expect(await MainActor.run { vm.modelPickerSections.pinned.map(\.selectionID) } == [selectedID])
        #expect(await MainActor.run { vm.modelPickerSections.recent.isEmpty })
    }

    @Test func `selecting provider qualified model disambiguates duplicate model I ds`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: NovaChatSessionsDefaults(model: "openrouter/gpt-4.1-mini", contextTokens: nil),
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: "gpt-4.1-mini", modelProvider: "openrouter"),
            ])
        let models = [
            modelChoice(id: "gpt-4.1-mini", name: "GPT-4.1 mini", provider: "openai"),
            modelChoice(id: "gpt-4.1-mini", name: "GPT-4.1 mini", provider: "openrouter"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models])

        try await loadAndWaitBootstrap(vm: vm)

        #expect(await MainActor.run { vm.modelSelectionID } == "openrouter/gpt-4.1-mini")

        await MainActor.run { vm.selectModel("openai/gpt-4.1-mini") }

        try await waitUntil("provider-qualified model patched") {
            let patched = await transport.patchedModels()
            return patched == ["openai/gpt-4.1-mini"]
        }
    }

    @Test func `slash model I ds stay provider qualified in selection and patch`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "agent:main:main", updatedAt: now, model: nil),
            ])
        let models = [
            modelChoice(
                id: "openai/gpt-5.4",
                name: "GPT-5.4 via Vercel AI Gateway",
                provider: "vercel-ai-gateway"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models])

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel("vercel-ai-gateway/openai/gpt-5.4") }

        try await waitUntil("slash model patched with provider-qualified ref") {
            let patched = await transport.patchedModels()
            return patched == ["vercel-ai-gateway/openai/gpt-5.4"]
        }
    }

    @Test @MainActor func `stale model patch completions do not overwrite newer selection`() async throws {
        let suiteName = "ChatViewModelTests.staleModelPicker.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let modelPickerStore = ChatModelPickerStore(defaults: defaults)
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: nil),
            ])
        let models = [
            modelChoice(id: "gpt-5.4", name: "GPT-5.4", provider: "openai"),
            modelChoice(id: "gpt-5.4-pro", name: "GPT-5.4 Pro", provider: "openai"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models],
            setSessionModelHook: { model in
                if model == "openai/gpt-5.4" {
                    try await Task.sleep(for: .milliseconds(200))
                }
            },
            modelPickerStore: modelPickerStore)

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel("openai/gpt-5.4") }
        try await waitUntil("older model patch starts") {
            await transport.patchedModels() == ["openai/gpt-5.4"]
        }
        await MainActor.run { vm.selectModel("openai/gpt-5.4-pro") }

        try await waitUntil("two model patches issued") {
            await transport.patchedModels() == ["openai/gpt-5.4", "openai/gpt-5.4-pro"]
        }
        await sendUserMessage(vm, text: "after model patches")
        _ = try await waitForLastSentRunId(transport)

        #expect(await MainActor.run { vm.modelSelectionID } == "openai/gpt-5.4-pro")
        #expect(await MainActor.run { vm.sessions.first(where: { $0.key == "main" })?.model } == "gpt-5.4-pro")
        #expect(await MainActor.run { vm.sessions.first(where: { $0.key == "main" })?.modelProvider } == "openai")
        #expect(modelPickerStore.recents == ["openai/gpt-5.4-pro"])
    }

    @Test func `distinct model patches are serialized in selection order`() async throws {
        let firstPatchGate = AsyncGate()
        let now = Date().timeIntervalSince1970 * 1000
        let sessions = sessionsResponse(sessionEntry(key: "main", updatedAt: now, model: nil))
        let models = [
            modelChoice(id: "gpt-first", name: "First", provider: "openai"),
            modelChoice(id: "gpt-second", name: "Second", provider: "openai"),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sessionsResponses: [sessions],
            modelResponses: [models],
            modelPatchResults: [
                NovaChatModelPatchResult(
                    modelProvider: "openai",
                    model: "gpt-first",
                    thinkingLevel: "high"),
                NovaChatModelPatchResult(
                    modelProvider: "openai",
                    model: "gpt-second",
                    thinkingLevel: "medium"),
            ],
            setSessionModelHook: { model in
                if model == "openai/gpt-first" {
                    await firstPatchGate.wait()
                }
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run {
            vm.selectModel("openai/gpt-first")
            vm.selectModel("openai/gpt-second")
        }
        try await waitUntil("first model patch starts") {
            await transport.patchedModels() == ["openai/gpt-first"]
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(await transport.patchedModels() == ["openai/gpt-first"])

        await firstPatchGate.open()
        try await waitUntil("second model patch follows first") {
            await transport.patchedModels() == ["openai/gpt-first", "openai/gpt-second"]
        }
        await vm.waitForPendingSessionSettings(in: "main")
        #expect(await MainActor.run { vm.modelSelectionID } == "openai/gpt-second")
        #expect(await MainActor.run { vm.sessions.first?.model } == "gpt-second")
    }

    @Test func `thinking patch follows in flight model patch on shared settings lane`() async throws {
        let modelPatchGate = AsyncGate()
        let sessions = sessionsResponse(
            sessionEntry(
                key: "main",
                updatedAt: 1,
                model: "claude-fable-5",
                modelProvider: "anthropic",
                thinkingLevels: [thinkingOption("off"), thinkingOption("high"), thinkingOption("ultra")]))
        let models = [
            modelChoice(id: "gpt-5.6-sol", name: "Sol", provider: "openai", reasoning: true),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sessionsResponses: [sessions],
            modelResponses: [models],
            modelPatchResults: [
                NovaChatModelPatchResult(
                    modelProvider: "openai",
                    model: "gpt-5.6-sol",
                    thinkingLevel: "high",
                    thinkingLevels: [thinkingOption("off"), thinkingOption("high"), thinkingOption("ultra")]),
            ],
            setSessionModelHook: { model in
                if model == "openai/gpt-5.6-sol" {
                    await modelPatchGate.wait()
                }
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run {
            vm.selectModel("openai/gpt-5.6-sol")
            vm.selectThinkingLevel("ultra")
        }
        try await waitUntil("model patch starts") {
            await transport.patchedModels() == ["openai/gpt-5.6-sol"]
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(await (transport.patchedThinkingLevels()).isEmpty)

        await modelPatchGate.open()
        try await waitUntil("thinking patch follows model") {
            await transport.patchedThinkingLevels() == ["ultra"]
        }
        await vm.waitForPendingSessionSettings(in: "main")
        #expect(await MainActor.run { vm.modelSelectionID } == "openai/gpt-5.6-sol")
        #expect(await MainActor.run { vm.thinkingLevel } == "ultra")
    }

    @Test func `send waits for in flight model patch to finish`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: nil),
            ])
        let models = [
            modelChoice(id: "gpt-5.4", name: "GPT-5.4", provider: "openai"),
        ]
        let gate = AsyncGate()

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models],
            setSessionModelHook: { model in
                if model == "openai/gpt-5.4" {
                    await gate.wait()
                }
            })

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel("openai/gpt-5.4") }
        try await waitUntil("model patch started") {
            let patched = await transport.patchedModels()
            return patched == ["openai/gpt-5.4"]
        }

        await sendUserMessage(vm, text: "hello")
        try await waitUntil("send entered waiting state") {
            await MainActor.run { vm.isSending }
        }
        #expect(await transport.lastSentRunId() == nil)

        await MainActor.run { vm.selectThinkingLevel("high") }
        try await waitUntil("thinking level changed while send is blocked") {
            await MainActor.run { vm.thinkingLevel == "high" }
        }

        await gate.open()

        try await waitUntil("send released after model patch") {
            await transport.lastSentRunId() != nil
        }
        #expect(await transport.sentThinkingLevels() == ["off"])
    }

    @Test func `failed latest model selection does not replay after older completion finishes`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: nil),
            ])
        let models = [
            modelChoice(id: "gpt-5.4", name: "GPT-5.4", provider: "openai"),
            modelChoice(id: "gpt-5.4-pro", name: "GPT-5.4 Pro", provider: "openai"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models],
            setSessionModelHook: { model in
                if model == "openai/gpt-5.4" {
                    try await Task.sleep(for: .milliseconds(200))
                    return
                }
                if model == "openai/gpt-5.4-pro" {
                    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
                }
            })

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel("openai/gpt-5.4") }
        try await waitUntil("older model patch starts") {
            await transport.patchedModels() == ["openai/gpt-5.4"]
        }
        await MainActor.run { vm.selectModel("openai/gpt-5.4-pro") }

        try await waitUntil("older model completion wins after latest failure") {
            await MainActor.run {
                vm.sessions.first(where: { $0.key == "main" })?.model == "gpt-5.4" &&
                    vm.sessions.first(where: { $0.key == "main" })?.modelProvider == "openai"
            }
        }

        #expect(await MainActor.run { vm.modelSelectionID } == "openai/gpt-5.4")
        #expect(await MainActor.run { vm.sessions.first(where: { $0.key == "main" })?.model } == "gpt-5.4")
        #expect(await MainActor.run { vm.sessions.first(where: { $0.key == "main" })?.modelProvider } == "openai")
        #expect(await transport.patchedModels() == ["openai/gpt-5.4", "openai/gpt-5.4-pro"])
    }

    @Test func `failed latest model selection restores earlier success without replay`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let history = historyPayload()
        let sessions = NovaChatSessionsListResponse(
            ts: now,
            path: nil,
            count: 1,
            defaults: nil,
            sessions: [
                sessionEntry(key: "main", updatedAt: now, model: nil),
            ])
        let models = [
            modelChoice(id: "gpt-5.4", name: "GPT-5.4", provider: "openai"),
            modelChoice(id: "gpt-5.4-pro", name: "GPT-5.4 Pro", provider: "openai"),
        ]

        let (transport, vm) = await makeViewModel(
            historyResponses: [history],
            sessionsResponses: [sessions],
            modelResponses: [models],
            setSessionModelHook: { model in
                if model == "openai/gpt-5.4" {
                    try await Task.sleep(for: .milliseconds(100))
                    return
                }
                if model == "openai/gpt-5.4-pro" {
                    try await Task.sleep(for: .milliseconds(200))
                    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
                }
            })

        try await loadAndWaitBootstrap(vm: vm)

        await MainActor.run { vm.selectModel("openai/gpt-5.4") }
        try await waitUntil("earlier model patch starts") {
            await transport.patchedModels() == ["openai/gpt-5.4"]
        }
        await MainActor.run { vm.selectModel("openai/gpt-5.4-pro") }

        try await waitUntil("latest failure restores prior successful model") {
            await MainActor.run {
                vm.modelSelectionID == "openai/gpt-5.4" &&
                    vm.sessions.first(where: { $0.key == "main" })?.model == "gpt-5.4" &&
                    vm.sessions.first(where: { $0.key == "main" })?.modelProvider == "openai"
            }
        }

        #expect(await transport.patchedModels() == ["openai/gpt-5.4", "openai/gpt-5.4-pro"])
    }

    @Test func `two failed queued model patches restore the confirmed model`() async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let sessions = sessionsResponse(
            sessionEntry(
                key: "main",
                updatedAt: now,
                model: "gpt-original",
                modelProvider: "openai"))
        let models = [
            modelChoice(id: "gpt-original", name: "Original", provider: "openai"),
            modelChoice(id: "gpt-first", name: "First", provider: "openai"),
            modelChoice(id: "gpt-second", name: "Second", provider: "openai"),
        ]
        let (transport, vm) = await makeViewModel(
            historyResponses: [historyPayload()],
            sessionsResponses: [sessions],
            modelResponses: [models],
            setSessionModelHook: { model in
                guard model == "openai/gpt-first" || model == "openai/gpt-second" else { return }
                throw NSError(
                    domain: "test",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "patch failed"])
            })

        try await loadAndWaitBootstrap(vm: vm)
        await MainActor.run {
            vm.selectModel("openai/gpt-first")
            vm.selectModel("openai/gpt-second")
        }

        try await waitUntil("both queued patches fail back to the confirmed model") {
            let patched = await transport.patchedModels()
            let selectionID = await MainActor.run { vm.modelSelectionID }
            return patched == ["openai/gpt-first", "openai/gpt-second"] &&
                selectionID == "openai/gpt-original"
        }
        #expect(await MainActor.run { vm.sessions.first?.model } == "gpt-original")

        await MainActor.run { vm.selectModel("openai/gpt-first") }
        try await waitUntil("failed optimistic model remains retryable") {
            await transport.patchedModels() == [
                "openai/gpt-first",
                "openai/gpt-second",
                "openai/gpt-first",
            ]
        }
    }

    @Test @MainActor func `switch session notifies session changed callback`() async throws {
        var changedSessionKeys: [String] = []
        let (_, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionKey: "main", sessionId: "sess-main"),
                historyPayload(sessionKey: "other", sessionId: "sess-other"),
            ],
            onSessionChanged: { changedSessionKeys.append($0) })

        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        vm.switchSession(to: "other")

        try await waitUntil("user switch bootstrapped target session") {
            await MainActor.run { vm.sessionKey == "other" && vm.sessionId == "sess-other" }
        }
        #expect(changedSessionKeys == ["other"])
    }

    @Test @MainActor func `sync session does not notify session changed callback`() async throws {
        var changedSessionKeys: [String] = []
        let (_, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionKey: "main", sessionId: "sess-main"),
                historyPayload(sessionKey: "other", sessionId: "sess-other"),
            ],
            onSessionChanged: { changedSessionKeys.append($0) })

        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        vm.syncSession(to: "other")

        try await waitUntil("external sync bootstrapped target session") {
            await MainActor.run { vm.sessionKey == "other" && vm.sessionId == "sess-other" }
        }
        #expect(changedSessionKeys.isEmpty)
    }

    @Test @MainActor func `refresh ignores late history from canceled bootstrap for same session`() async throws {
        let staleHistoryGate = SessionSubscribeGate()
        let mainHistoryCount = AsyncCounter()
        let staleHistoryReleasedCount = AsyncCounter()
        let (_, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(
                    sessionKey: "main",
                    sessionId: "sess-stale-load",
                    messages: [chatTextMessage(role: "assistant", text: "stale load", timestamp: 1)]),
                historyPayload(
                    sessionKey: "main",
                    sessionId: "sess-current-refresh",
                    messages: [chatTextMessage(role: "assistant", text: "current refresh", timestamp: 2)]),
            ],
            requestHistoryHook: { sessionKey in
                guard sessionKey == "main" else { return }
                let count = await mainHistoryCount.increment()
                if count == 1 {
                    await staleHistoryGate.wait()
                    _ = await staleHistoryReleasedCount.increment()
                }
            })

        vm.load()
        try await waitUntil("first bootstrap history request is in flight") {
            await mainHistoryCount.current() == 1
        }

        vm.refresh()
        try await waitUntil("refresh bootstrap wins") {
            await MainActor.run {
                vm.sessionId == "sess-current-refresh" &&
                    vm.messages.contains { message in
                        message.content.contains { $0.text == "current refresh" }
                    }
            }
        }

        await staleHistoryGate.release()
        try await waitUntil("stale load history resumes") {
            await staleHistoryReleasedCount.current() == 1
        }

        #expect(await MainActor.run { vm.sessionId } == "sess-current-refresh")
        #expect(await MainActor.run {
            !vm.messages.contains { message in
                message.content.contains { $0.text == "stale load" }
            }
        })
    }

    @Test @MainActor func `manual refresh invalidates older same session event refresh`() async throws {
        let staleRefreshGate = SessionSubscribeGate()
        let mainHistoryCount = AsyncCounter()
        let staleRefreshReleasedCount = AsyncCounter()
        let (transport, vm) = await makeViewModel(
            historyResponses: [
                historyPayload(sessionKey: "main", sessionId: "sess-main"),
                historyPayload(
                    sessionKey: "main",
                    sessionId: "sess-main-event-stale",
                    messages: [chatTextMessage(role: "assistant", text: "stale same-session event", timestamp: 1)]),
                historyPayload(
                    sessionKey: "main",
                    sessionId: "sess-main-manual-refresh",
                    messages: [chatTextMessage(role: "assistant", text: "current manual refresh", timestamp: 2)]),
            ],
            requestHistoryHook: { sessionKey in
                guard sessionKey == "main" else { return }
                let count = await mainHistoryCount.increment()
                if count == 2 {
                    await staleRefreshGate.wait()
                    _ = await staleRefreshReleasedCount.increment()
                }
            })

        try await loadAndWaitBootstrap(vm: vm, sessionId: "sess-main")

        transport.emit(.seqGap)
        try await waitUntil("same-session event refresh is in flight") {
            await mainHistoryCount.current() == 2
        }

        vm.refresh()
        try await waitUntil("manual refresh wins") {
            await MainActor.run {
                vm.sessionId == "sess-main-manual-refresh" &&
                    vm.messages.contains { message in
                        message.content.contains { $0.text == "current manual refresh" }
                    }
            }
        }

        await staleRefreshGate.release()
        try await waitUntil("stale same-session event refresh resumes") {
            await staleRefreshReleasedCount.current() == 1
        }

        #expect(await MainActor.run { vm.sessionId } == "sess-main-manual-refresh")
        #expect(await MainActor.run {
            !vm.messages.contains { message in
                message.content.contains { $0.text == "stale same-session event" }
            }
        })
    }

    @Test @MainActor func `failed newer same session refresh does not drop older successful send refresh`() async throws {
        let sendRefreshGate = 