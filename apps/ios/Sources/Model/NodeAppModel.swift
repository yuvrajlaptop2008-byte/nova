import CoreLocation
import CryptoKit
import Observation
import NovaChatUI
import NovaKit
import NovaProtocol
import os
import Security
import SwiftUI
import UIKit
import UserNotifications

private let clientDatabaseLogger = Logger(
    subsystem: "ai.novafoundation.app",
    category: "ClientDatabases")

/// Wrap errors without pulling non-Sendable types into async notification paths.
private struct NotificationCallError: Error {
    let message: String
}

private struct GatewayRelayIdentityResponse: Decodable {
    let deviceId: String
    let publicKey: String
}

private struct WatchChatPreview {
    var items: [NovaWatchChatItem]
    var status: NovaWatchAppStatus?
    var statusText: String?
}

private struct WatchChatMetadataEnvelope: Decodable {
    struct Metadata: Decodable {
        var id: String?
    }

    var metadata: Metadata?
    var messageToolMirror: [String: String]?

    enum CodingKeys: String, CodingKey {
        case metadata = "__nova"
        case messageToolMirror = "novaMessageToolMirror"
    }
}

private struct WatchChatMessageEntry {
    var message: NovaChatMessage
    var text: String
    var serverId: String?
    var isMessageToolMirror: Bool
}

private struct ExecApprovalGatewayEventPayload: Decodable {
    var id: String
}

private struct NodeEventRequestPayload: Encodable {
    var event: String
    var payloadJSON: String
}

/// Ensures notification requests return promptly even if the system prompt blocks.
private final class NotificationInvokeLatch<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Result<T, NotificationCallError>, Never>?
    private var resumed = false

    func setContinuation(_ continuation: CheckedContinuation<Result<T, NotificationCallError>, Never>) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ response: Result<T, NotificationCallError>) {
        let cont: CheckedContinuation<Result<T, NotificationCallError>, Never>?
        self.lock.lock()
        if self.resumed {
            self.lock.unlock()
            return
        }
        self.resumed = true
        cont = self.continuation
        self.continuation = nil
        self.lock.unlock()
        cont?.resume(returning: response)
    }
}

private enum IOSDeepLinkAgentPolicy {
    static let maxMessageChars = 20000
    static let maxUnkeyedConfirmChars = 240
}

private enum TalkCapturePreparationOwner {
    case remotePushToTalk(epoch: UInt64)
    case chatDictation(epoch: UInt64)
}

@MainActor
@Observable
// swiftlint:disable type_body_length file_length
final class NodeAppModel {
    private nonisolated static let watchChatPreviewItemLimit = 5
    private nonisolated static let watchMessageMaxImmediateRetryAttempts = 3

    struct AgentDeepLinkPrompt: Identifiable, Equatable {
        let id: String
        let messagePreview: String
        let urlPreview: String
        let request: AgentDeepLink
    }

    struct ExecApprovalPrompt: Identifiable, Equatable, Codable {
        let id: String
        let kind: String?
        let gatewayStableID: String
        let commandText: String
        let commandPreview: String?
        let warningText: String?
        let allowedDecisions: [String]
        let host: String?
        let nodeId: String?
        let agentId: String?
        let expiresAtMs: Int64?
        let descriptionText: String?
        let pluginId: String?
        let toolName: String?
        let pluginSeverity: String?

        init(
            id: String,
            kind: String?,
            gatewayStableID: String,
            commandText: String,
            commandPreview: String?,
            warningText: String?,
            allowedDecisions: [String],
            host: String?,
            nodeId: String?,
            agentId: String?,
            expiresAtMs: Int64?,
            descriptionText: String? = nil,
            pluginId: String? = nil,
            toolName: String? = nil,
            pluginSeverity: String? = nil)
        {
            self.id = id
            self.kind = kind
            self.gatewayStableID = gatewayStableID
            self.commandText = commandText
            self.commandPreview = commandPreview
            self.warningText = warningText
            self.allowedDecisions = allowedDecisions
            self.host = host
            self.nodeId = nodeId
            self.agentId = agentId
            self.expiresAtMs = expiresAtMs
            self.descriptionText = descriptionText
            self.pluginId = pluginId
            self.toolName = toolName
            self.pluginSeverity = pluginSeverity
        }

        var allowsAllowOnce: Bool {
            self.allowedDecisions.contains(ApprovalDecision.allowOnce.rawValue)
        }

        var allowsAllowAlways: Bool {
            self.allowedDecisions.contains(ApprovalDecision.allowAlways.rawValue)
        }

        var allowsDeny: Bool {
            self.allowedDecisions.contains(ApprovalDecision.deny.rawValue)
        }
    }

    struct ExecApprovalInboxKey: Hashable, Sendable {
        let approvalID: ExecApprovalIdentifier.Key
        let gatewayID: GatewayStableIdentifier.Key
    }

    struct ExecApprovalInboxItem: Identifiable, Equatable {
        let id: ExecApprovalInboxKey
        let prompt: ExecApprovalPrompt
    }

    enum ExecApprovalOutcomeTone: Equatable {
        case success
        case danger
        case warning
        case neutral
    }

    struct ExecApprovalOutcome: Equatable {
        let text: String
        let tone: ExecApprovalOutcomeTone
    }

    struct NotificationPermissionGuidancePrompt: Identifiable, Equatable {
        let id = UUID()
        let approvalId: String
    }

    private struct ExecApprovalPushKey: Hashable {
        let approvalID: ExecApprovalIdentifier.Key
        let gatewayDeviceID: GatewayStableIdentifier.Key?
        let kind: ApprovalKind
    }

    private struct PersistedExecApprovalReadback: Codable, Equatable {
        let approvalId: String
        let gatewayStableID: String
    }

    private struct PersistedExecApprovalReadbackKey: Hashable {
        let approvalID: ExecApprovalIdentifier.Key
        let gatewayID: GatewayStableIdentifier.Key
    }

    private struct PersistedExecApprovalUncertainty: Codable, Equatable {
        let approvalId: String
        let gatewayStableID: String
        let message: String
    }

    private typealias ExecApprovalResolutionKey = ExecApprovalInboxKey

    private struct ExecApprovalResolutionAttempt: Equatable {
        let key: ExecApprovalResolutionKey
        let token: UUID
    }

    private struct ExecApprovalResolutionAttemptState {
        let token: UUID
        var writeInFlight: Bool
    }

    private struct ExecApprovalUncertaintyState {
        let token: UUID
        let message: String
    }

    private struct ExecApprovalReadbackFence {
        let key: ExecApprovalResolutionKey
        let uncertaintyToken: UUID?
    }

    private enum ExecApprovalResolutionOutcome {
        case resolved(ExecApprovalTerminalResult, applied: Bool)
        case pendingRetry(message: String)
        case stale
        case uncertain(message: String)
        case failed(message: String)
    }

    private struct LegacyExecApprovalGetResult: Decodable {
        let id: String
        let commandText: String
        let commandPreview: String?
        let warningText: String?
        let allowedDecisions: [String]
        let host: String?
        let nodeId: String?
        let agentId: String?
        let expiresAtMs: Int64?
    }

    private enum ExecApprovalRPCFamily: Equatable {
        case unified
        case legacy
        case unavailable
    }

    private struct ExecApprovalTerminalResult {
        let id: String
        let kind: ApprovalKind
        let verdict: ExecApprovalTerminalVerdict
        let resolvedAtMs: Int64

        var status: String {
            self.verdict.status
        }

        var decision: String? {
            self.verdict.decision
        }
    }

    private enum ExecApprovalTerminalVerdict {
        case allowOnce
        case allowAlways
        case deny
        case expired
        case cancelled
        case resolvedUnknown

        var status: String {
            switch self {
            case .allowOnce, .allowAlways:
                "allowed"
            case .deny:
                "denied"
            case .expired:
                "expired"
            case .cancelled:
                "cancelled"
            case .resolvedUnknown:
                "resolved"
            }
        }

        var decision: String? {
            switch self {
            case .allowOnce:
                ApprovalDecision.allowOnce.rawValue
            case .allowAlways:
                ApprovalDecision.allowAlways.rawValue
            case .deny:
                ApprovalDecision.deny.rawValue
            case .expired, .cancelled, .resolvedUnknown:
                nil
            }
        }
    }

    private struct GatewaySessionRouteContext {
        let route: GatewayNodeSessionRoute
        let gatewayStableID: String
        let routeGeneration: UInt64
    }

    private struct NodeGatewayLoopContext: Sendable {
        let url: URL
        let stableID: String
        let routeGeneration: UInt64
        let fallbackToken: String?
        let fallbackBootstrapToken: String?
        let fallbackPassword: String?
        let initialOptions: GatewayConnectOptions
        let sessionBox: WebSocketSessionBox?
    }

    private struct NodeGatewayLoopState: Sendable {
        var attempt = 0
        var options: GatewayConnectOptions
        var didFallbackClientID = false
    }

    private enum NodeGatewayLoopStep: Sendable {
        case retry(NodeGatewayLoopState)
        case stop
        case stopPreservingStatus
    }

    private struct APNsRegistrationContext: Sendable {
        let usesRelayTransport: Bool
        let nodeRoute: GatewayNodeSessionRoute
        let token: String
        let gatewayStableID: String
        let topic: String
    }

    private enum ExecApprovalPushRouteValidation {
        case validated(GatewaySessionRouteContext)
        case unavailable
        case mismatchedOwner
    }

    private enum WatchMessageSendOutcome {
        case sent
        case retry
        case discard
    }

    private struct PersistedWatchExecApprovalBridgeState: Codable {
        var approvals: [ExecApprovalPrompt]
        var pendingApprovalReadbacks: [PersistedExecApprovalReadback]?
        var approvalUncertainties: [PersistedExecApprovalUncertainty]?
        var pendingApprovalPushes: [ExecApprovalNotificationPrompt]?
        var pendingResolvedPushes: [ExecApprovalNotificationPrompt]?
        var pendingResolutions: [WatchExecApprovalResolveEvent]?
    }

    private let deepLinkLogger = Logger(subsystem: "ai.novafoundation.app", category: "DeepLink")
    private nonisolated static let agentRequestNodeEventTimeoutSeconds = 8
    private nonisolated static let execApprovalNotificationGuidanceSuppressedKey =
        "notifications.execApprovalGuidance.suppressed"
    private let pushWakeLogger = Logger(subsystem: "ai.novafoundation.app", category: "PushWake")
    private let pendingActionLogger = Logger(subsystem: "ai.novafoundation.app", category: "PendingAction")
    private let locationWakeLogger = Logger(subsystem: "ai.novafoundation.app", category: "LocationWake")
    private let watchReplyLogger = Logger(subsystem: "ai.novafoundation.app", category: "WatchReply")
    private let watchExecApprovalLogger = Logger(subsystem: "ai.novafoundation.app", category: "WatchExecApproval")
    private let execApprovalNotificationLogger = Logger(
        subsystem: "ai.novafoundation.app",
        category: "ExecApprovalNotification")
    enum CameraHUDKind {
        case photo
        case recording
        case success
        case error
    }

    private enum AuxiliaryAudioCapture: Equatable {
        case cameraClip
        case screenRecording
    }

    var isBackgrounded: Bool = false
    let screen: ScreenController
    private let camera: any CameraServicing
    private(set) var preferredCameraFacing: NovaCameraFacing
    private let screenRecorder: any ScreenRecordingServicing
    private var watchGatewayConnectionStatus: NovaWatchAppStatusCode?
    var gatewayStatusText: String = "Offline" {
        didSet {
            self.watchGatewayConnectionStatus = nil
        }
    }

    var nodeStatusText: String = "Offline"
    var operatorStatusText: String = "Offline"
    private(set) var isAppleReviewDemoModeEnabled: Bool = false
    private(set) var isScreenshotFixtureModeEnabled: Bool = false
    var isOperatorGatewayConnected: Bool {
        self.operatorConnected
    }

    private(set) var hasOperatorAdminScope: Bool = false

    var gatewayServerName: String?
    var gatewayRemoteAddress: String?
    var connectedGatewayID: String?
    var gatewayAutoReconnectEnabled: Bool = true
    // When the gateway requires pairing approval, we pause reconnect churn and show a stable UX.
    // Reconnect loops (both our own and the underlying WebSocket watchdog) can otherwise generate
    // multiple pending requests and cause the onboarding UI to "flip-flop".
    var gatewayPairingPaused: Bool = false
    var gatewayPairingRequestId: String?
    // Bumped on every non-nil assignment, including re-reports of an equal problem;
    // value equality alone cannot tell the UI to re-surface a dismissed toast.
    private(set) var gatewayProblemReportCount = 0
    private(set) var lastGatewayProblem: GatewayConnectionProblem? {
        didSet { if self.lastGatewayProblem != nil { self.gatewayProblemReportCount &+= 1 } }
    }

    // Live connection problems drive retry behavior. lastGatewayProblem may outlive both so the UI
    // keeps the previous failure readable while an explicit reconnect starts a fresh attempt.
    private var nodeGatewayProblem: GatewayConnectionProblem?
    private var operatorGatewayProblem: GatewayConnectionProblem?
    var gatewayDisplayStatusText: String {
        self.lastGatewayProblem?.localizedStatusText ?? self.gatewayStatusText
    }

    private var mainSessionBaseKey: String = "main"
    private var gatewaySessionScope: String?
    private var focusedChatSessionKey: String?
    // Two-part unread guard mirroring Android: the opened key survives read
    // confirmations so later unread episodes on the same open chat re-acknowledge;
    // the acknowledged key is the per-episode pending flag.
    @ObservationIgnored private var openedChatSessionKey: String?
    @ObservationIgnored private var readAcknowledgedChatSessionKey: String?
    var selectedAgentId: String?
    var gatewayDefaultAgentId: String?
    var gatewayAgents: [AgentSummary] = []
    var homeCanvasRevision: Int = 0
    var lastShareEventText: String = "No share events yet."
    var openChatRequestID: Int = 0
    var newChatRequestID: Int = 0
    // RootTabs has one chat destination; keep its acknowledgement here so recreating
    // that destination cannot replay a request that the prior view already handled.
    @ObservationIgnored private var consumedNewChatRequestID: Int = 0
    var dashboardNavigationRequestID: Int = 0
    @ObservationIgnored private var consumedDashboardNavigationRequestID: Int = 0
    var gatewaySetupRequestID: Int = 0
    private(set) var pendingAgentDeepLinkPrompt: AgentDeepLinkPrompt?
    private var pendingGatewaySetupLink: GatewayConnectDeepLink?
    private(set) var pendingExecApprovalPrompt: ExecApprovalPrompt?
    private(set) var pendingExecApprovalPromptResolving: Bool = false
    private(set) var pendingExecApprovalPromptErrorText: String?
    // A canonical applied:false winner keeps the prompt visible but freezes its actions.
    private(set) var pendingExecApprovalPromptOutcome: ExecApprovalOutcome?
    var pendingExecApprovalPromptResolvedText: String? {
        self.pendingExecApprovalPromptOutcome?.text
    }

    var pendingExecApprovalInboxItems: [ExecApprovalInboxItem] {
        self.execApprovalInboxPromptsByKey.compactMap { key, prompt in
            guard !self.terminalExecApprovalKeys.contains(key) else { return nil }
            return ExecApprovalInboxItem(id: key, prompt: prompt)
        }.sorted { lhs, rhs in
            let lhsExpires = lhs.prompt.expiresAtMs ?? Int64.max
            let rhsExpires = rhs.prompt.expiresAtMs ?? Int64.max
            if lhsExpires != rhsExpires {
                return lhsExpires < rhsExpires
            }
            if lhs.id.gatewayID != rhs.id.gatewayID {
                return Self.exactStringSortsBefore(
                    lhs.prompt.gatewayStableID,
                    rhs.prompt.gatewayStableID)
            }
            return Self.approvalIDSortsBefore(lhs.prompt.id, rhs.prompt.id)
        }
    }

    var pendingExecApprovalCount: Int {
        self.pendingExecApprovalInboxItems.count
    }

    /// An uncertain resolution keeps approval actions frozen, but must not trap the
    /// reviewer in a modal or Settings detail while canonical readback is unavailable.
    var pendingExecApprovalPromptCanDismiss: Bool {
        !self.pendingExecApprovalPromptResolving || self.pendingExecApprovalPromptErrorText != nil
    }

    private var pendingExecApprovalPromptRequestGeneration: Int = 0
    private var pendingExecApprovalPromptSurfaceGeneration: UInt64 = 0
    private(set) var pendingNotificationPermissionGuidancePrompt: NotificationPermissionGuidancePrompt?
    private var queuedAgentDeepLinkPrompt: AgentDeepLinkPrompt?
    private var lastAgentDeepLinkPromptAt: Date = .distantPast
    @ObservationIgnored private var queuedAgentDeepLinkPromptTask: Task<Void, Never>?

    /// Primary "node" connection: used for device capabilities and node.invoke requests.
    private let nodeGateway = GatewayNodeSession()
    // Secondary "operator" connection: used for chat/talk/config/voicewake requests.
    private let operatorGateway = GatewayNodeSession()
    private var nodeGatewayTask: Task<Void, Never>?
    private var operatorGatewayTask: Task<Void, Never>?
    @ObservationIgnored private var gatewaySessionResetTask: Task<Void, Never>?
    @ObservationIgnored private var gatewaySessionResetGeneration: UInt64 = 0
    @ObservationIgnored private var gatewayRouteGeneration: UInt64 = 0
    @ObservationIgnored private var operatorTalkConnectionGeneration: UInt64 = 0
    @ObservationIgnored private var operatorTalkHydrationGeneration: UInt64?
    @ObservationIgnored private var credentialHandoffFailureGeneration: UInt64?
    @ObservationIgnored private(set) var gatewayConnectGeneration: UInt64 = 0
    private var forceOperatorTalkPermissionUpgradeRequest = false
    @ObservationIgnored private var talkPermissionUpgradeTask: Task<Void, Never>?
    @ObservationIgnored private var talkPermissionUpgradeReconnectTask: Task<Void, Never>?
    private var talkPermissionUpgradeReconnectGeneration: UInt64 = 0
    private var lastTalkPermissionReconnectAttemptAt: Date?
    private var voiceWakeSyncTask: Task<Void, Never>?
    @ObservationIgnored private var cameraHUDDismissTask: Task<Void, Never>?
    @ObservationIgnored private var cameraHUDOwnerID: String?
    @ObservationIgnored private lazy var capabilityRouter: NodeCapabilityRouter = self.buildCapabilityRouter()
    private let gatewayHealthMonitor = GatewayHealthMonitor()
    private var gatewayHealthMonitorDisabled = false
    private let notificationCenter: NotificationCentering
    let voiceWake = VoiceWakeManager()
    let voiceNoteRecorder: NovaVoiceNoteRecorder
    let talkMode: TalkModeManager
    private let locationService: any LocationServicing
    private let deviceStatusService: any DeviceStatusServicing
    private let photosService: any PhotosServicing
    private let contactsService: any ContactsServicing
    private let calendarService: any CalendarServicing
    private let remindersService: any RemindersServicing
    private let motionService: any MotionServicing
    private let healthSummaryService: any HealthSummaryServicing
    private let watchMessagingService: any WatchMessagingServicing
    #if DEBUG
    @ObservationIgnored private var testAgentRequestHandler: ((AgentDeepLink) async throws -> Void)?
    @ObservationIgnored private var testTalkCapturePreparationHandler: (() async -> Void)?
    @ObservationIgnored private var testTalkCaptureStartedHandler: (() async -> Void)?
    @ObservationIgnored private var testChatSessionRoutingRestoreHandler: (() async -> Void)?
    @ObservationIgnored private var testExecApprovalPromptFetchHandler:
        ((String, String) async -> ExecApprovalPromptFetchOutcome)?
    @ObservationIgnored private var testExecApprovalResolutionHandler:
        ((String, ApprovalKind, String, String) async -> ExecApprovalResolutionOutcome)?
    @ObservationIgnored private var testExecApprovalResolutionReconcilesUnknownAck = false
    #endif
    private var pttVoiceWakeLeaseCaptureId: String?
    private var chatDictationCaptureId: String?
    private var talkPttCommandEpoch: UInt64 = 0
    private var chatDictationCommandEpoch: UInt64 = 0
    private(set) var isChatDictationPending = false
    private var talkPreparationInFlight = false
    private var auxiliaryAudioCapture: AuxiliaryAudioCapture?
    private var foregroundCaptureCancellations: [UUID: @MainActor () -> Void] = [:]
    private var talkPreparationWaiters: [(id: UUID, continuation: CheckedContinuation<Bool, Never>)] = []
    private var backgroundTalkKeptActive = false
    private var backgroundedAt: Date?
    private var reconnectAfterBackgroundArmed = false
    private var backgroundGraceTaskID: UIBackgroundTaskIdentifier = .invalid
    @ObservationIgnored private var backgroundGraceTaskTimer: Task<Void, Never>?
    private var backgroundReconnectSuppressed = false
    private var backgroundReconnectLeaseUntil: Date?
    @ObservationIgnored private var foregroundGatewayResumeCheckInFlight = false
    private var lastSignificantLocationWakeAt: Date?
    @ObservationIgnored private let watchMessageOutbox = WatchMessageOutbox()
    @ObservationIgnored private var watchMessageFlushInFlight = false
    @ObservationIgnored private var watchMessageRetryAttempts: [String: Int] = [:]
    @ObservationIgnored private var watchMessageRetryTask: Task<Void, Never>?
    @ObservationIgnored private let appleReviewDemoChatTransport = AppleReviewDemoChatTransport()
    @ObservationIgnored private var clientDatabases: NovaClientDatabases?
    @ObservationIgnored private var chatTranscriptCachesByGatewayID: [String: NovaChatSQLiteTranscriptCache] = [:]
    @ObservationIgnored private var chatSessionRoutingRestoreTask: Task<Void, Never>?
    private var watchExecApprovalPromptsByID: [ExecApprovalIdentifier.Key: ExecApprovalPrompt] = [:]
    private var execApprovalInboxPromptsByKey: [ExecApprovalInboxKey: ExecApprovalPrompt] = [:]
    private var dismissedExecApprovalPresentationKeys: Set<ExecApprovalInboxKey> = []
    private var terminalExecApprovalKeys: Set<ExecApprovalInboxKey> = []
    @ObservationIgnored private var terminalExecApprovalKeyOrder: [ExecApprovalInboxKey] = []
    @ObservationIgnored private var resettableWatchResolutionAttempts:
        [ExecApprovalInboxKey: [ExactOpaqueIdentifierKey: String]] = [:]
    private var pendingPersistedExecApprovalReadbacks: [PersistedExecApprovalReadback] = []
    @ObservationIgnored private var activeExecApprovalResolutionAttempts:
        [ExecApprovalResolutionKey: ExecApprovalResolutionAttemptState] = [:]
    @ObservationIgnored private var execApprovalUncertainties:
        [ExecApprovalResolutionKey: ExecApprovalUncertaintyState] = [:]
    @ObservationIgnored private var pendingWatchExecApprovalResolutionFlushInFlight = false
    private var pendingWatchExecApprovalRecoveryPushes: [ExecApprovalNotificationPrompt] = []
    private var pendingExecApprovalResolvedPushes: [ExecApprovalNotificationPrompt] = []
    private var pendingWatchExecApprovalResolutions: [WatchExecApprovalResolveEvent] = []
    private var pendingForegroundActionDrainInFlight = false
    private var pendingForegroundActionDrainRequested = false
    private var completedPendingForegroundActionIDsByGateway: [String: Set<String>] = [:]

    private var gatewayConnected = false
    private var operatorConnected = false
    private var shareDeliveryChannel: String?
    private var shareDeliveryTo: String?
    private var apnsDeviceTokenHex: String?
    private var apnsLastRegisteredTokenHex: String?
    private var apnsLastRegisteredGatewayStableID: String?
    @ObservationIgnored private let pushRegistrationManager = PushRegistrationManager()

    var operatorSession: GatewayNodeSession {
        self.operatorGateway
    }

    var isTalkCaptureActive: Bool {
        // PTT owns its Voice Wake lease before permission and audio setup.
        // Count that pending interval so Chat cannot race another mic owner.
        self.talkPreparationInFlight ||
            self.talkMode.isEnabled ||
            self.talkMode.isPushToTalkActive ||
            self.pttVoiceWakeLeaseCaptureId != nil
    }

    var isChatDictationActive: Bool {
        self.chatDictationCaptureId != nil
    }

    var localChatFixture: LocalChatFixture? {
        if self.isScreenshotFixtureModeEnabled { return .appScreenshots }
        if self.isAppleReviewDemoModeEnabled { return .appleReviewDemo }
        return nil
    }

    var isLocalChatFixtureEnabled: Bool {
        self.localChatFixture != nil
    }

    var isLocalGatewayFixtureEnabled: Bool {
        self.isAppleReviewDemoModeEnabled || self.isScreenshotFixtureModeEnabled
    }

    var chatTransportModeID: String {
        if self.isScreenshotFixtureModeEnabled { return "screenshots" }
        if self.isAppleReviewDemoModeEnabled { return "apple-review-demo" }
        return self.isOperatorGatewayConnected ? "operator" : "offline"
    }

    func makeChatTransport(outboxGatewayID: String? = nil) -> any NovaChatTransport {
        if self.isScreenshotFixtureModeEnabled {
            return LocalFixtureChatTransport(fixture: .appScreenshots)
        }
        if self.isAppleReviewDemoModeEnabled {
            return AppleReviewDemoChatTransport()
        }
        return IOSGatewayChatTransport(
            gateway: self.operatorSession,
            widgetGateway: self.nodeGateway,
            globalAgentId: self.chatDeliveryAgentId,
            outboxGatewayID: outboxGatewayID)
    }

    /// Gateway identity the transcript cache is scoped to: the active
    /// connection's stableID, or the keychain-persisted active gateway on
    /// cold open before the gateway session is up. Nil for fixture transports
    /// and unpaired installs so demo or foreign rows can never leak into a
    /// real gateway's transcript.
    var chatTranscriptCacheGatewayID: String? {
        guard !self.isLocalGatewayFixtureEnabled else { return nil }
        let stableID = self.activeGatewayConnectConfig?.effectiveStableID
            ?? self.connectedGatewayID
            ?? GatewaySettingsStore.activeGatewayEntry()?.stableID
        guard let stableID, !stableID.isEmpty else { return nil }
        return stableID
    }

    /// Recreation key for the chat view model. Includes the cache gateway
    /// identity: switching paired gateways while the transport mode stays
    /// "operator" must rebuild the view model so transcripts are never read
    /// from or written under another gateway's cache scope.
    var chatViewModelIdentityID: String {
        "\(self.chatTransportModeID)|\(self.chatTranscriptCacheGatewayID ?? "")|\(self.chatTranscriptCacheGeneration)"
    }

    /// Stable owner key for the long-lived chat view model. Connectivity still
    /// changes `chatViewModelIdentityID` for session-list refreshes, but must
    /// not rebuild Chat and discard an offline draft on the same gateway.
    var chatViewModelOwnerID: String {
        let modeID = self.isLocalGatewayFixtureEnabled ? self.chatTransportModeID : "gateway"
        return "\(modeID)|\(self.chatTranscriptCacheGatewayID ?? "")|\(self.chatTranscriptCacheGeneration)"
    }

    private var chatTranscriptCacheGeneration = 0
    private var quarantinedChatOfflineGatewayIDs: Set<String> = []

    /// Gateway-scoped facade over the installation-wide cache and client-state
    /// databases. Nil for fixture/unpaired transports: no cache and no outbox.
    func makeChatOfflineStore() -> NovaChatSQLiteTranscriptCache? {
        guard let gatewayID = self.chatTranscriptCacheGatewayID,
              !self.quarantinedChatOfflineGatewayIDs.contains(gatewayID)
        else { return nil }
        if self.clientDatabases == nil {
            self.clientDatabases = Self.makeClientDatabases()
        }
        guard let clientDatabases else { return nil }
        // The durable marker is authoritative across task suspension and app
        // relaunch. Never expose even an existing facade while cleanup can
        // still delete rows written through it.
        guard !clientDatabases.hasPendingGatewayRemoval(gatewayID: gatewayID) else {
            self.quarantinedChatOfflineGatewayIDs.insert(gatewayID)
            return nil
        }
        if let cache = self.chatTranscriptCachesByGatewayID[gatewayID] {
            return cache
        }
        let cache = clientDatabases.store(gatewayID: gatewayID)
        self.chatTranscriptCachesByGatewayID[gatewayID] = cache
        return cache
    }

    var hasVerifiedChatOfflineRoutingIdentity: Bool {
        self.chatTranscriptCacheGatewayID != nil &&
            self.chatDeliveryAgentId != nil &&
            self.chatSessionRoutingContract != nil
    }

    func restoreChatSessionRoutingIdentityIfNeeded() async {
        guard !self.isLocalGatewayFixtureEnabled,
              self.chatSessionRoutingContract == nil,
              let store = self.makeChatOfflineStore()
        else { return }
        let identity = await store.loadSessionRoutingIdentity()
        #if DEBUG
        if let testChatSessionRoutingRestoreHandler {
            await testChatSessionRoutingRestoreHandler()
        }
        #endif
        guard !Task.isCancelled,
              let identity,
              self.chatTranscriptCacheGatewayID == store.gatewayID,
              self.chatSessionRoutingContract == nil
        else { return }
        self.selectedAgentId = GatewaySettingsStore.loadGatewaySelectedAgentId(stableID: store.gatewayID)
        self.gatewaySessionScope = identity.scope
        self.mainSessionBaseKey = identity.mainSessionKey
        self.gatewayDefaultAgentId = identity.defaultAgentID
        self.synchronizeTalkSessionKey()
        self.homeCanvasRevision &+= 1
    }

    func loadCachedChatSessions() async -> [NovaChatSessionEntry] {
        guard let cache = self.makeChatOfflineStore() else { return [] }
        return await cache.loadSessions()
    }

    func storeCachedChatSessions(_ sessions: [NovaChatSessionEntry]) async {
        guard let cache = self.makeChatOfflineStore() else { return }
        await cache.storeSessions(sessions)
    }

    /// Delete one forgotten gateway's cache and durable state, or both
    /// installation-wide databases during a full onboarding reset.
    func stageChatOfflineDataRemoval(gatewayID: String) async -> Bool {
        if self.clientDatabases == nil {
            self.clientDatabases = Self.makeClientDatabases()
        }
        guard let clientDatabases else { return false }
        do {
            try clientDatabases.stageGatewayRemoval(gatewayID: gatewayID)
            await self.chatTranscriptCachesByGatewayID[gatewayID]?.retire()
            return true
        } catch {
            clientDatabaseLogger.error(
                "gateway removal staging failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func commitChatOfflineDataRemoval(gatewayID: String) -> Bool {
        guard let clientDatabases else { return false }
        do {
            try clientDatabases.commitGatewayRemoval(gatewayID: gatewayID)
            self.quarantinedChatOfflineGatewayIDs.remove(gatewayID)
            self.chatTranscriptCachesByGatewayID.removeValue(forKey: gatewayID)
            self.chatTranscriptCacheGeneration &+= 1
            return true
        } catch {
            clientDatabaseLogger.error(
                "gateway removal commit failed: \(error.localizedDescription, privacy: .public)")
            // The removal may already be irreversible. Keep this gateway
            // quarantined until foreground recovery proves no marker remains.
            self.quarantinedChatOfflineGatewayIDs.insert(gatewayID)
            self.chatTranscriptCachesByGatewayID.removeValue(forKey: gatewayID)
            self.chatTranscriptCacheGeneration &+= 1
            return false
        }
    }

    func cancelChatOfflineDataRemoval(gatewayID: String) {
        guard let clientDatabases else { return }
        do {
            try clientDatabases.cancelGatewayRemoval(gatewayID: gatewayID)
        } catch {
            clientDatabaseLogger.error(
                "gateway removal cancellation failed: \(error.localizedDescription, privacy: .public)")
        }
        // The registry owner did not commit, so cleanup never crossed into the
        // irreversible phase. Repair the retired live facade even if the
        // cancellation transaction or its checkpoint must be retried later.
        self.quarantinedChatOfflineGatewayIDs.remove(gatewayID)
        if self.chatTranscriptCachesByGatewayID[gatewayID] != nil {
            self.chatTranscriptCachesByGatewayID[gatewayID] = clientDatabases.store(gatewayID: gatewayID)
            self.chatTranscriptCacheGeneration &+= 1
        }
    }

    @discardableResult
    func purgeChatTranscriptCache(gatewayID: String? = nil) async -> Bool {
        if let gatewayID, !gatewayID.isEmpty {
            guard await self.stageChatOfflineDataRemoval(gatewayID: gatewayID) else { return false }
            return self.commitChatOfflineDataRemoval(gatewayID: gatewayID)
        }

        // Full reset retires every open handle before removing SQLite sidecars,
        // so deleted transcript bytes cannot survive in WAL or journal pages.
        for cache in self.chatTranscriptCachesByGatewayID.values {
            await cache.retire()
        }
        do {
            try self.clientDatabases?.close()
            self.clientDatabases = nil
            try Self.removeAllChatDatabaseFiles()
        } catch {
            clientDatabaseLogger.error(
                "full database reset failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
        self.chatTranscriptCachesByGatewayID.removeAll()
        self.quarantinedChatOfflineGatewayIDs.removeAll()
        self.chatTranscriptCacheGeneration &+= 1
        return true
    }

    /// Debug launch reset runs before Chat can create a cache actor, so direct
    /// file removal preserves the launch flag's synchronous startup contract.
    func purgeChatTranscriptCacheBeforeStartup() {
        do {
            try self.clientDatabases?.close()
            self.clientDatabases = nil
            try Self.removeAllChatDatabaseFiles()
        } catch {
            clientDatabaseLogger.error(
                "startup database reset failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        self.chatTranscriptCachesByGatewayID.removeAll()
        self.quarantinedChatOfflineGatewayIDs.removeAll()
        self.chatTranscriptCacheGeneration &+= 1
    }

    static func chatDatabaseDirectoryURL() -> URL? {
        try? NovaNodeStorage.appSupportDir()
            .appendingPathComponent("databases", isDirectory: true)
    }

    private static func legacyChatDatabaseDirectoryURL() -> URL? {
        try? NovaNodeStorage.appSupportDir()
            .appendingPathComponent("chat-cache", isDirectory: true)
    }

    private static func removeAllChatDatabaseFiles() throws {
        if let directoryURL = chatDatabaseDirectoryURL() {
            try NovaClientDatabases.removeDatabaseFiles(in: directoryURL)
        }
        if let legacyDirectoryURL = Self.legacyChatDatabaseDirectoryURL(),
           FileManager.default.fileExists(atPath: legacyDirectoryURL.path)
        {
            try FileManager.default.removeItem(at: legacyDirectoryURL)
        }
    }

    private static func makeClientDatabases() -> NovaClientDatabases? {
        guard let directoryURL = chatDatabaseDirectoryURL() else { return nil }
        let legacyDirectories = Self.legacyChatDatabaseDirectoryURL().map { [$0] } ?? []
        do {
            return try NovaClientDatabases(
                directoryURL: directoryURL,
                legacyDirectoryURLs: legacyDirectories,
                registeredGatewayIDs: Set(GatewaySettingsStore.loadGatewayRegistry().entries.map(\.stableID)))
        } catch {
            clientDatabaseLogger.error(
                "client databases unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private(set) var activeGatewayConnectConfig: GatewayConnectConfig?

    private static let watchExecApprovalBridgeStateKey = "watch.execApproval.bridge.state.v1"
    private static let backgroundAliveLastSuccessAtMsKey = "gateway.backgroundAlive.lastSuccessAtMs"
    private static let backgroundAliveLastTriggerKey = "gateway.backgroundAlive.lastTrigger"
    private static let preferredCameraFacingKey = "camera.preferredFacing"
    private static let foregroundResumeHealthTimeoutSeconds = 1
    private static let watchChatCompletionWaitMs = 75000
    private static let watchChatRunWaitSliceMs = 60000

    var cameraHUDText: String?
    var cameraHUDKind: CameraHUDKind?
    var cameraFlashNonce: Int = 0
    var screenRecordActive: Bool = false
    private(set) var watchMessagingStatus = WatchMessagingStatus(
        supported: false,
        paired: false,
        appInstalled: false,
        reachable: false,
        activationState: "notActivated")

    init(
        screen: ScreenController = ScreenController(),
        camera: any CameraServicing = CameraController(),
        screenRecorder: any ScreenRecordingServicing = ScreenRecordService(),
        locationService: any LocationServicing = LocationService(),
        notificationCenter: NotificationCentering = LiveNotificationCenter(),
        deviceStatusService: any DeviceStatusServicing = DeviceStatusService(),
        photosService: any PhotosServicing = PhotoLibraryService(),
        contactsService: any ContactsServicing = ContactsService(),
        calendarService: any CalendarServicing = CalendarService(),
        remindersService: any RemindersServicing = RemindersService(),
        motionService: any MotionServicing = MotionService(),
        healthSummaryService: any HealthSummaryServicing = HealthSummaryService(),
        watchMessagingService: any WatchMessagingServicing = WatchMessagingService(),
        talkMode: TalkModeManager = TalkModeManager(),
        voiceNoteRecorder: NovaVoiceNoteRecorder = NovaVoiceNoteRecorder(),
        audioAdmissionInitiallyAllowed: Bool = true)
    {
        self.screen = screen
        self.camera = camera
        self.preferredCameraFacing = Self.cameraFacingPreference(
            rawValue: UserDefaults.standard.string(forKey: Self.preferredCameraFacingKey))
        self.screenRecorder = screenRecorder
        self.locationService = locationService
        self.notificationCenter = notificationCenter
        self.deviceStatusService = deviceStatusService
        self.photosService = photosService
        self.contactsService = contactsService
        self.calendarService = calendarService
        self.remindersService = remindersService
        self.motionService = motionService
        self.healthSummaryService = healthSummaryService
        self.watchMessagingService = watchMessagingService
        self.talkMode = talkMode
        self.voiceNoteRecorder = voiceNoteRecorder
        if !audioAdmissionInitiallyAllowed {
            // The production scene has not reported its initial phase yet. Keep
            // every microphone owner closed until SwiftUI explicitly admits it.
            self.isBackgrounded = true
            self.voiceWake.setSuppressedForBackground(true)
            self.talkMode.suspendForBackground()
        }
        // Every TalkMode terminal path reports the exact capture after audio
        // teardown; this callback is the single owner of Voice Wake lease release.
        self.talkMode.setPushToTalkAudioOwnershipEndHandler { [weak self] captureId in
            self?.releasePttVoiceWakeLease(for: captureId)
        }
        self.voiceNoteRecorder.setCaptureAdmissionHandler { [weak self] in
            self?.isBackgrounded == false &&
                self?.isTalkCaptureActive == false &&
                self?.auxiliaryAudioCapture == nil
        }
        self.apnsDeviceTokenHex = UserDefaults.standard.string(forKey: Self.apnsDeviceTokenUserDefaultsKey)
        restorePersistedWatchExecApprovalBridgeState()
        GatewayDiagnostics.bootstrap()
        GatewayDiagnostics.log("node app model: init start")
        self.watchMessagingService.setStatusHandler { [weak self] status in
            Task { @MainActor in
                GatewayDiagnostics.log(
                    "node app model: watch status callback "
                        + "reachable=\(status.reachable) activation=\(status.activationState) "
                        + "backgrounded=\(self?.isBackgrounded ?? false)")
                await self?.handleWatchMessagingStatusChanged(status)
            }
        }
        self.watchMessagingService.setReplyHandler { [weak self] event in
            Task { @MainActor in
                await self?.handleWatchQuickReply(event)
            }
        }
        self.watchMessagingService.setExecApprovalResolveHandler { [weak self] event in
            Task { @MainActor in
                _ = await self?.handleWatchExecApprovalResolve(event)
            }
        }
        self.watchMessagingService.setExecApprovalSnapshotRequestHandler { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                GatewayDiagnostics.log(
                    "node app model: watch snapshot request id=\(event.requestId) backgrounded=\(self.isBackgrounded)")
                // A correlated reply is an acknowledgment of canonical readback, not
                // merely receipt. Always reconcile before echoing the Watch request.
                await self.refreshWatchExecApprovalSnapshotOnDemand(
                    reason: "watch_request",
                    requestId: event.requestId,
                    requestGatewayStableID: event.gatewayStableID,
                    heldApprovals: event.heldApprovals)
            }
        }
        self.watchMessagingService.setAppSnapshotRequestHandler { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                GatewayDiagnostics.log(
                    "node app model: watch app snapshot request id=\(event.requestId)")
                await self.syncWatchAppSnapshot(reason: "watch_app_request", includeChat: true)
            }
        }
        self.watchMessagingService.setAppCommandHandler { [weak self] event in
            Task { @MainActor in
                await self?.handleWatchAppCommand(event)
            }
        }

        self.voiceWake.configure { [weak self] cmd in
            guard let self else { return }
            let sessionKey = await MainActor.run { self.mainSessionKey }
            do {
                try await self.sendVoiceTranscript(text: cmd, sessionKey: sessionKey)
            } catch {
                // Best-effort only.
            }
        }
        self.voiceNoteRecorder.onRecordingActiveChanged = { [weak self] isActive in
            self?.voiceWake.setSuppressedByVoiceNote(isActive)
        }

        let enabled = UserDefaults.standard.bool(forKey: "voiceWake.enabled")
        self.voiceWake.setEnabled(enabled)
        self.talkMode.attachGateway(self.operatorGateway)
        refreshOperatorAdminScopeFromStore()
        refreshLastShareEventFromRelay()
        let talkEnabled = UserDefaults.standard.bool(forKey: "talk.enabled")
        self.setTalkEnabled(talkEnabled)
        self.locationService.setAuthorizationChangeHandler { [weak self] status in
            guard let self else { return }
            self.reconcileSignificantLocationMonitoring(
                mode: self.locationMode(),
                authorizationStatus: status)
        }

        // Wire up deep links from canvas taps
        self.screen.onDeepLink = { [weak self] url in
            guard let self else { return }
            Task { @MainActor in
                await self.handleDeepLink(url: url)
            }
        }

        // Wire up A2UI action clicks (buttons, etc.)
        self.screen.onA2UIAction = { [weak self] body in
            guard let self else { return }
            Task { @MainActor in
                await self.handleCanvasA2UIAction(body: body)
            }
        }
    }

    private func handleCanvasA2UIAction(body: [String: Any]) async {
        let userActionAny = body["userAction"] ?? body
        let userAction: [String: Any] = {
            if let dict = userActionAny as? [String: Any] { return dict }
            if let dict = userActionAny as? [AnyHashable: Any] {
                return dict.reduce(into: [String: Any]()) { acc, pair in
                    guard let key = pair.key as? String else { return }
                    acc[key] = pair.value
                }
            }
            return [:]
        }()
        guard !userAction.isEmpty else { return }

        guard let name = NovaCanvasA2UIAction.extractActionName(userAction) else { return }
        let actionId: String = {
            let id = (userAction["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return id.isEmpty ? UUID().uuidString : id
        }()

        let surfaceId: String = {
            let raw = (userAction["surfaceId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? "main" : raw
        }()
        let sourceComponentId: String = {
            let raw = (userAction[
                "sourceComponentId",
            ] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? "-" : raw
        }()

        let host = NodeDisplayName.resolve(
            existing: UserDefaults.standard.string(forKey: "node.displayName"),
            deviceName: UIDevice.current.name,
            interfaceIdiom: UIDevice.current.userInterfaceIdiom)
        let instanceId = (UserDefaults.standard.string(forKey: "node.instanceId") ?? "ios-node").lowercased()
        let contextJSON = NovaCanvasA2UIAction.compactJSON(userAction["context"])
        let sessionKey = mainSessionKey

        let messageContext = NovaCanvasA2UIAction.AgentMessageContext(
            actionName: name,
            session: .init(key: sessionKey, surfaceId: surfaceId),
            component: .init(id: sourceComponentId, host: host, instanceId: instanceId),
            contextJSON: contextJSON)
        let message = NovaCanvasA2UIAction.formatAgentMessage(messageContext)

        let ok: Bool
        var errorText: String?
        if await !isGatewayConnected() {
            ok = false
            errorText = "gateway not connected"
        } else {
            do {
                try await sendAgentRequest(link: AgentDeepLink(
                    message: message,
                    sessionKey: sessionKey,
                    thinking: "low",
                    deliver: false,
                    to: nil,
                    channel: nil,
                    timeoutSeconds: nil,
                    key: actionId))
                ok = true
            } catch {
                ok = false
                errorText = error.localizedDescription
            }
        }

        let js = NovaCanvasA2UIAction.jsDispatchA2UIActionStatus(actionId: actionId, ok: ok, error: errorText)
        do {
            _ = try await self.screen.eval(javaScript: js)
        } catch {
            // ignore
        }
    }

    func setScenePhase(_ phase: ScenePhase) {
        let keepTalkActive = UserDefaults.standard.bool(forKey: "talk.background.enabled")
        GatewayDiagnostics.log("node app model: scene phase=\(String(describing: phase))")
        switch phase {
        case .background:
            self.isBackgrounded = true
            // This durable reason outlives asynchronous PTT/Talk teardown. A
            // late lease release cannot reopen Voice Wake while backgrounded.
            self.voiceWake.setSuppressedForBackground(true)
            // Captures remain owners until cancellation unwinds. Their defers
            // then clear tracking and any auxiliary-audio suppression they own.
            for cancel in self.foregroundCaptureCancellations.values {
                cancel()
            }
            self.stopGatewayHealthMonitor()
            self.backgroundedAt = Date()
            self.reconnectAfterBackgroundArmed = true
            self.beginBackgroundConnectionGracePeriod()
            if self.voiceNoteRecorder.isRecording || self.voiceNoteRecorder.isRequestingPermission {
                // Cancel first: releasing the voice-note suppression reason can
                // schedule Voice Wake, which the background suspension must catch.
                self.voiceNoteRecorder.cancel()
            }
            // Backgrounding invalidates both remote PTT and local dictation preparation.
            // Route and PTT events only advance the remote epoch so they cannot cancel
            // transcription-only permission prompts.
            self.talkPttCommandEpoch &+= 1
            self.chatDictationCommandEpoch &+= 1
            let shouldKeepTalkActive = keepTalkActive && self.talkMode.canKeepContinuousTalkActiveInBackground
            self.backgroundTalkKeptActive = shouldKeepTalkActive
            self.talkMode.suspendForBackground(keepActive: shouldKeepTalkActive)
        case .inactive:
            // Background -> inactive is not foreground admission. iOS passes
            // through this phase before active; keep microphone gates closed.
            break
        case .active:
            self.isBackgrounded = false
            if self.clientDatabases == nil {
                // Recovery must run even after forgetting the final gateway;
                // no chat facade may remain to initialize the container.
                self.clientDatabases = Self.makeClientDatabases()
            }
            let registeredGatewayIDs = Set(
                GatewaySettingsStore.loadGatewayRegistry().entries.map(\.stableID))
            self.clientDatabases?.resolvePendingGatewayRemovals(
                registeredGatewayIDs: registeredGatewayIDs)
            if let clientDatabases = self.clientDatabases {
                let recoveredGatewayIDs = self.quarantinedChatOfflineGatewayIDs.filter {
                    !clientDatabases.hasPendingGatewayRemoval(gatewayID: $0)
                }
                if !recoveredGatewayIDs.isEmpty {
                    self.quarantinedChatOfflineGatewayIDs.subtract(recoveredGatewayIDs)
                    self.chatTranscriptCacheGeneration &+= 1
                }
            }
            self.clientDatabases?.retryLegacyImport(
                registeredGatewayIDs: registeredGatewayIDs)
            self.endBackgroundConnectionGracePeriod(reason: "scene_foreground")
            self.clearBackgroundReconnectSuppression(reason: "scene_foreground")
            var shouldStartGatewayHealthMonitor = self.operatorConnected
            self.voiceWake.setSuppressedForBackground(false)
            let keptActive = self.backgroundTalkKeptActive
            self.backgroundTalkKeptActive = false
            self.talkMode.resumeAfterBackground(wasKeptActive: keptActive)
            Task { [weak self] in
                await self?.resumePendingForegroundNodeActionsIfNeeded(trigger: "scene_active")
            }
            if self.reconnectAfterBackgroundArmed {
                self.reconnectAfterBackgroundArmed = false
                let backgroundedFor = self.backgroundedAt.map { Date().timeIntervalSince($0) } ?? 0
                self.backgroundedAt = nil
                // iOS may suspend network sockets in background without a clean close.
                // On foreground, force a fresh handshake to avoid "connected but dead" states.
                if backgroundedFor >= 3.0 {
                    shouldStartGatewayHealthMonitor = false
                    self.foregroundGatewayResumeCheckInFlight = true
                    Task { [weak self] in
                        guard let self else { return }
                        let operatorWasConnected = await MainActor.run { self.operatorConnected }
                        if operatorWasConnected {
                            // Prefer keeping the connection if it's healthy; reconnect only when needed.
                            let healthy = await (try? self.operatorGateway.request(
                                method: "health",
                                paramsJSON: nil,
                                timeoutSeconds: Self.foregroundResumeHealthTimeoutSeconds)) != nil
                            if healthy {
                                await MainActor.run {
                                    self.foregroundGatewayResumeCheckInFlight = false
                                    self.startGatewayHealthMonitor()
                                }
                                return
                            }
                        }

                        await MainActor.run {
                            self.foregroundGatewayResumeCheckInFlight = false
                        }
                        await self.restartGatewaySessionsAfterForegroundStaleConnection()
                    }
                }
            }
            if shouldStartGatewayHealthMonitor {
                self.startGatewayHealthMonitor()
            }
        @unknown default:
            self.isBackgrounded = false
            self.endBackgroundConnectionGracePeriod(reason: "scene_unknown")
            self.clearBackgroundReconnectSuppression(reason: "scene_unknown")
        }
    }

    private func beginBackgroundConnectionGracePeriod(seconds: TimeInterval = 25) {
        self.grantBackgroundReconnectLease(seconds: seconds, reason: "scene_background_grace")
        self.endBackgroundConnectionGracePeriod(reason: "restart")
        let taskID = UIApplication.shared.beginBackgroundTask(withName: "gateway-background-grace") { [weak self] in
            Task { @MainActor in
                self?.suppressBackgroundReconnect(
                    reason: "background_grace_expired",
                    disconnectIfNeeded: true)
                self?.endBackgroundConnectionGracePeriod(reason: "expired")
            }
        }
        guard taskID != .invalid else {
            self.pushWakeLogger.info("Background grace unavailable: beginBackgroundTask returned invalid")
            return
        }
        self.backgroundGraceTaskID = taskID
        self.pushWakeLogger.info("Background grace started seconds=\(seconds, privacy: .public)")
        self.backgroundGraceTaskTimer = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(max(1, seconds) * 1_000_000_000))
            await MainActor.run {
                self.suppressBackgroundReconnect(reason: "background_grace_timer", disconnectIfNeeded: true)
                self.endBackgroundConnectionGracePeriod(reason: "timer")
            }
        }
    }

    private func endBackgroundConnectionGracePeriod(reason: String) {
        self.backgroundGraceTaskTimer?.cancel()
        self.backgroundGraceTaskTimer = nil
        guard self.backgroundGraceTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(self.backgroundGraceTaskID)
        self.backgroundGraceTaskID = .invalid
        self.pushWakeLogger.info("Background grace ended reason=\(reason, privacy: .public)")
    }

    private func grantBackgroundReconnectLease(seconds: TimeInterval, reason: String) {
        guard self.isBackgrounded else { return }
        let leaseSeconds = max(5, seconds)
        let leaseUntil = Date().addingTimeInterval(leaseSeconds)
        if let existing = backgroundReconnectLeaseUntil, existing > leaseUntil {
            // Keep the longer lease if one is already active.
        } else {
            self.backgroundReconnectLeaseUntil = leaseUntil
        }
        let wasSuppressed = self.backgroundReconnectSuppressed
        self.backgroundReconnectSuppressed = false
        let leaseLogMessage =
            "Background reconnect lease reason=\(reason) "
                + "seconds=\(leaseSeconds) wasSuppressed=\(wasSuppressed)"
        self.pushWakeLogger.info("\(leaseLogMessage, privacy: .public)")
    }

    private func suppressBackgroundReconnect(reason: String, disconnectIfNeeded: Bool) {
        guard self.isBackgrounded else { return }
        let hadLease = self.backgroundReconnectLeaseUntil != nil
        let changed = hadLease || !self.backgroundReconnectSuppressed
        self.backgroundReconnectLeaseUntil = nil
        self.backgroundReconnectSuppressed = true
        guard changed else { return }
        let suppressLogMessage =
            "Background reconnect suppressed reason=\(reason) "
                + "disconnect=\(disconnectIfNeeded)"
        self.pushWakeLogger.info("\(suppressLogMessage, privacy: .public)")
        guard disconnectIfNeeded else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.operatorGateway.disconnect()
            await self.nodeGateway.disconnect()
            await MainActor.run {
                guard !self.isLocalGatewayFixtureEnabled else { return }
                self.setOperatorConnected(false)
                self.gatewayConnected = false
                self.talkMode.updateGatewayConnected(false)
                if self.isBackgrounded {
                    self.gatewayStatusText = "Background idle"
                    LiveActivityManager.shared.endActivity(reason: "background_idle")
                    self.gatewayServerName = nil
                    self.gatewayRemoteAddress = nil
                    self.showLocalCanvasOnDisconnect()
                }
            }
        }
    }

    private func clearBackgroundReconnectSuppression(reason: String) {
        let changed = self.backgroundReconnectSuppressed || self.backgroundReconnectLeaseUntil != nil
        self.backgroundReconnectSuppressed = false
        self.backgroundReconnectLeaseUntil = nil
        guard changed else { return }
        self.pushWakeLogger.info("Background reconnect cleared reason=\(reason, privacy: .public)")
    }

    func setVoiceWakeEnabled(_ enabled: Bool) {
        self.voiceWake.setEnabled(enabled)
        if enabled {
            // If talk is enabled, voice wake should not grab the mic.
            if self.talkMode.isEnabled {
                self.voiceWake.setSuppressedByTalk(true)
            }
        } else {
            self.voiceWake.setSuppressedByTalk(false)
        }
    }

    func setTalkEnabled(_ enabled: Bool) {
        if self.isAppleReviewDemoModeEnabled {
            UserDefaults.standard.set(false, forKey: "talk.enabled")
            self.talkMode.setEnabled(false)
            self.talkMode.statusText = "Demo mode only"
            return
        }
        if enabled, self.auxiliaryAudioCapture != nil {
            UserDefaults.standard.set(false, forKey: "talk.enabled")
            self.talkMode.setEnabled(false)
            self.talkMode.statusText = "Finish the active audio capture first"
            return
        }
        UserDefaults.standard.set(enabled, forKey: "talk.enabled")
        if enabled {
            if self.voiceNoteRecorder.isRecording || self.voiceNoteRecorder.isRequestingPermission {
                self.voiceNoteRecorder.cancel()
            }
            // Voice wake holds the microphone continuously; talk mode needs exclusive access for STT.
            // When talk is enabled from the UI, prioritize talk and pause voice wake.
            self.voiceWake.setSuppressedByTalk(true)
        } else {
            self.voiceWake.setSuppressedByTalk(false)
            self.cancelTalkPermissionUpgrade(
                resumeOperatorGateway: self.forceOperatorTalkPermissionUpgradeRequest)
        }
        self.talkMode.setEnabled(enabled)
        if enabled {
            Task { [weak self] in
                guard let self else { return }
                await self.talkMode.reloadConfig()
                self.requestTalkPermissionUpgradeIfNeeded()
            }
        }
        Task { [weak self] in
            await self?.pushTalkModeToGateway(
                enabled: enabled,
                phase: enabled ? "enabled" : "disabled")
        }
    }

    func setTalkProviderSelection(_ rawValue: String) {
        let selection = TalkModeProviderSelection.resolved(rawValue)
        UserDefaults.standard.set(selection.rawValue, forKey: TalkModeProviderSelection.storageKey)
        self.talkMode.applyProviderSelectionChanged()
    }

    func setTalkRealtimeVoiceSelection(_ rawValue: String) {
        let voice = TalkModeRealtimeVoiceSelection.resolvedOverride(rawValue) ?? ""
        UserDefaults.standard.set(voice, forKey: TalkModeRealtimeVoiceSelection.storageKey)
        self.talkMode.applyProviderSelectionChanged()
    }

    private func requestTalkPermissionUpgrade() {
        if self.forceOperatorTalkPermissionUpgradeRequest {
            guard case .requestFailed = self.talkMode.gatewayTalkPermissionState else { return }
            self.cancelTalkPermissionUpgrade()
        }
        guard let config = activeGatewayConnectConfig else {
            self.talkMode.gatewayTalkPermissionState = .requestFailed("Gateway is not connected")
            self.talkMode.statusText = "Gateway not connected"
            return
        }
        GatewayDiagnostics.log("talk permission upgrade requested")
        self.talkMode.gatewayTalkPermissionState = .requestingUpgrade
        self.talkMode.statusText = "Requesting Talk approval"
        self.forceOperatorTalkPermissionUpgradeRequest = true
        self.gatewayAutoReconnectEnabled = true
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.lastGatewayProblem = nil
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        self.lastTalkPermissionReconnectAttemptAt = Date()
        self.restartOperatorGatewayForTalkPermissionUpgrade(config)
        self.startTalkPermissionUpgradePolling()
    }

    private func restartOperatorGatewayForTalkPermissionUpgrade(_ config: GatewayConnectConfig) {
        self.operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        let sessionBox = config.tls.map { WebSocketSessionBox(session: GatewayTLSPinningSession(params: $0)) }
        let routeGeneration = self.gatewayRouteGeneration
        self.talkPermissionUpgradeReconnectGeneration &+= 1
        let reconnectGeneration = self.talkPermissionUpgradeReconnectGeneration
        self.talkPermissionUpgradeReconnectTask?.cancel()
        self.talkPermissionUpgradeReconnectTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.finishTalkPermissionUpgradeReconnect(generation: reconnectGeneration) }
            await self.operatorGateway.disconnect()
            guard !Task.isCancelled,
                  self.talkMode.isEnabled,
                  self.forceOperatorTalkPermissionUpgradeRequest,
                  self.isCurrentGatewayRoute(
                      generation: routeGeneration,
                      stableID: config.effectiveStableID)
            else { return }
            self.startOperatorGatewayLoop(
                url: config.url,
                stableID: config.effectiveStableID,
                token: config.token,
                bootstrapToken: config.bootstrapToken,
                password: config.password,
                nodeOptions: config.nodeOptions,
                sessionBox: sessionBox)
        }
    }

    private func requestTalkPermissionUpgradeIfNeeded() {
        guard Self.shouldRequestTalkPermissionUpgrade(
            isTalkEnabled: self.talkMode.isEnabled,
            state: self.talkMode.gatewayTalkPermissionState)
        else { return }
        self.requestTalkPermissionUpgrade()
    }

    nonisolated static func shouldRequestTalkPermissionUpgrade(
        isTalkEnabled: Bool,
        state: TalkGatewayPermissionState) -> Bool
    {
        guard isTalkEnabled else { return false }
        return switch state {
        case .missingScope, .requestFailed:
            true
        default:
            false
        }
    }

    private func startTalkPermissionUpgradePolling() {
        self.talkPermissionUpgradeTask?.cancel()
        self.talkPermissionUpgradeTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.pollTalkPermissionUpgrade()
                guard self.talkMode.gatewayTalkPermissionState.isApprovalRequestInProgress else { return }
            }
        }
    }

    private func cancelTalkPermissionUpgrade(resumeOperatorGateway: Bool = false) {
        self.forceOperatorTalkPermissionUpgradeRequest = false
        self.talkPermissionUpgradeTask?.cancel()
        self.talkPermissionUpgradeTask = nil
        self.talkPermissionUpgradeReconnectGeneration &+= 1
        self.talkPermissionUpgradeReconnectTask?.cancel()
        self.talkPermissionUpgradeReconnectTask = nil
        self.lastTalkPermissionReconnectAttemptAt = nil
        guard resumeOperatorGateway, let config = self.activeGatewayConnectConfig else { return }

        // A scope-upgrade attempt can pause the shared operator reconnect loop for approval.
        // Cancelling Talk must replace that attempt with the normal stored-auth connection.
        self.gatewayAutoReconnectEnabled = true
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.clearOperatorGatewayConnectionProblemIfCurrent()
        self.operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        let sessionBox = config.tls.map { WebSocketSessionBox(session: GatewayTLSPinningSession(params: $0)) }
        let routeGeneration = self.gatewayRouteGeneration
        self.talkPermissionUpgradeReconnectGeneration &+= 1
        let reconnectGeneration = self.talkPermissionUpgradeReconnectGeneration
        self.talkPermissionUpgradeReconnectTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.finishTalkPermissionUpgradeReconnect(generation: reconnectGeneration) }
            await self.operatorGateway.disconnect()
            guard !Task.isCancelled,
                  self.isCurrentGatewayRoute(
                      generation: routeGeneration,
                      stableID: config.effectiveStableID)
            else { return }
            self.startOperatorGatewayLoop(
                url: config.url,
                stableID: config.effectiveStableID,
                token: config.token,
                bootstrapToken: config.bootstrapToken,
                password: config.password,
                nodeOptions: config.nodeOptions,
                sessionBox: sessionBox)
        }
    }

    private func pollTalkPermissionUpgrade() async {
        guard self.talkMode.gatewayTalkPermissionState.isApprovalRequestInProgress,
              self.operatorTalkHydrationGeneration == nil
        else { return }
        guard let config = activeGatewayConnectConfig else {
            self.forceOperatorTalkPermissionUpgradeRequest = false
            self.talkMode.gatewayTalkPermissionState = .requestFailed("Gateway is not connected")
            self.talkMode.statusText = "Gateway not connected"
            return
        }

        let now = Date()
        if let lastTalkPermissionReconnectAttemptAt,
           now.timeIntervalSince(lastTalkPermissionReconnectAttemptAt) < 6
        {
            return
        }
        // The operator loop owns handshake retries. Polling only revives a loop
        // that paused for approval; it must never impose a timeout on an active attempt.
        guard Self.shouldRestartTalkPermissionUpgradePoll(
            hasOperatorGatewayTask: self.operatorGatewayTask != nil,
            hasReconnectTask: self.talkPermissionUpgradeReconnectTask != nil)
        else { return }
        GatewayDiagnostics.log("talk permission approval poll reconnect")
        self.lastTalkPermissionReconnectAttemptAt = now
        self.gatewayAutoReconnectEnabled = true
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.restartOperatorGatewayForTalkPermissionUpgrade(config)
    }

    nonisolated static func shouldRestartTalkPermissionUpgradePoll(
        hasOperatorGatewayTask: Bool,
        hasReconnectTask: Bool) -> Bool
    {
        !hasOperatorGatewayTask && !hasReconnectTask
    }

    private func finishTalkPermissionUpgradeReconnect(generation: UInt64) {
        guard self.talkPermissionUpgradeReconnectGeneration == generation else { return }
        self.talkPermissionUpgradeReconnectTask = nil
    }

    func setTalkSpeakerphoneEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: TalkDefaults.speakerphoneEnabledKey)
        self.talkMode.applyAudioRoutePreferenceChanged()
    }

    func requestLocationPermissions(mode: NovaLocationMode) async -> Bool {
        guard mode != .off else {
            self.reconcileSignificantLocationMonitoring(
                mode: mode,
                authorizationStatus: self.locationService.authorizationStatus())
            return true
        }
        let status = await locationService.ensureAuthorization(mode: mode)
        switch status {
        case .authorizedAlways:
            self.reconcileSignificantLocationMonitoring(mode: mode, authorizationStatus: status)
            return true
        case .authorizedWhenInUse:
            self.reconcileSignificantLocationMonitoring(mode: mode, authorizationStatus: status)
            return true
        default:
            self.reconcileSignificantLocationMonitoring(mode: mode, authorizationStatus: status)
            return false
        }
    }

    private func reconcileSignificantLocationMonitoring(
        mode: NovaLocationMode,
        authorizationStatus: CLAuthorizationStatus)
    {
        guard mode == .always, authorizationStatus == .authorizedAlways else {
            self.locationService.setBackgroundLocationUpdatesEnabled(false)
            self.locationService.stopMonitoringSignificantLocationChanges()
            return
        }
        SignificantLocationMonitor.startIfNeeded(
            locationService: self.locationService,
            locationMode: mode,
            gateway: self.nodeGateway,
            beforeSend: { [weak self] in
                await self?.handleSignificantLocationWakeIfNeeded()
            })
    }

    private static let apnsDeviceTokenUserDefaultsKey = "push.apns.deviceTokenHex"
    private static let deepLinkKeyUserDefaultsKey = "deeplink.agent.key"
    private static let canvasUnattendedDeepLinkKey: String = NodeAppModel.generateDeepLinkKey()

    private func refreshBrandingFromGateway(shouldApply: () -> Bool = { true }) async {
        do {
            guard let sourceGatewayID = self.chatTranscriptCacheGatewayID,
                  let sourceRoute = await operatorGateway.currentRoute(ifGatewayID: sourceGatewayID)
            else { return }
            let res = try await operatorGateway.request(
                method: "config.get",
                paramsJSON: "{}",
                timeoutSeconds: 8,
                ifCurrentRoute: sourceRoute)
            guard let json = try JSONSerialization.jsonObject(with: res) as? [String: Any] else { return }
            guard let config = json["config"] as? [String: Any] else { return }
            let session = config["session"] as? [String: Any]
            let mainKey = SessionKey.normalizeMainKey(session?["mainKey"] as? String)
            let scope = (session?["scope"] as? String) ?? "per-sender"
            guard shouldApply(), self.chatTranscriptCacheGatewayID == sourceGatewayID else { return }
            await MainActor.run {
                self.mainSessionBaseKey = mainKey
                self.gatewaySessionScope = scope
                self.synchronizeTalkSessionKey()
                self.homeCanvasRevision &+= 1
            }
        } catch {
            if let gatewayError = error as? GatewayResponseError {
                let lower = gatewayError.message.lowercased()
                if lower.contains("unauthorized role") {
                    return
                }
            }
            // ignore
        }
    }

    private func refreshAgentsFromGateway(shouldApply: () -> Bool = { true }) async {
        do {
            guard let sourceGatewayID = self.chatTranscriptCacheGatewayID,
                  let sourceStore = self.makeChatOfflineStore(),
                  sourceStore.gatewayID == sourceGatewayID,
                  let sourceRoute = await operatorGateway.currentRoute(ifGatewayID: sourceGatewayID)
            else { return }
            let request = NovaChatGatewayRequests.agentsList(timeoutMs: 8000)
            let res = try await operatorGateway.request(
                request,
                ifCurrentRoute: sourceRoute)
            let decoded = try JSONDecoder().decode(AgentsListResult.self, from: res)
            let routingIdentity = NovaChatSessionRoutingIdentity(
                scope: decoded.scope.value as? String,
                mainSessionKey: decoded.mainkey,
                defaultAgentID: decoded.defaultid)
            guard shouldApply(), self.chatTranscriptCacheGatewayID == sourceGatewayID else { return }
            await MainActor.run {
                self.gatewayDefaultAgentId = decoded.defaultid
                self.gatewayAgents = decoded.agents
                self.gatewaySessionScope = decoded.scope.value as? String
                self.applyMainSessionKey(decoded.mainkey)

                let selected = (self.selectedAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !selected.isEmpty, !decoded.agents.contains(where: { $0.id == selected }) {
                    self.selectedAgentId = nil
                    self.focusedChatSessionKey = nil
                }
                self.synchronizeTalkSessionKey()
                self.homeCanvasRevision &+= 1
            }
            if let routingIdentity {
                await sourceStore.storeSessionRoutingIdentity(routingIdentity)
            }
        } catch {
            // Best-effort only.
        }
    }

    func refreshGatewayOverviewIfConnected() async {
        guard await isOperatorConnected() else { return }
        if self.foregroundGatewayResumeCheckInFlight {
            GatewayDiagnostics.log("gateway overview refresh deferred reason=foreground_resume_check")
            try? await Task.sleep(
                nanoseconds: UInt64(Self.foregroundResumeHealthTimeoutSeconds) * 1_000_000_000)
            guard await isOperatorConnected(), !self.foregroundGatewayResumeCheckInFlight else { return }
        }
        await self.refreshBrandingFromGateway()
        await self.refreshAgentsFromGateway()
    }

    func setSelectedAgentId(_ agentId: String?) {
        let trimmed = (agentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nextSelectedAgentId = trimmed.isEmpty ? nil : trimmed
        let currentSelectedAgentId = self.selectedAgentId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedAgentChanged = currentSelectedAgentId != nextSelectedAgentId
        let stableID = GatewayStableIdentifier.exact(self.connectedGatewayID)
        if let stableID {
            self.selectedAgentId = nextSelectedAgentId
            GatewaySettingsStore.saveGatewaySelectedAgentId(
                stableID: stableID,
                agentId: self.selectedAgentId)
        } else {
            self.selectedAgentId = nextSelectedAgentId
        }
        if selectedAgentChanged {
            self.focusedChatSessionKey = nil
        }
        self.synchronizeTalkSessionKey()
        self.homeCanvasRevision &+= 1
        if let relay = ShareGatewayRelaySettings.loadConfig() {
            ShareGatewayRelaySettings.saveConfig(
                ShareGatewayRelayConfig(
                    gatewayURLString: relay.gatewayURLString,
                    gatewayStableID: relay.gatewayStableID,
                    token: relay.token,
                    password: relay.password,
                    sessionKey: mainSessionKey,
                    deliveryChannel: self.shareDeliveryChannel,
                    deliveryTo: self.shareDeliveryTo))
        }
    }

    func setGlobalWakeWords(_ words: [String]) async {
        let sanitized = VoiceWakePreferences.sanitizeTriggerWords(words)

        struct Payload: Codable {
            var triggers: [String]
        }
        let payload = Payload(triggers: sanitized)
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8)
        else { return }

        do {
            _ = try await self.operatorGateway.request(method: "voicewake.set", paramsJSON: json, timeoutSeconds: 12)
        } catch {
            // Best-effort only.
        }
    }

    private func startVoiceWakeSync(shouldContinue: @escaping @MainActor @Sendable () -> Bool = { true }) async {
        guard shouldContinue() else { return }
        self.voiceWakeSyncTask?.cancel()
        self.voiceWakeSyncTask = Task { [weak self] in
            guard let self else { return }

            if !self.isGatewayHealthMonitorDisabled() {
                await self.refreshWakeWordsFromGateway(shouldApply: shouldContinue)
            }
            guard shouldContinue() else { return }

            guard let operatorRoute = await self.operatorGateway.currentRoute(), shouldContinue() else { return }
            let stream = await self.operatorGateway.subscribeServerEvents(bufferingNewest: 200)
            for await evt in stream {
                if Task.isCancelled || !shouldContinue() { return }
                guard evt.payload != nil else { continue }
                await self.handleOperatorGatewayServerEvent(
                    evt,
                    expectedOperatorRoute: operatorRoute,
                    shouldContinue: shouldContinue)
            }
        }
    }

    private func handleOperatorGatewayServerEvent(
        _ evt: EventFrame,
        expectedOperatorRoute: GatewayNodeSessionRoute? = nil,
        shouldContinue: @MainActor @Sendable () -> Bool = { true }) async
    {
        guard shouldContinue(), let payload = evt.payload else { return }
        switch evt.event {
        case "voicewake.changed":
            struct Payload: Decodable { var triggers: [String] }
            guard let decoded = try? GatewayPayloadDecoding.decode(payload, as: Payload.self) else { return }
            let triggers = VoiceWakePreferences.sanitizeTriggerWords(decoded.triggers)
            VoiceWakePreferences.saveTriggerWords(triggers)
        case "talk.mode":
            struct Payload: Decodable {
                var enabled: Bool
                var phase: String?
            }
            guard let decoded = try? GatewayPayloadDecoding.decode(payload, as: Payload.self) else { return }
            self.applyTalkModeSync(enabled: decoded.enabled, phase: decoded.phase)
        case ExecApprovalNotificationBridge.requestedKind:
            guard let approvalId = Self.execApprovalEventID(from: payload) else { return }
            if let gatewayStableID = self.currentExecApprovalGatewayStableID() {
                self.appendPendingPersistedExecApprovalReadback(
                    approvalId: approvalId,
                    gatewayStableID: gatewayStableID)
            }
            await self.presentNotificationPermissionGuidanceForExecApprovalIfNeeded(
                approvalId: approvalId,
                shouldApply: shouldContinue)
            guard shouldContinue() else { return }
            await presentExecApprovalGatewayEventPrompt(
                approvalId: approvalId,
                expectedOperatorRoute: expectedOperatorRoute,
                shouldContinue: shouldContinue)
        case ExecApprovalNotificationBridge.resolvedKind:
            guard let approvalId = Self.execApprovalEventID(from: payload) else { return }
            guard let context = await self.operatorRouteForExecApproval(
                sourceReason: "resolved_event",
                expectedOperatorRoute: expectedOperatorRoute,
                shouldContinue: shouldContinue)
            else {
                self.appendPendingExecApprovalResolvedPush(ExecApprovalNotificationPrompt(
                    approvalId: approvalId,
                    gatewayDeviceId: nil))
                return
            }
            let reconciled = await handleExecApprovalResolvedForCurrentGateway(
                approvalId: approvalId,
                routeContext: context,
                shouldContinue: shouldContinue)
            if !reconciled, shouldContinue() {
                self.appendPendingExecApprovalResolvedPush(ExecApprovalNotificationPrompt(
                    approvalId: approvalId,
                    gatewayDeviceId: nil))
            }
        default:
            return
        }
    }

    private nonisolated static func execApprovalEventID(from payload: AnyCodable) -> String? {
        guard let decoded = try? GatewayPayloadDecoding.decode(
            payload,
            as: ExecApprovalGatewayEventPayload.self)
        else {
            return nil
        }
        return Self.validatedApprovalID(decoded.id)
    }

    private nonisolated static func validatedApprovalID(_ id: String) -> String? {
        ExecApprovalIdentifier.exact(id)
    }

    private nonisolated static func execApprovalIDKey(_ id: String) -> ExecApprovalIdentifier.Key? {
        ExecApprovalIdentifier.key(id)
    }

    private nonisolated static func approvalIDsMatch(_ lhs: String, _ rhs: String) -> Bool {
        ExecApprovalIdentifier.matches(lhs, rhs)
    }

    private nonisolated static func approvalIDSortsBefore(_ lhs: String, _ rhs: String) -> Bool {
        ExecApprovalIdentifier.sortsBefore(lhs, rhs)
    }

    private nonisolated static func execApprovalResolutionKey(
        approvalID: String,
        gatewayStableID: String) -> ExecApprovalResolutionKey?
    {
        guard let approvalID = ExecApprovalIdentifier.key(approvalID),
              let gatewayID = GatewayStableIdentifier.key(gatewayStableID)
        else { return nil }
        return ExecApprovalResolutionKey(
            approvalID: approvalID,
            gatewayID: gatewayID)
    }

    static func execApprovalInboxKey(
        approvalID: String,
        gatewayStableID: String?) -> ExecApprovalInboxKey?
    {
        guard let gatewayStableID else { return nil }
        return self.execApprovalResolutionKey(
            approvalID: approvalID,
            gatewayStableID: gatewayStableID)
    }

    static func execApprovalInboxKey(_ prompt: ExecApprovalPrompt?) -> ExecApprovalInboxKey? {
        guard let prompt else { return nil }
        return self.execApprovalInboxKey(
            approvalID: prompt.id,
            gatewayStableID: prompt.gatewayStableID)
    }

    private func beginExecApprovalResolutionAttempt(
        approvalID: String,
        gatewayStableID: String) -> ExecApprovalResolutionAttempt?
    {
        guard let key = Self.execApprovalResolutionKey(
            approvalID: approvalID,
            gatewayStableID: gatewayStableID),
            self.activeExecApprovalResolutionAttempts[key] == nil,
            self.execApprovalUncertainties[key] == nil,
            !self.terminalExecApprovalKeys.contains(key)
        else { return nil }
        let attempt = ExecApprovalResolutionAttempt(key: key, token: UUID())
        self.activeExecApprovalResolutionAttempts[key] = ExecApprovalResolutionAttemptState(
            token: attempt.token,
            writeInFlight: true)
        return attempt
    }

    private func isActiveExecApprovalResolutionAttempt(
        _ attempt: ExecApprovalResolutionAttempt) -> Bool
    {
        self.activeExecApprovalResolutionAttempts[attempt.key]?.token == attempt.token
    }

    private func markExecApprovalResolutionWriteSettled(
        _ attempt: ExecApprovalResolutionAttempt)
    {
        guard var state = self.activeExecApprovalResolutionAttempts[attempt.key],
              state.token == attempt.token
        else { return }
        state.writeInFlight = false
        self.activeExecApprovalResolutionAttempts[attempt.key] = state
    }

    private func finishExecApprovalResolutionAttempt(
        _ attempt: ExecApprovalResolutionAttempt)
    {
        guard self.isActiveExecApprovalResolutionAttempt(attempt) else { return }
        self.activeExecApprovalResolutionAttempts.removeValue(forKey: attempt.key)
        guard !self.pendingWatchExecApprovalResolutions.isEmpty else { return }
        Task { @MainActor [weak self] in
            await Task.yield()
            await self?.flushPendingWatchExecApprovalResolutions()
        }
    }

    private func markExecApprovalResolutionUncertain(
        approvalID: String,
        gatewayStableID: String,
        message: String)
    {
        guard let key = Self.execApprovalResolutionKey(
            approvalID: approvalID,
            gatewayStableID: gatewayStableID),
            !self.terminalExecApprovalKeys.contains(key)
        else { return }
        // A lost write response is neither pending nor terminal truth. Keep this exact
        // owner frozen across dismissal until approval.get classifies it canonically.
        self.execApprovalUncertainties[key] = ExecApprovalUncertaintyState(
            token: UUID(),
            message: message)
        let readback = PersistedExecApprovalReadback(
            approvalId: approvalID,
            gatewayStableID: gatewayStableID)
        if !self.pendingPersistedExecApprovalReadbacks.contains(where: {
            Self.persistedExecApprovalReadbackKey($0) == PersistedExecApprovalReadbackKey(
                approvalID: key.approvalID,
                gatewayID: key.gatewayID)
        }) {
            self.pendingPersistedExecApprovalReadbacks.append(readback)
            self.pendingPersistedExecApprovalReadbacks.sort(
                by: Self.persistedExecApprovalReadbackSortsBefore)
        }
        self.persistWatchExecApprovalBridgeState()
        guard Self.execApprovalInboxKey(self.pendingExecApprovalPrompt) == key else { return }
        self.pendingExecApprovalPromptResolving = true
        self.pendingExecApprovalPromptErrorText = message
        self.pendingExecApprovalPromptOutcome = nil
    }

    private func recordCanonicalExecApprovalFetchOutcome(
        _ outcome: ExecApprovalPromptFetchOutcome,
        fence: ExecApprovalReadbackFence?) -> ExecApprovalPromptFetchOutcome
    {
        guard case let .loaded(prompt) = outcome,
              let promptKey = Self.execApprovalInboxKey(prompt),
              let fence,
              promptKey == fence.key,
              let uncertaintyToken = fence.uncertaintyToken,
              self.execApprovalUncertainties[promptKey]?.token == uncertaintyToken
        else { return outcome }
        self.execApprovalUncertainties.removeValue(forKey: promptKey)
        self.pendingPersistedExecApprovalReadbacks.removeAll {
            Self.persistedExecApprovalReadbackKey($0) == PersistedExecApprovalReadbackKey(
                approvalID: promptKey.approvalID,
                gatewayID: promptKey.gatewayID)
        }
        self.persistWatchExecApprovalBridgeState()
        self.schedulePendingWatchExecApprovalResolutionFlush()
        return outcome
    }

    private func execApprovalReadbackFence(approvalID: String) -> ExecApprovalReadbackFence? {
        guard let gatewayStableID = self.currentExecApprovalGatewayStableID(),
              let key = Self.execApprovalResolutionKey(
                  approvalID: approvalID,
                  gatewayStableID: gatewayStableID)
        else { return nil }
        return ExecApprovalReadbackFence(
            key: key,
            uncertaintyToken: self.execApprovalUncertainties[key]?.token)
    }

    private func schedulePendingWatchExecApprovalResolutionFlush() {
        guard !self.pendingWatchExecApprovalResolutions.isEmpty else { return }
        Task { @MainActor [weak self] in
            await Task.yield()
            await self?.flushPendingWatchExecApprovalResolutions()
        }
    }

    private func isExecApprovalResolutionWriteInFlight(
        approvalID: String,
        gatewayStableID: String) -> Bool
    {
        guard let key = Self.execApprovalResolutionKey(
            approvalID: approvalID,
            gatewayStableID: gatewayStableID)
        else { return false }
        return self.activeExecApprovalResolutionAttempts[key]?.writeInFlight == true
    }

    /// True while the owner-scoped attempt lease is held, including the readback window
    /// after the write settled but before the outer defer releases the lease. New
    /// resolution attempts are rejected for that whole span, not just while writing.
    private func hasActiveExecApprovalResolutionAttempt(
        approvalID: String,
        gatewayStableID: String) -> Bool
    {
        guard let key = Self.execApprovalResolutionKey(
            approvalID: approvalID,
            gatewayStableID: gatewayStableID)
        else { return false }
        return self.activeExecApprovalResolutionAttempts[key] != nil
    }

    private func markWatchResolutionAttemptResettable(
        _ event: WatchExecApprovalResolveEvent)
    {
        guard let key = Self.execApprovalInboxKey(
            approvalID: event.approvalId,
            gatewayStableID: event.gatewayStableID),
            let attemptKey = ExactOpaqueIdentifier.key(event.replyId)
        else { return }
        var attempts = self.resettableWatchResolutionAttempts[key] ?? [:]
        attempts[attemptKey] = event.replyId
        if attempts.count > 8,
           let evictedKey = attempts.keys.min(by: { lhs, rhs in
               Self.exactStringSortsBefore(lhs.rawValue, rhs.rawValue)
           })
        {
            attempts.removeValue(forKey: evictedKey)
        }
        self.resettableWatchResolutionAttempts[key] = attempts
    }

    private func resettableWatchResolutionAttemptID(
        for prompt: ExecApprovalPrompt,
        heldAttemptID: String?) -> String?
    {
        guard let key = Self.execApprovalInboxKey(prompt),
              self.activeExecApprovalResolutionAttempts[key] == nil,
              let heldAttemptKey = ExactOpaqueIdentifier.key(heldAttemptID),
              let recordedAttemptID = self.resettableWatchResolutionAttempts[key]?[heldAttemptKey]
        else { return nil }
        return recordedAttemptID
    }

    private nonisolated static func exactStringSortsBefore(_ lhs: String, _ rhs: String) -> Bool {
        Array(lhs.utf8).lexicographicallyPrecedes(Array(rhs.utf8))
    }

    private nonisolated static func execApprovalPushSortsBefore(
        _ lhs: ExecApprovalNotificationPrompt,
        _ rhs: ExecApprovalNotificationPrompt) -> Bool
    {
        if lhs.kind != rhs.kind {
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
        let lhsGatewayID = lhs.gatewayDeviceId ?? ""
        let rhsGatewayID = rhs.gatewayDeviceId ?? ""
        let lhsGatewayBytes = Array(lhsGatewayID.utf8)
        let rhsGatewayBytes = Array(rhsGatewayID.utf8)
        if lhsGatewayBytes != rhsGatewayBytes {
            return lhsGatewayBytes.lexicographicallyPrecedes(rhsGatewayBytes)
        }
        return self.approvalIDSortsBefore(lhs.approvalId, rhs.approvalId)
    }

    private nonisolated static func execApprovalPushKey(
        _ push: ExecApprovalNotificationPrompt) -> ExecApprovalPushKey?
    {
        guard let approvalID = self.execApprovalIDKey(push.approvalId) else { return nil }
        let gatewayDeviceID: GatewayStableIdentifier.Key?
        if let rawGatewayDeviceID = push.gatewayDeviceId {
            guard let exactGatewayDeviceID = GatewayStableIdentifier.key(rawGatewayDeviceID) else { return nil }
            gatewayDeviceID = exactGatewayDeviceID
        } else {
            gatewayDeviceID = nil
        }
        return ExecApprovalPushKey(
            approvalID: approvalID,
            gatewayDeviceID: gatewayDeviceID,
            kind: push.kind)
    }

    private nonisolated static func persistedExecApprovalReadbackKey(
        _ readback: PersistedExecApprovalReadback) -> PersistedExecApprovalReadbackKey?
    {
        guard let approvalID = ExecApprovalIdentifier.key(readback.approvalId),
              let gatewayID = GatewayStableIdentifier.key(readback.gatewayStableID)
        else { return nil }
        return PersistedExecApprovalReadbackKey(
            approvalID: approvalID,
            gatewayID: gatewayID)
    }

    private nonisolated static func persistedExecApprovalReadbackSortsBefore(
        _ lhs: PersistedExecApprovalReadback,
        _ rhs: PersistedExecApprovalReadback) -> Bool
    {
        if !GatewayStableIdentifier.matches(lhs.gatewayStableID, rhs.gatewayStableID) {
            return self.exactStringSortsBefore(lhs.gatewayStableID, rhs.gatewayStableID)
        }
        return self.approvalIDSortsBefore(lhs.approvalId, rhs.approvalId)
    }

    private nonisolated static func persistedExecApprovalUncertaintyKey(
        _ uncertainty: PersistedExecApprovalUncertainty) -> ExecApprovalResolutionKey?
    {
        self.execApprovalResolutionKey(
            approvalID: uncertainty.approvalId,
            gatewayStableID: uncertainty.gatewayStableID)
    }

    private nonisolated static func persistedExecApprovalUncertaintySortsBefore(
        _ lhs: PersistedExecApprovalUncertainty,
        _ rhs: PersistedExecApprovalUncertainty) -> Bool
    {
        if !GatewayStableIdentifier.matches(lhs.gatewayStableID, rhs.gatewayStableID) {
            return self.exactStringSortsBefore(lhs.gatewayStableID, rhs.gatewayStableID)
        }
        return self.approvalIDSortsBefore(lhs.approvalId, rhs.approvalId)
    }

    private func applyTalkModeSync(enabled: Bool, phase: String?) {
        _ = phase
        guard self.talkMode.isEnabled != enabled else { return }
        self.setTalkEnabled(enabled)
    }

    private func pushTalkModeToGateway(enabled: Bool, phase: String?) async {
        guard await isOperatorConnected() else { return }
        struct TalkModePayload: Encodable {
            var enabled: Bool
            var phase: String?
        }
        let payload = TalkModePayload(enabled: enabled, phase: phase)
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8)
        else { return }
        _ = try? await self.operatorGateway.request(
            method: "talk.mode",
            paramsJSON: json,
            timeoutSeconds: 8)
    }

    private func startGatewayHealthMonitor() {
        self.gatewayHealthMonitorDisabled = false
        self.gatewayHealthMonitor.start(
            check: { [weak self] in
                guard let self else { return false }
                if await MainActor.run(body: { self.isGatewayHealthMonitorDisabled() }) { return true }
                do {
                    let data = try await self.operatorGateway.request(
                        method: "health",
                        paramsJSON: nil,
                        timeoutSeconds: 6)
                    guard let decoded = try? JSONDecoder().decode(NovaGatewayHealthOK.self, from: data) else {
                        return false
                    }
                    return decoded.ok ?? false
                } catch {
                    if let gatewayError = error as? GatewayResponseError,
                       gatewayError.isAuthorizationFailure
                    {
                        await self.setGatewayHealthMonitorDisabled(true)
                        return true
                    }
                    return false
                }
            },
            onFailure: { [weak self] _ in
                guard let self else { return }
                await self.operatorGateway.disconnect()
                await self.nodeGateway.disconnect()
                await MainActor.run {
                    guard !self.isLocalGatewayFixtureEnabled else { return }
                    self.setOperatorConnected(false)
                    self.gatewayConnected = false
                    self.setGatewayConnectionProgress(reconnecting: true)
                    self.talkMode.updateGatewayConnected(false)
                }
            })
    }

    private func stopGatewayHealthMonitor() {
        self.gatewayHealthMonitor.stop()
    }

    private func handleInvoke(
        _ req: BridgeInvokeRequest,
        gatewayStableID: String? = nil) async -> BridgeInvokeResponse
    {
        let command = req.command

        if self.isBackgrounded, self.isBackgroundRestricted(command) {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .backgroundUnavailable,
                    message: "NODE_BACKGROUND_UNAVAILABLE: canvas/camera/screen/talk commands require foreground"))
        }

        if command.hasPrefix("camera."), !isCameraEnabled() {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .unavailable,
                    message: "CAMERA_DISABLED: enable Camera in iOS Settings → Camera → Allow Camera"))
        }

        do {
            return try await self.capabilityRouter.handle(
                Self.scopedWatchNotificationRequest(req, gatewayStableID: gatewayStableID))
        } catch let error as NodeCapabilityRouter.RouterError {
            switch error {
            case .unknownCommand:
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
            case .handlerUnavailable:
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(code: .unavailable, message: "node handler unavailable"))
            }
        } catch is CancellationError {
            if command.hasPrefix("camera.") {
                self.clearCameraHUD(ownerID: req.id)
            }
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .unavailable, message: "node invoke cancelled"))
        } catch {
            if command.hasPrefix("camera.") {
                let text = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                self.updateCameraHUD(ownerID: req.id, text: text, kind: .error, autoHideSeconds: 2.2)
            }
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .unavailable, message: error.localizedDescription))
        }
    }

    private static func scopedWatchNotificationRequest(
        _ req: BridgeInvokeRequest,
        gatewayStableID: String?) -> BridgeInvokeRequest
    {
        guard req.command == NovaWatchCommand.notify.rawValue,
              var params = try? decodeParams(NovaWatchNotifyParams.self, from: req.paramsJSON)
        else { return req }
        // Gateway identity comes from the installed node route, never the request payload.
        params.gatewayStableID = trimmedOrNil(gatewayStableID)
        guard let paramsJSON = try? encodePayload(params) else { return req }
        return BridgeInvokeRequest(
            type: req.type,
            id: req.id,
            command: req.command,
            paramsJSON: paramsJSON,
            nodeId: req.nodeId)
    }

    private func isBackgroundRestricted(_ command: String) -> Bool {
        command.hasPrefix("canvas.") || command.hasPrefix("camera.") || command.hasPrefix("screen.") ||
            command.hasPrefix("talk.")
    }

    private func handleLocationInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let mode = locationMode()
        guard mode != .off else {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .unavailable,
                    message: "LOCATION_DISABLED: enable Location in Settings"))
        }
        if self.isBackgrounded, mode != .always {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .backgroundUnavailable,
                    message: "LOCATION_BACKGROUND_UNAVAILABLE: background location requires Always"))
        }
        let params = (try? Self.decodeParams(NovaLocationGetParams.self, from: req.paramsJSON)) ??
            NovaLocationGetParams()
        let desired = params.desiredAccuracy ??
            (isLocationPreciseEnabled() ? .precise : .balanced)
        let status = self.locationService.authorizationStatus()
        if status != .authorizedAlways, status != .authorizedWhenInUse {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .unavailable,
                    message: "LOCATION_PERMISSION_REQUIRED: grant Location permission"))
        }
        if self.isBackgrounded, status != .authorizedAlways {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .unavailable,
                    message: "LOCATION_PERMISSION_REQUIRED: enable Always for background access"))
        }
        let location = try await locationService.currentLocation(
            params: params,
            desiredAccuracy: desired,
            maxAgeMs: params.maxAgeMs,
            timeoutMs: params.timeoutMs)
        let isPrecise = self.locationService.accuracyAuthorization() == .fullAccuracy
        let payload = NovaLocationPayload(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            accuracyMeters: location.horizontalAccuracy,
            altitudeMeters: location.verticalAccuracy >= 0 ? location.altitude : nil,
            speedMps: location.speed >= 0 ? location.speed : nil,
            headingDeg: location.course >= 0 ? location.course : nil,
            timestamp: ISO8601DateFormatter().string(from: location.timestamp),
            isPrecise: isPrecise,
            source: nil)
        let json = try Self.encodePayload(payload)
        return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
    }

    private func handleCanvasInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaCanvasCommand.present.rawValue:
            // iOS ignores placement hints; canvas always fills the screen.
            let params = (try? Self.decodeParams(NovaCanvasPresentParams.self, from: req.paramsJSON)) ??
                NovaCanvasPresentParams()
            let url = params.url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if url.isEmpty {
                self.screen.presentDefaultCanvas()
            } else {
                self.screen.present(urlString: url)
            }
            return BridgeInvokeResponse(id: req.id, ok: true)
        case NovaCanvasCommand.hide.rawValue:
            self.screen.hideCanvas()
            return BridgeInvokeResponse(id: req.id, ok: true)
        case NovaCanvasCommand.navigate.rawValue:
            let params = try Self.decodeParams(NovaCanvasNavigateParams.self, from: req.paramsJSON)
            let trimmedURL = params.url.trimmingCharacters(in: .whitespacesAndNewlines)
            self.screen.present(urlString: trimmedURL)
            return BridgeInvokeResponse(id: req.id, ok: true)
        case NovaCanvasCommand.evalJS.rawValue:
            let params = try Self.decodeParams(NovaCanvasEvalParams.self, from: req.paramsJSON)
            let result = try await screen.eval(javaScript: params.javaScript)
            let payload = try Self.encodePayload(["result": result])
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
        case NovaCanvasCommand.snapshot.rawValue:
            let params = try? Self.decodeParams(NovaCanvasSnapshotParams.self, from: req.paramsJSON)
            let format = params?.format ?? .jpeg
            let maxWidth: CGFloat? = {
                if let raw = params?.maxWidth, raw > 0 { return CGFloat(raw) }
                // Keep default snapshots comfortably below the gateway client's maxPayload.
                // For full-res, clients should explicitly request a larger maxWidth.
                return switch format {
                case .png: 900
                case .jpeg: 1600
                }
            }()
            let base64 = try await screen.snapshotBase64(
                maxWidth: maxWidth,
                format: format,
                quality: params?.quality)
            let payload = try Self.encodePayload([
                "format": format == .jpeg ? "jpeg" : "png",
                "base64": base64,
            ])
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleCanvasA2UIInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let command = req.command
        switch command {
        case NovaCanvasA2UICommand.reset.rawValue:
            switch await ensureA2UIReadyWithCapabilityRefresh(timeoutMs: 5000) {
            case .ready:
                break
            case .hostUnavailable:
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(
                        code: .unavailable,
                        message: "A2UI_HOST_UNAVAILABLE: bundled A2UI host not reachable"))
            }
            let json = try await screen.eval(javaScript: """
            (() => {
              const host = globalThis.novaA2UI;
              if (!host) return JSON.stringify({ ok: false, error: "missing novaA2UI" });
              return JSON.stringify(host.reset());
            })()
            """)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)

        case NovaCanvasA2UICommand.push.rawValue, NovaCanvasA2UICommand.pushJSONL.rawValue:
            let messages: [NovaKit.AnyCodable]
            if command == NovaCanvasA2UICommand.pushJSONL.rawValue {
                let params = try Self.decodeParams(NovaCanvasA2UIPushJSONLParams.self, from: req.paramsJSON)
                messages = try NovaCanvasA2UIJSONL.decodeMessagesFromJSONL(params.jsonl)
            } else {
                do {
                    let params = try Self.decodeParams(NovaCanvasA2UIPushParams.self, from: req.paramsJSON)
                    messages = params.messages
                } catch {
                    // Be forgiving: some clients still send JSONL payloads to `canvas.a2ui.push`.
                    let params = try Self.decodeParams(NovaCanvasA2UIPushJSONLParams.self, from: req.paramsJSON)
                    messages = try NovaCanvasA2UIJSONL.decodeMessagesFromJSONL(params.jsonl)
                }
            }

            switch await ensureA2UIReadyWithCapabilityRefresh(timeoutMs: 5000) {
            case .ready:
                break
            case .hostUnavailable:
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(
                        code: .unavailable,
                        message: "A2UI_HOST_UNAVAILABLE: bundled A2UI host not reachable"))
            }

            let messagesJSON = try NovaCanvasA2UIJSONL.encodeMessagesJSONArray(messages)
            let js = """
            (() => {
              try {
                const host = globalThis.novaA2UI;
                if (!host) return JSON.stringify({ ok: false, error: "missing novaA2UI" });
                const messages = \(messagesJSON);
                return JSON.stringify(host.applyMessages(messages));
              } catch (e) {
                return JSON.stringify({ ok: false, error: String(e?.message ?? e) });
              }
            })()
            """
            let resultJSON = try await screen.eval(javaScript: js)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: resultJSON)

        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleCameraInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaCameraCommand.list.rawValue:
            let devices = await camera.listDevices()
            struct Payload: Codable {
                var devices: [CameraController.CameraDeviceInfo]
            }
            let payload = try Self.encodePayload(Payload(devices: devices))
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
        case NovaCameraCommand.snap.rawValue:
            showCameraHUD(ownerID: req.id, text: "Taking photo…", kind: .photo)
            triggerCameraFlash()
            let params = (try? Self.decodeParams(NovaCameraSnapParams.self, from: req.paramsJSON)) ??
                NovaCameraSnapParams()
            let defaultFacing = self.preferredCameraFacing
            let res = try await self.withForegroundCapture {
                try await self.camera.snap(
                    params: params,
                    defaultFacing: defaultFacing)
            }

            struct Payload: Codable {
                var format: String
                var base64: String
                var width: Int
                var height: Int
            }
            try Task.checkCancellation()
            let payload = try Self.encodePayload(Payload(
                format: res.format,
                base64: res.base64,
                width: res.width,
                height: res.height))
            try Task.checkCancellation()
            updateCameraHUD(ownerID: req.id, text: "Photo captured", kind: .success, autoHideSeconds: 1.6)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
        case NovaCameraCommand.clip.rawValue:
            let params = (try? Self.decodeParams(NovaCameraClipParams.self, from: req.paramsJSON)) ??
                NovaCameraClipParams()

            let includeAudio = params.includeAudio ?? true
            let defaultFacing = self.preferredCameraFacing
            showCameraHUD(ownerID: req.id, text: "Recording…", kind: .recording)
            let res = try await self.withForegroundCapture(
                audioOwner: includeAudio ? .cameraClip : nil)
            {
                try await self.camera.clip(
                    params: params,
                    defaultFacing: defaultFacing)
            }

            struct Payload: Codable {
                var format: String
                var base64: String
                var durationMs: Int
                var hasAudio: Bool
            }
            try Task.checkCancellation()
            let payload = try Self.encodePayload(Payload(
                format: res.format,
                base64: res.base64,
                durationMs: res.durationMs,
                hasAudio: res.hasAudio))
            try Task.checkCancellation()
            updateCameraHUD(ownerID: req.id, text: "Clip captured", kind: .success, autoHideSeconds: 1.8)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleScreenRecordInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let params = (try? Self.decodeParams(NovaScreenRecordParams.self, from: req.paramsJSON)) ??
            NovaScreenRecordParams()
        if let format = params.format, format.lowercased() != "mp4" {
            throw NSError(domain: "Screen", code: 30, userInfo: [
                NSLocalizedDescriptionKey: "INVALID_REQUEST: screen format must be mp4",
            ])
        }
        let includeAudio = params.includeAudio ?? true
        guard !self.screenRecordActive else {
            throw NSError(domain: "Screen", code: 31, userInfo: [
                NSLocalizedDescriptionKey: "SCREEN_CAPTURE_BUSY: screen recording already active",
            ])
        }
        // Status pill mirrors screen recording state so it stays visible without overlay stacking.
        self.screenRecordActive = true
        defer { self.screenRecordActive = false }
        let data = try await self.withForegroundCapture(
            audioOwner: includeAudio ? .screenRecording : nil)
        {
            let path = try await self.screenRecorder.record(
                screenIndex: params.screenIndex,
                durationMs: params.durationMs,
                fps: params.fps,
                includeAudio: params.includeAudio,
                outPath: nil)
            defer { try? FileManager().removeItem(atPath: path) }
            return try Data(contentsOf: URL(fileURLWithPath: path))
        }
        struct Payload: Codable {
            var format: String
            var base64: String
            var durationMs: Int?
            var fps: Double?
            var screenIndex: Int?
            var hasAudio: Bool
        }
        let payload = try Self.encodePayload(Payload(
            format: "mp4",
            base64: data.base64EncodedString(),
            durationMs: params.durationMs,
            fps: params.fps,
            screenIndex: params.screenIndex,
            hasAudio: includeAudio))
        return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: payload)
    }

    private func handleSystemNotify(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let params = try Self.decodeParams(NovaSystemNotifyParams.self, from: req.paramsJSON)
        let title = params.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = params.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty, body.isEmpty {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: empty notification"))
        }

        let status = await notificationAuthorizationStatus()
        guard Self.isNotificationServingEnabled(status) else {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .unavailable, message: "NOT_AUTHORIZED: notifications"))
        }

        let addResult = await runNotificationCall(timeoutSeconds: 2.0) { [notificationCenter] in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if #available(iOS 15.0, *) {
                switch params.priority ?? .active {
                case .passive:
                    content.interruptionLevel = .passive
                case .timeSensitive:
                    content.interruptionLevel = .timeSensitive
                case .active:
                    content.interruptionLevel = .active
                }
            }
            let soundValue = params.sound?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let soundValue, ["none", "silent", "off", "false", "0"].contains(soundValue) {
                content.sound = nil
            } else {
                content.sound = .default
            }
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil)
            try await notificationCenter.add(request)
        }
        if case let .failure(error) = addResult {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .unavailable, message: "NOTIFICATION_FAILED: \(error.message)"))
        }
        return BridgeInvokeResponse(id: req.id, ok: true)
    }

    private func handleChatPushInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let params = try Self.decodeParams(NovaChatPushParams.self, from: req.paramsJSON)
        let text = params.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: empty chat.push text"))
        }

        let shouldSpeak = params.speak ?? true
        let status = await notificationAuthorizationStatus()
        let notificationsAllowed = Self.isNotificationServingEnabled(status)
        if !notificationsAllowed, !shouldSpeak {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .unavailable, message: "NOT_AUTHORIZED: notifications"))
        }

        let messageId = UUID().uuidString
        if notificationsAllowed {
            let addResult = await runNotificationCall(timeoutSeconds: 2.0) { [notificationCenter] in
                let content = UNMutableNotificationContent()
                content.title = "Nova"
                content.body = text
                content.sound = .default
                content.userInfo = ["messageId": messageId]
                let request = UNNotificationRequest(
                    identifier: messageId,
                    content: content,
                    trigger: nil)
                try await notificationCenter.add(request)
            }
            if case let .failure(error) = addResult {
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(code: .unavailable, message: "NOTIFICATION_FAILED: \(error.message)"))
            }
        }

        if shouldSpeak {
            let toSpeak = text
            Task { @MainActor in
                try? await TalkSystemSpeechSynthesizer.shared.speak(text: toSpeak)
            }
        }

        let payload = NovaChatPushPayload(messageId: messageId)
        let json = try Self.encodePayload(payload)
        return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
    }

    private func notificationAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let result = await runNotificationCall(timeoutSeconds: 1.5) { [notificationCenter] in
            await notificationCenter.authorizationStatus()
        }
        switch result {
        case let .success(status):
            return status
        case .failure:
            return .denied
        }
    }

    private static func isNotificationAuthorizationAllowed(
        _ status: NotificationAuthorizationStatus) -> Bool
    {
        switch status {
        case .authorized, .provisional, .ephemeral:
            true
        case .denied, .notDetermined:
            false
        }
    }

    private static func isNotificationServingEnabled(
        _ status: NotificationAuthorizationStatus) -> Bool
    {
        NotificationServingPreference.isEnabled() && self.isNotificationAuthorizationAllowed(status)
    }

    private func presentNotificationPermissionGuidanceForExecApprovalIfNeeded(
        approvalId: String,
        shouldApply: @MainActor @Sendable () -> Bool = { true }) async
    {
        guard shouldApply(), !self.execApprovalNotificationGuidanceSuppressed else { return }
        let status = await notificationAuthorizationStatus()
        guard shouldApply(), !Self.isNotificationAuthorizationAllowed(status) else { return }
        self.pendingNotificationPermissionGuidancePrompt =
            NotificationPermissionGuidancePrompt(approvalId: approvalId)
    }

    var execApprovalNotificationGuidanceSuppressed: Bool {
        UserDefaults.standard.bool(forKey: Self.execApprovalNotificationGuidanceSuppressedKey)
    }

    func dismissNotificationPermissionGuidancePrompt(suppressFuture: Bool) {
        if suppressFuture {
            UserDefaults.standard.set(true, forKey: Self.execApprovalNotificationGuidanceSuppressedKey)
        }
        self.pendingNotificationPermissionGuidancePrompt = nil
    }

    func resetExecApprovalNotificationGuidanceSuppression() {
        UserDefaults.standard.removeObject(forKey: Self.execApprovalNotificationGuidanceSuppressedKey)
    }

    private func runNotificationCall<T: Sendable>(
        timeoutSeconds: Double,
        operation: @escaping @Sendable () async throws -> T) async -> Result<T, NotificationCallError>
    {
        let latch = NotificationInvokeLatch<T>()
        var opTask: Task<Void, Never>?
        var timeoutTask: Task<Void, Never>?
        defer {
            opTask?.cancel()
            timeoutTask?.cancel()
        }
        let clamped = max(0.0, timeoutSeconds)
        return await withCheckedContinuation { (cont: CheckedContinuation<Result<T, NotificationCallError>, Never>) in
            latch.setContinuation(cont)
            opTask = Task { @MainActor in
                do {
                    let value = try await operation()
                    latch.resume(.success(value))
                } catch {
                    latch.resume(.failure(NotificationCallError(message: error.localizedDescription)))
                }
            }
            timeoutTask = Task.detached {
                if clamped > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(clamped * 1_000_000_000))
                }
                latch.resume(.failure(NotificationCallError(message: "notification request timed out")))
            }
        }
    }

    private func handleDeviceInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaDeviceCommand.status.rawValue:
            let payload = try await deviceStatusService.status()
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaDeviceCommand.info.rawValue:
            let payload = self.deviceStatusService.info()
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handlePhotosInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        let params = (try? Self.decodeParams(NovaPhotosLatestParams.self, from: req.paramsJSON)) ??
            NovaPhotosLatestParams()
        let payload = try await photosService.latest(params: params)
        let json = try Self.encodePayload(payload)
        return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
    }

    private func handleContactsInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaContactsCommand.search.rawValue:
            let params = (try? Self.decodeParams(NovaContactsSearchParams.self, from: req.paramsJSON)) ??
                NovaContactsSearchParams()
            let payload = try await contactsService.search(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaContactsCommand.add.rawValue:
            let params = try Self.decodeParams(NovaContactsAddParams.self, from: req.paramsJSON)
            let payload = try await contactsService.add(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleCalendarInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaCalendarCommand.events.rawValue:
            let params = (try? Self.decodeParams(NovaCalendarEventsParams.self, from: req.paramsJSON)) ??
                NovaCalendarEventsParams()
            let payload = try await calendarService.events(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaCalendarCommand.add.rawValue:
            let params = try Self.decodeParams(NovaCalendarAddParams.self, from: req.paramsJSON)
            let payload = try await calendarService.add(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleRemindersInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaRemindersCommand.list.rawValue:
            let params = (try? Self.decodeParams(NovaRemindersListParams.self, from: req.paramsJSON)) ??
                NovaRemindersListParams()
            let payload = try await remindersService.list(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaRemindersCommand.add.rawValue:
            let params = try Self.decodeParams(NovaRemindersAddParams.self, from: req.paramsJSON)
            let payload = try await remindersService.add(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleMotionInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaMotionCommand.activity.rawValue:
            let params = (try? Self.decodeParams(NovaMotionActivityParams.self, from: req.paramsJSON)) ??
                NovaMotionActivityParams()
            let payload = try await motionService.activities(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaMotionCommand.pedometer.rawValue:
            let params = (try? Self.decodeParams(NovaPedometerParams.self, from: req.paramsJSON)) ??
                NovaPedometerParams()
            let payload = try await motionService.pedometer(params: params)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    private func handleHealthInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        guard let params = try? Self.decodeParams(NovaHealthSummaryParams.self, from: req.paramsJSON) else {
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(
                    code: .invalidRequest,
                    message: "INVALID_REQUEST: period must be today"))
        }
        let payload = try await self.healthSummaryService.summary(params: params)
        let json = try Self.encodePayload(payload)
        return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
    }

    private func handleTalkInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        try Task.checkCancellation()
        switch req.command {
        case NovaTalkCommand.pttStart.rawValue:
            let commandEpoch = self.talkPttCommandEpoch
            var reservedCaptureId: String?
            do {
                let payload = try await self.withTalkCapturePreparation(
                    owner: .remotePushToTalk(epoch: commandEpoch))
                {
                    try self.rejectTalkCaptureWhileOtherAudioActive()
                    return try await self.talkMode.beginPushToTalk(
                        canStartCapture: {
                            self.talkPttCommandEpoch == commandEpoch && !self.isBackgrounded
                        },
                        onCaptureReserved: { captureId in
                            reservedCaptureId = captureId
                            self.acquirePttVoiceWakeLease(for: captureId)
                        })
                }
                #if DEBUG
                if let testTalkCaptureStartedHandler {
                    await testTalkCaptureStartedHandler()
                }
                #endif
                try self.ensureTalkPttStartCurrent(commandEpoch, captureId: payload.captureId)
                let json = try Self.encodePayload(payload)
                try self.ensureTalkPttStartCurrent(commandEpoch, captureId: payload.captureId)
                return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
            } catch {
                if let reservedCaptureId {
                    _ = self.talkMode.cancelPushToTalk(captureId: reservedCaptureId)
                }
                throw error
            }
        case NovaTalkCommand.pttOnce.rawValue:
            let commandEpoch = self.talkPttCommandEpoch
            var reservedCaptureId: String?
            let start: TalkPushToTalkOnceStart
            do {
                start = try await self.withTalkCapturePreparation(
                    owner: .remotePushToTalk(epoch: commandEpoch))
                {
                    try self.rejectTalkCaptureWhileOtherAudioActive()
                    return try await self.talkMode.beginPushToTalkOnce(
                        canStartCapture: {
                            self.talkPttCommandEpoch == commandEpoch && !self.isBackgrounded
                        },
                        onCaptureReserved: { captureId in
                            reservedCaptureId = captureId
                            self.acquirePttVoiceWakeLease(for: captureId)
                        })
                }
            } catch {
                if let reservedCaptureId {
                    _ = self.talkMode.cancelPushToTalk(captureId: reservedCaptureId)
                }
                throw error
            }
            let payload: NovaTalkPTTStopPayload = switch start {
            case let .busy(busyPayload):
                busyPayload
            case .started:
                await self.talkMode.awaitPushToTalkOnce(start)
            }
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaTalkCommand.pttStop.rawValue:
            // Interrupt commands invalidate suspended preparation before touching
            // capture state, then bypass the preparation queue entirely.
            self.talkPttCommandEpoch &+= 1
            let payload = self.talkMode.endPushToTalk(expectedTranscriptionOnly: false)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaTalkCommand.pttCancel.rawValue:
            self.talkPttCommandEpoch &+= 1
            let payload = self.talkMode.cancelPushToTalk(expectedTranscriptionOnly: false)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    /// Captures one locally recognized utterance for the chat draft. Unlike
    /// remote PTT, this returns text without starting an agent turn or TTS.
    func transcribeChatDraft() async throws -> String? {
        guard !self.isChatDictationPending, self.chatDictationCaptureId == nil else { return nil }
        self.isChatDictationPending = true
        defer { self.isChatDictationPending = false }

        let commandEpoch = self.chatDictationCommandEpoch
        var reservedCaptureId: String?
        let start: TalkPushToTalkOnceStart
        do {
            start = try await self.withTalkCapturePreparation(
                owner: .chatDictation(epoch: commandEpoch))
            {
                try self.rejectTalkCaptureWhileOtherAudioActive()
                return try await self.talkMode.beginPushToTalkOnce(
                    maxDurationSeconds: 30,
                    transcriptionOnly: true,
                    canStartCapture: {
                        self.chatDictationCommandEpoch == commandEpoch && !self.isBackgrounded
                    },
                    onCaptureReserved: { captureId in
                        self.isChatDictationPending = false
                        reservedCaptureId = captureId
                        self.chatDictationCaptureId = captureId
                        self.acquirePttVoiceWakeLease(for: captureId)
                    })
            }
        } catch {
            self.cancelChatDictationReservation(reservedCaptureId)
            throw error
        }

        guard case let .started(captureId) = start else {
            self.cancelChatDictationReservation(reservedCaptureId)
            return nil
        }
        guard reservedCaptureId == captureId else {
            self.cancelChatDictationReservation(reservedCaptureId)
            if reservedCaptureId != captureId {
                _ = self.talkMode.cancelPushToTalk(captureId: captureId)
            }
            return nil
        }

        let payload = await self.talkMode.awaitPushToTalkOnce(start)
        // Dictation may be cancelled while recognition is suspended. Only the
        // invocation that still owns this capture may publish its transcript.
        guard payload.captureId == captureId,
              self.chatDictationCaptureId == captureId
        else {
            if self.chatDictationCaptureId == captureId {
                self.chatDictationCaptureId = nil
            }
            return nil
        }
        self.chatDictationCaptureId = nil
        return payload.transcript?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cancelChatDictationReservation(_ captureId: String?) {
        guard let captureId else { return }
        _ = self.talkMode.cancelPushToTalk(captureId: captureId)
        if self.chatDictationCaptureId == captureId {
            self.chatDictationCaptureId = nil
        }
    }

    func finishChatDictation() {
        guard let captureId = self.chatDictationCaptureId else { return }
        _ = self.talkMode.endPushToTalk(captureId: captureId)
    }

    func cancelChatDictation() {
        // Cancellation must also invalidate permission/preparation work before a
        // capture ID exists, or a dismissed dictation can start recording later.
        self.chatDictationCommandEpoch &+= 1
        // The suspended starter owns the pending flag. Keep it set until that task
        // unwinds so another start cannot overlap the cancelled preparation.
        guard let captureId = self.chatDictationCaptureId else { return }
        _ = self.talkMode.cancelPushToTalk(captureId: captureId)
        self.chatDictationCaptureId = nil
    }

    private func rejectTalkCaptureWhileOtherAudioActive() throws {
        // Remote PTT bypasses the Chat Talk toggle. Preserve the user's draft;
        // Talk must not reconfigure AVAudioSession while its recorder owns it.
        if self.voiceNoteRecorder.isRecording || self.voiceNoteRecorder.isRequestingPermission {
            throw NSError(domain: "TalkMode", code: 8, userInfo: [
                NSLocalizedDescriptionKey: "Finish or cancel the active voice note before starting push-to-talk.",
            ])
        }
        if self.auxiliaryAudioCapture != nil {
            throw NSError(domain: "TalkMode", code: 8, userInfo: [
                NSLocalizedDescriptionKey: "Finish the active audio capture before starting push-to-talk.",
            ])
        }
    }

    private func acquireAuxiliaryAudioCapture(_ owner: AuxiliaryAudioCapture) throws {
        guard self.auxiliaryAudioCapture == nil,
              !self.isBackgrounded,
              !self.isTalkCaptureActive,
              !self.voiceNoteRecorder.isRecording,
              !self.voiceNoteRecorder.isRequestingPermission
        else {
            throw NSError(domain: "AudioCapture", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Finish the active audio capture before starting another one.",
            ])
        }
        self.auxiliaryAudioCapture = owner
        self.voiceWake.setSuppressedForAuxiliaryAudio(true)
    }

    private func releaseAuxiliaryAudioCapture(_ owner: AuxiliaryAudioCapture) {
        guard self.auxiliaryAudioCapture == owner else { return }
        self.auxiliaryAudioCapture = nil
        self.voiceWake.setSuppressedForAuxiliaryAudio(false)
    }

    private func withForegroundCapture<T: Sendable>(
        audioOwner: AuxiliaryAudioCapture? = nil,
        operation: @escaping @MainActor () async throws -> T) async throws -> T
    {
        try self.ensureForegroundCaptureAllowed()
        if let audioOwner {
            try self.acquireAuxiliaryAudioCapture(audioOwner)
        }
        let captureTask = Task {
            try Task.checkCancellation()
            let result = try await operation()
            try Task.checkCancellation()
            return result
        }
        let captureId = UUID()
        self.foregroundCaptureCancellations[captureId] = { captureTask.cancel() }
        defer {
            self.foregroundCaptureCancellations.removeValue(forKey: captureId)
            if let audioOwner {
                self.releaseAuxiliaryAudioCapture(audioOwner)
            }
        }

        return try await withTaskCancellationHandler {
            try await captureTask.value
        } onCancel: {
            captureTask.cancel()
        }
    }

    private func ensureForegroundCaptureAllowed() throws {
        guard !self.isBackgrounded else {
            throw NSError(domain: "AudioCapture", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "NODE_BACKGROUND_UNAVAILABLE: camera and screen capture require foreground",
            ])
        }
    }

    private func acquirePttVoiceWakeLease(for captureId: String) {
        guard self.pttVoiceWakeLeaseCaptureId != captureId else { return }
        self.pttVoiceWakeLeaseCaptureId = captureId
        // The suppression reason outlives Voice Wake enable/disable toggles,
        // so enabling it mid-capture cannot open a competing audio pipeline.
        self.voiceWake.setSuppressedByPushToTalk(true)
    }

    private func releasePttVoiceWakeLease(for captureId: String) {
        guard self.pttVoiceWakeLeaseCaptureId == captureId else { return }
        self.pttVoiceWakeLeaseCaptureId = nil
        // Capture identity makes stale stop/cancel cleanup harmless. Resume Voice
        // Wake only after the live capture owner releases its lease.
        self.voiceWake.setSuppressedByPushToTalk(false)
    }

    private func withTalkCapturePreparation<T>(
        owner: TalkCapturePreparationOwner,
        operation: () async throws -> T) async throws -> T
    {
        try await self.acquireTalkPreparation()
        defer { self.releaseTalkPreparation() }
        try self.ensureTalkCapturePreparationCurrent(owner)
        #if DEBUG
        if let testTalkCapturePreparationHandler {
            await testTalkCapturePreparationHandler()
        }
        #endif
        try self.ensureTalkCapturePreparationCurrent(owner)
        return try await operation()
    }

    private func ensureTalkCapturePreparationCurrent(_ owner: TalkCapturePreparationOwner) throws {
        switch owner {
        case let .remotePushToTalk(epoch):
            try self.ensureTalkPttCommandCurrent(epoch)
        case let .chatDictation(epoch):
            try Task.checkCancellation()
            guard self.chatDictationCommandEpoch == epoch, !self.isBackgrounded else {
                throw NSError(domain: "TalkMode", code: 9, userInfo: [
                    NSLocalizedDescriptionKey: "DICTATION_CANCELLED: chat dictation start was cancelled",
                ])
            }
        }
    }

    private func ensureTalkPttCommandCurrent(_ commandEpoch: UInt64) throws {
        try Task.checkCancellation()
        guard self.talkPttCommandEpoch == commandEpoch, !self.isBackgrounded else {
            throw NSError(domain: "TalkMode", code: 9, userInfo: [
                NSLocalizedDescriptionKey: "PTT_CANCELLED: push-to-talk start was cancelled",
            ])
        }
    }

    private func ensureTalkPttStartCurrent(_ commandEpoch: UInt64, captureId: String) throws {
        try self.ensureTalkPttCommandCurrent(commandEpoch)
        guard self.talkMode.isActivePushToTalkCapture(captureId) else {
            throw NSError(domain: "TalkMode", code: 9, userInfo: [
                NSLocalizedDescriptionKey: "PTT_CANCELLED: push-to-talk start was cancelled",
            ])
        }
    }

    private func acquireTalkPreparation() async throws {
        if !self.talkPreparationInFlight {
            try Task.checkCancellation()
            self.talkPreparationInFlight = true
            return
        }
        let waiterID = UUID()
        let acquired = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(returning: false)
                    return
                }
                self.talkPreparationWaiters.append((id: waiterID, continuation: continuation))
            }
        } onCancel: {
            Task { @MainActor in
                self.cancelTalkPreparationWaiter(id: waiterID)
            }
        }
        guard acquired else {
            try Task.checkCancellation()
            return
        }
        do {
            try Task.checkCancellation()
        } catch {
            self.releaseTalkPreparation()
            throw error
        }
    }

    private func cancelTalkPreparationWaiter(id: UUID) {
        guard let index = self.talkPreparationWaiters.firstIndex(where: { $0.id == id }) else { return }
        self.talkPreparationWaiters.remove(at: index).continuation.resume(returning: false)
    }

    private func releaseTalkPreparation() {
        guard !self.talkPreparationWaiters.isEmpty else {
            self.talkPreparationInFlight = false
            return
        }
        self.talkPreparationWaiters.removeFirst().continuation.resume(returning: true)
    }
}

extension NodeAppModel {
    /// Central registry for node invoke routing to keep commands in one place.
    private func buildCapabilityRouter() -> NodeCapabilityRouter {
        var handlers: [String: NodeCapabilityRouter.Handler] = [:]

        func register(_ commands: [String], handler: @escaping NodeCapabilityRouter.Handler) {
            for command in commands {
                handlers[command] = handler
            }
        }

        register([NovaLocationCommand.get.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleLocationInvoke(req)
        }

        register([
            NovaCanvasCommand.present.rawValue,
            NovaCanvasCommand.hide.rawValue,
            NovaCanvasCommand.navigate.rawValue,
            NovaCanvasCommand.evalJS.rawValue,
            NovaCanvasCommand.snapshot.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleCanvasInvoke(req)
        }

        register([
            NovaCanvasA2UICommand.reset.rawValue,
            NovaCanvasA2UICommand.push.rawValue,
            NovaCanvasA2UICommand.pushJSONL.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleCanvasA2UIInvoke(req)
        }

        register([
            NovaCameraCommand.list.rawValue,
            NovaCameraCommand.snap.rawValue,
            NovaCameraCommand.clip.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleCameraInvoke(req)
        }

        register([NovaScreenCommand.record.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleScreenRecordInvoke(req)
        }

        register([NovaSystemCommand.notify.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleSystemNotify(req)
        }

        register([NovaChatCommand.push.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleChatPushInvoke(req)
        }

        register([
            NovaDeviceCommand.status.rawValue,
            NovaDeviceCommand.info.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleDeviceInvoke(req)
        }

        register([
            NovaWatchCommand.status.rawValue,
            NovaWatchCommand.notify.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleWatchInvoke(req)
        }

        register([NovaPhotosCommand.latest.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handlePhotosInvoke(req)
        }

        register([
            NovaContactsCommand.search.rawValue,
            NovaContactsCommand.add.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleContactsInvoke(req)
        }

        register([
            NovaCalendarCommand.events.rawValue,
            NovaCalendarCommand.add.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleCalendarInvoke(req)
        }

        register([
            NovaRemindersCommand.list.rawValue,
            NovaRemindersCommand.add.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleRemindersInvoke(req)
        }

        register([
            NovaMotionCommand.activity.rawValue,
            NovaMotionCommand.pedometer.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleMotionInvoke(req)
        }

        register([NovaHealthCommand.summary.rawValue]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleHealthInvoke(req)
        }

        register([
            NovaTalkCommand.pttStart.rawValue,
            NovaTalkCommand.pttStop.rawValue,
            NovaTalkCommand.pttCancel.rawValue,
            NovaTalkCommand.pttOnce.rawValue,
        ]) { [weak self] req in
            guard let self else { throw NodeCapabilityRouter.RouterError.handlerUnavailable }
            return try await self.handleTalkInvoke(req)
        }

        return NodeCapabilityRouter(handlers: handlers)
    }

    private func handleWatchInvoke(_ req: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
        switch req.command {
        case NovaWatchCommand.status.rawValue:
            let status = await watchMessagingService.status()
            let payload = NovaWatchStatusPayload(
                supported: status.supported,
                paired: status.paired,
                appInstalled: status.appInstalled,
                reachable: status.reachable,
                activationState: status.activationState)
            let json = try Self.encodePayload(payload)
            return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
        case NovaWatchCommand.notify.rawValue:
            let params = try Self.decodeParams(NovaWatchNotifyParams.self, from: req.paramsJSON)
            let normalizedParams = Self.normalizeWatchNotifyParams(params)
            let title = normalizedParams.title
            let body = normalizedParams.body
            if title.isEmpty, body.isEmpty {
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(
                        code: .invalidRequest,
                        message: "INVALID_REQUEST: empty watch notification"))
            }
            do {
                let gatewayStableID = currentWatchChatGatewayStableID()
                self.watchMessageOutbox.recordPromptRoute(
                    promptID: normalizedParams.promptId,
                    gatewayStableID: gatewayStableID)
                let result = try await watchMessagingService.sendNotification(
                    id: req.id,
                    params: normalizedParams,
                    gatewayStableID: gatewayStableID)
                if result.queuedForDelivery || !result.deliveredImmediately {
                    let invokeID = req.id
                    Task { @MainActor in
                        await WatchPromptNotificationBridge.scheduleMirroredWatchPromptNotificationIfNeeded(
                            invokeID: invokeID,
                            params: normalizedParams,
                            gatewayStableID: gatewayStableID,
                            sendResult: result)
                    }
                }
                let payload = NovaWatchNotifyPayload(
                    deliveredImmediately: result.deliveredImmediately,
                    queuedForDelivery: result.queuedForDelivery,
                    transport: result.transport)
                let json = try Self.encodePayload(payload)
                return BridgeInvokeResponse(id: req.id, ok: true, payloadJSON: json)
            } catch {
                return BridgeInvokeResponse(
                    id: req.id,
                    ok: false,
                    error: NovaNodeError(
                        code: .unavailable,
                        message: error.localizedDescription))
            }
        default:
            return BridgeInvokeResponse(
                id: req.id,
                ok: false,
                error: NovaNodeError(code: .invalidRequest, message: "INVALID_REQUEST: unknown command"))
        }
    }

    func sendDirectWatchSetup() async throws -> WatchNotificationSendResult {
        struct SetupCodeResponse: Decodable {
            var setupCode: String
        }

        guard self.isOperatorGatewayConnected else {
            throw NSError(domain: "WatchDirectSetup", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Connect the iPhone to a Gateway first.",
            ])
        }
        guard self.hasOperatorAdminScope else {
            throw NSError(domain: "WatchDirectSetup", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "The iPhone connection needs operator.admin access.",
            ])
        }
        let status = await watchMessagingService.status()
        guard status.supported, status.paired, status.appInstalled else {
            throw NSError(domain: "WatchDirectSetup", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Pair an Apple Watch and install the Nova watch app first.",
            ])
        }

        let response = try await operatorGateway.request(
            method: "device.pair.setupCode",
            paramsJSON: #"{"includeQr":false,"bootstrapProfile":"node"}"#,
            timeoutSeconds: 20)
        let setup = try JSONDecoder().decode(SetupCodeResponse.self, from: response)
        guard let setupLink = GatewayConnectDeepLink.fromSetupCode(setup.setupCode),
              setupLink.connectionEndpoints.contains(where: \.tls)
        else {
            throw NSError(domain: "WatchDirectSetup", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Direct Apple Watch mode requires a trusted HTTPS Gateway endpoint.",
            ])
        }
        return try await self.watchMessagingService.sendDirectNodeSetup(setupCode: setup.setupCode)
    }

    func refreshWatchMessagingStatus() async {
        self.watchMessagingStatus = await self.watchMessagingService.status()
    }

    private func locationMode() -> NovaLocationMode {
        let raw = UserDefaults.standard.string(forKey: "location.enabledMode") ?? "off"
        return NovaLocationMode(rawValue: raw) ?? .off
    }

    private func isLocationPreciseEnabled() -> Bool {
        // iOS settings now expose a single location mode control.
        // Default location tool precision stays high unless a command explicitly requests balanced.
        true
    }

    fileprivate static func decodeParams<T: Decodable>(_ type: T.Type, from json: String?) throws -> T {
        guard let json, let data = json.data(using: .utf8) else {
            throw NSError(domain: "Gateway", code: 20, userInfo: [
                NSLocalizedDescriptionKey: "INVALID_REQUEST: paramsJSON required",
            ])
        }
        return try JSONDecoder().decode(type, from: data)
    }

    fileprivate static func encodePayload(_ obj: some Encodable) throws -> String {
        let data = try JSONEncoder().encode(obj)
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw NSError(domain: "NodeAppModel", code: 21, userInfo: [
                NSLocalizedDescriptionKey: "Failed to encode payload as UTF-8",
            ])
        }
        return json
    }

    private func isCameraEnabled() -> Bool {
        // Default-on: if the key doesn't exist yet, treat it as enabled.
        if UserDefaults.standard.object(forKey: "camera.enabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "camera.enabled")
    }

    nonisolated static func cameraFacingPreference(rawValue: String?) -> NovaCameraFacing {
        rawValue.flatMap(NovaCameraFacing.init(rawValue:)) ?? .front
    }

    func setPreferredCameraFacing(_ facing: NovaCameraFacing) {
        guard self.preferredCameraFacing != facing else { return }
        self.preferredCameraFacing = facing
        UserDefaults.standard.set(facing.rawValue, forKey: Self.preferredCameraFacingKey)
    }

    func flipPreferredCameraFacing() {
        self.setPreferredCameraFacing(self.preferredCameraFacing == .front ? .back : .front)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func triggerCameraFlash() {
        self.cameraFlashNonce &+= 1
    }

    private func showCameraHUD(
        ownerID: String,
        text: String,
        kind: CameraHUDKind,
        autoHideSeconds: Double? = nil)
    {
        self.cameraHUDDismissTask?.cancel()
        self.cameraHUDOwnerID = ownerID

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            self.cameraHUDText = text
            self.cameraHUDKind = kind
        }

        guard let autoHideSeconds else { return }
        self.cameraHUDDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoHideSeconds * 1_000_000_000))
            guard self.cameraHUDOwnerID == ownerID else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.cameraHUDText = nil
                self.cameraHUDKind = nil
            }
            self.cameraHUDOwnerID = nil
            self.cameraHUDDismissTask = nil
        }
    }

    private func updateCameraHUD(
        ownerID: String,
        text: String,
        kind: CameraHUDKind,
        autoHideSeconds: Double? = nil)
    {
        guard self.cameraHUDOwnerID == ownerID else { return }
        self.showCameraHUD(ownerID: ownerID, text: text, kind: kind, autoHideSeconds: autoHideSeconds)
    }

    private func clearCameraHUD(ownerID: String) {
        guard self.cameraHUDOwnerID == ownerID else { return }
        self.cameraHUDDismissTask?.cancel()
        self.cameraHUDDismissTask = nil
        self.cameraHUDOwnerID = nil
        self.cameraHUDText = nil
        self.cameraHUDKind = nil
    }
}

extension NodeAppModel {
    var mainSessionKey: String {
        let base = SessionKey.normalizeMainKey(self.mainSessionBaseKey)
        let agentId = (selectedAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultId = (gatewayDefaultAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if agentId.isEmpty || (!defaultId.isEmpty && agentId == defaultId) { return base }
        return SessionKey.makeAgentSessionKey(agentId: agentId, baseKey: base)
    }

    var chatSessionKey: String {
        if let focused = focusedChatSessionKey?.trimmingCharacters(in: .whitespacesAndNewlines),
           !focused.isEmpty
        {
            return focused
        }
        return self.defaultChatSessionKey
    }

    var defaultChatSessionKey: String {
        // Keep chat aligned with the gateway's resolved main session key.
        // A hardcoded "ios" base creates synthetic placeholder sessions in the chat UI.
        self.mainSessionKey
    }

    func openChat(sessionKey: String?, unread: Bool = false) {
        self.focusChatSession(sessionKey)
        let activeKey = self.chatSessionKey
        self.openedChatSessionKey = activeKey
        if self.readAcknowledgedChatSessionKey != activeKey {
            self.readAcknowledgedChatSessionKey = nil
        }
        if unread {
            self.acknowledgeChatSessionReadIfNeeded(activeKey)
        }
        self.openChatRequestID &+= 1
    }

    func requestNewChat() {
        self.newChatRequestID &+= 1
    }

    func consumeNewChatRequest(_ requestID: Int) -> Bool {
        guard requestID != 0,
              requestID == self.newChatRequestID,
              requestID != self.consumedNewChatRequestID
        else { return false }
        self.consumedNewChatRequestID = requestID
        return true
    }

    func consumeDashboardNavigationRequest(_ requestID: Int) -> Bool {
        guard requestID != 0,
              requestID == self.dashboardNavigationRequestID,
              requestID != self.consumedDashboardNavigationRequestID
        else { return false }
        self.consumedDashboardNavigationRequestID = requestID
        return true
    }

    /// One acknowledgement per unread episode: the pending flag clears when a fresh
    /// snapshot confirms the read (unread != true), so a run finishing while the
    /// session stays open re-acknowledges without patch loops (the gateway stamps
    /// lastReadAt server-side, which makes the exchange convergent).
    func reconcileChatSessionReadState(_ entries: [NovaChatSessionEntry]) {
        guard let openedKey = self.openedChatSessionKey,
              let entry = entries.first(where: { $0.key == openedKey })
        else { return }
        if entry.unread != true {
            if self.readAcknowledgedChatSessionKey == openedKey {
                self.readAcknowledgedChatSessionKey = nil
            }
            return
        }
        // Only the currently open chat auto-acknowledges fresh unread episodes.
        guard openedKey == self.chatSessionKey else { return }
        self.acknowledgeChatSessionReadIfNeeded(openedKey)
    }

    private func acknowledgeChatSessionReadIfNeeded(_ sessionKey: String) {
        guard self.readAcknowledgedChatSessionKey != sessionKey else { return }
        self.readAcknowledgedChatSessionKey = sessionKey
        let transport = self.makeChatTransport()
        Task { @MainActor in
            do {
                try await transport.patchSession(
                    key: sessionKey,
                    label: nil,
                    category: nil,
                    pinned: nil,
                    archived: nil,
                    unread: false)
            } catch {
                if self.readAcknowledgedChatSessionKey == sessionKey {
                    self.readAcknowledgedChatSessionKey = nil
                }
            }
        }
    }

    func focusChatSession(_ sessionKey: String?) {
        let trimmed = (sessionKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.focusedChatSessionKey = trimmed.isEmpty ? nil : trimmed
        self.synchronizeTalkSessionKey()
    }

    /// Session changes invalidate queued PTT admission before Talk cancels any
    /// active owner. Otherwise a waiter can wake and retarget to the new chat.
    func synchronizeTalkSessionKey(_ sessionKey: String? = nil) {
        let effectiveSessionKey = sessionKey ?? self.chatSessionKey
        guard !self.talkMode.isUsingMainSessionKey(effectiveSessionKey) else { return }
        self.talkPttCommandEpoch &+= 1
        self.voiceWake.invalidatePendingCommand()
        self.talkMode.updateMainSessionKey(effectiveSessionKey)
    }

    var chatAgentId: String {
        if let sessionAgentId = SessionKey.agentId(from: chatSessionKey) {
            return sessionAgentId
        }
        return self.selectedOrDefaultAgentId
    }

    /// Verified routing owner for sends. Unlike `chatAgentId`, this has no
    /// display fallback: a cold offline start must wait for persisted or
    /// gateway-provided ownership before it can queue durable work.
    var chatDeliveryAgentId: String? {
        if let sessionAgentId = SessionKey.agentId(from: chatSessionKey) {
            return sessionAgentId.lowercased()
        }
        let selected = (self.selectedAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !selected.isEmpty { return selected.lowercased() }
        let defaultId = (self.gatewayDefaultAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return defaultId.isEmpty ? nil : defaultId.lowercased()
    }

    var chatSessionRoutingContract: String? {
        NovaChatSessionRoutingContract.make(
            scope: self.gatewaySessionScope,
            mainKey: self.mainSessionBaseKey,
            defaultAgentID: self.gatewayDefaultAgentId)
    }

    var chatAgentName: String {
        self.agentDisplayName(for: self.chatAgentId, fallback: "Main")
    }

    var chatAgentAvatarURL: String? {
        self.agentIdentityValue(for: self.chatAgentId, key: "avatarUrl")
    }

    var chatAgentAvatarText: String? {
        self.agentIdentityValue(for: self.chatAgentId, key: "emoji")
    }

    var activeAgentName: String {
        self.agentDisplayName(for: self.selectedOrDefaultAgentId, fallback: "Main")
    }

    private var selectedOrDefaultAgentId: String {
        let agentId = (selectedAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultId = (gatewayDefaultAgentId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return agentId.isEmpty ? defaultId : agentId
    }

    private func agentDisplayName(for agentId: String, fallback: String) -> String {
        let resolvedId = agentId.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedId.isEmpty { return fallback }
        if let match = gatewayAgents.first(where: { $0.id == resolvedId }) {
            let name = (match.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? match.id : name
        }
        return resolvedId
    }

    private func agentIdentityValue(for agentId: String, key: String) -> String? {
        let resolvedId = agentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedId.isEmpty,
              let match = gatewayAgents.first(where: { $0.id == resolvedId }),
              let rawValue = match.identity?[key]?.value as? String
        else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func connectToGateway(
        url: URL,
        gatewayStableID: String,
        tls: GatewayTLSParams?,
        token: String?,
        bootstrapToken: String?,
        password: String?,
        connectOptions: GatewayConnectOptions,
        forceReconnect: Bool = false)
    {
        let stableID = GatewayStableIdentifier.exact(gatewayStableID) ?? ""
        let effectiveStableID = stableID.isEmpty ? url.absoluteString : stableID
        let sessionBox = tls.map { WebSocketSessionBox(session: GatewayTLSPinningSession(params: $0)) }
        let nextConfig = GatewayConnectConfig(
            url: url,
            stableID: stableID,
            tls: tls,
            token: token,
            bootstrapToken: bootstrapToken,
            password: password,
            nodeOptions: connectOptions)
        let previousGatewayStableID = self.activeGatewayConnectConfig?.effectiveStableID
            ?? self.connectedGatewayID
        let isSameGatewayTarget = previousGatewayStableID.map {
            !$0.isEmpty && GatewayStableIdentifier.matches($0, effectiveStableID)
        } ?? false
        let targetChanged = previousGatewayStableID.map {
            !$0.isEmpty && !GatewayStableIdentifier.matches($0, effectiveStableID)
        } ?? false
        if targetChanged {
            self.clearGatewayProblemForCommittedTargetSwitch(to: effectiveStableID)
        }
        let hasForeignCachedApproval = self.watchExecApprovalPromptsByID.values.contains {
            !GatewayStableIdentifier.matches($0.gatewayStableID, effectiveStableID)
        }
        if hasForeignCachedApproval || targetChanged {
            // Approval IDs are gateway-local authorization handles. A target switch must remove
            // every cached surface so stale prompts cannot authorize work on the replacement.
            invalidateExecApprovalSurfacesForGatewayChange()
        }
        let operatorLoopRequired = shouldStartOperatorGatewayLoop(
            token: token,
            bootstrapToken: bootstrapToken,
            password: password,
            deviceAuthGatewayID: connectOptions.deviceAuthGatewayID ?? effectiveStableID,
            allowStoredDeviceAuth: connectOptions.allowStoredDeviceAuth)
        if let activeConfig = activeGatewayConnectConfig,
           activeConfig.hasSameConnectionInputs(as: nextConfig),
           nodeGatewayTask != nil,
           operatorGatewayTask != nil || !operatorLoopRequired,
           !forceReconnect
        {
            self.gatewayAutoReconnectEnabled = true
            return
        }

        self.gatewayRouteGeneration &+= 1
        self.activeGatewayConnectConfig = nextConfig
        prepareForGatewayConnect(
            stableID: effectiveStableID,
            preservingGatewayProblem: isSameGatewayTarget,
            preservingFocusedChatSession: isSameGatewayTarget)
        if operatorLoopRequired {
            startOperatorGatewayLoop(
                url: url,
                stableID: effectiveStableID,
                token: token,
                bootstrapToken: bootstrapToken,
                password: password,
                nodeOptions: connectOptions,
                sessionBox: sessionBox)
        } else {
            self.operatorGatewayTask = nil
            Task { await self.operatorGateway.disconnect() }
        }
        startNodeGatewayLoop(
            url: url,
            stableID: effectiveStableID,
            token: token,
            bootstrapToken: bootstrapToken,
            password: password,
            nodeOptions: connectOptions,
            sessionBox: sessionBox)
    }

    /// Preferred entry-point: apply a single config object and start both sessions.
    func applyGatewayConnectConfig(
        _ cfg: GatewayConnectConfig,
        forceReconnect: Bool = false)
    {
        let generation = self.beginGatewayConnectAttempt()
        self.applyGatewayConnectConfig(
            cfg,
            forceReconnect: forceReconnect,
            expectedGeneration: generation)
    }

    /// Applies queued work only while its originating gateway attempt is still current.
    func applyGatewayConnectConfig(
        _ cfg: GatewayConnectConfig,
        forceReconnect: Bool = false,
        expectedGeneration: UInt64)
    {
        guard expectedGeneration == self.gatewayConnectGeneration else { return }
        self.isAppleReviewDemoModeEnabled = false
        self.isScreenshotFixtureModeEnabled = false
        self.connectToGateway(
            url: cfg.url,
            // Preserve the caller-provided stableID (may be empty) and let connectToGateway
            // derive the effective stable id consistently for persistence keys.
            gatewayStableID: cfg.stableID,
            tls: cfg.tls,
            token: cfg.token,
            bootstrapToken: cfg.bootstrapToken,
            password: cfg.password,
            connectOptions: cfg.nodeOptions,
            forceReconnect: forceReconnect)
    }

    func beginGatewayConnectAttempt() -> UInt64 {
        self.gatewayConnectGeneration &+= 1
        return self.gatewayConnectGeneration
    }

    private func invalidateGatewayConnectAttempts() {
        self.gatewayConnectGeneration &+= 1
    }

    var hasGatewaySessionResetInFlight: Bool {
        self.gatewaySessionResetTask != nil
    }

    func waitForGatewaySessionResetIfNeeded() async {
        while let gatewaySessionResetTask {
            await gatewaySessionResetTask.value
        }
    }

    @discardableResult
    private func beginGatewaySessionReset(chainingAfterExisting: Bool = false) -> Task<Void, Never> {
        let previousResetTask = self.gatewaySessionResetTask
        if let previousResetTask, !chainingAfterExisting {
            return previousResetTask
        }
        let nodeGatewayTask = self.nodeGatewayTask
        let operatorGatewayTask = self.operatorGatewayTask
        self.talkMode.updateGatewayConnected(false)
        self.voiceWake.invalidatePendingCommand()
        self.gatewayRouteGeneration &+= 1
        nodeGatewayTask?.cancel()
        self.nodeGatewayTask = nil
        operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        let operatorGateway = self.operatorGateway
        let nodeGateway = self.nodeGateway
        self.gatewaySessionResetGeneration &+= 1
        let resetGeneration = self.gatewaySessionResetGeneration
        // Disconnect first so canceled receive loops can unwind, then keep the barrier until their
        // cleanup exits. A stale loop may otherwise disconnect a replacement session after reset.
        let gatewaySessionResetTask = Task {
            await previousResetTask?.value
            await operatorGateway.disconnect()
            await nodeGateway.disconnect()
            await operatorGatewayTask?.value
            await nodeGatewayTask?.value
            if self.gatewaySessionResetGeneration == resetGeneration {
                self.gatewaySessionResetTask = nil
            }
        }
        self.gatewaySessionResetTask = gatewaySessionResetTask
        return gatewaySessionResetTask
    }

    func resetGatewaySessionsForForcedReconnect() async {
        await self.beginGatewaySessionReset().value
    }

    func resetGatewaySessionsForTargetSwitch() async {
        // A target awaiting TLS trust must not retain a reconnect route to the previous gateway.
        invalidateExecApprovalSurfacesForGatewayChange()
        self.invalidateGatewayConnectAttempts()
        self.chatSessionRoutingRestoreTask?.cancel()
        self.chatSessionRoutingRestoreTask = nil
        self.disableGatewayAutoReconnect()
        self.activeGatewayConnectConfig = nil
        ShareGatewayRelaySettings.clearConfig()
        await self.resetGatewaySessionsForForcedReconnect()
        guard !self.gatewayAutoReconnectEnabled, self.activeGatewayConnectConfig == nil else { return }
        // A canceled loop may have persisted its reconnect flag and relay config while teardown was in flight.
        self.disableGatewayAutoReconnect()
        ShareGatewayRelaySettings.clearConfig()
        self.gatewayHealthMonitor.stop()
        self.gatewayStatusText = "Offline"
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        self.connectedGatewayID = nil
        self.gatewayConnected = false
        setOperatorConnected(false)
        self.talkMode.updateGatewayConnected(false)
    }

    private func restartGatewaySessionsAfterForegroundStaleConnection() async {
        guard self.gatewayAutoReconnectEnabled, let cfg = activeGatewayConnectConfig else { return }
        let generation = self.gatewayConnectGeneration
        await self.resetGatewaySessionsForForcedReconnect()
        guard generation == self.gatewayConnectGeneration,
              self.gatewayAutoReconnectEnabled,
              self.activeGatewayConnectConfig?.hasSameConnectionInputs(as: cfg) == true,
              self.nodeGatewayTask == nil,
              self.operatorGatewayTask == nil
        else { return }
        guard !self.isLocalGatewayFixtureEnabled else { return }
        setOperatorConnected(false)
        self.gatewayConnected = false
        self.setGatewayConnectionProgress(reconnecting: true)
        self.talkMode.updateGatewayConnected(false)
        self.applyGatewayConnectConfig(
            cfg,
            forceReconnect: true,
            expectedGeneration: generation)
    }

    func disconnectGateway() {
        self.disconnectGateway(disablePersistedAutoConnect: true, invalidateConnectAttempts: true)
    }

    func suspendGatewayForTargetReview() {
        // Target review pauses live reconnects without changing the user's launch preference.
        self.disconnectGateway(disablePersistedAutoConnect: false, invalidateConnectAttempts: true)
    }

    /// A replacement target may already own the connect generation while the forgotten route is live.
    /// Preserve that generation so teardown cannot strand the replacement offline.
    func disconnectForgottenGateway(preservingPendingConnectAttempt: Bool) {
        self.disconnectGateway(
            disablePersistedAutoConnect: !preservingPendingConnectAttempt,
            invalidateConnectAttempts: !preservingPendingConnectAttempt)
    }

    private func disconnectGateway(
        disablePersistedAutoConnect: Bool,
        invalidateConnectAttempts: Bool)
    {
        invalidateExecApprovalSurfacesForGatewayChange()
        if invalidateConnectAttempts {
            self.invalidateGatewayConnectAttempts()
        }
        self.isAppleReviewDemoModeEnabled = false
        self.isScreenshotFixtureModeEnabled = false
        if disablePersistedAutoConnect {
            self.disableGatewayAutoReconnect()
        } else {
            self.gatewayAutoReconnectEnabled = false
        }
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.lastGatewayProblem = nil
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        self.cancelTalkPermissionUpgrade()
        // Publish teardown through the shared barrier before returning. A replacement connect
        // must await old loop cleanup instead of racing this synchronous UI action.
        _ = self.beginGatewaySessionReset(chainingAfterExisting: true)
        self.voiceWakeSyncTask?.cancel()
        self.voiceWakeSyncTask = nil
        LiveActivityManager.shared.endActivity(reason: "manual_disconnect")
        self.gatewayHealthMonitor.stop()
        self.gatewayStatusText = "Offline"
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        self.connectedGatewayID = nil
        self.activeGatewayConnectConfig = nil
        self.gatewayConnected = false
        setOperatorConnected(false)
        self.talkMode.updateGatewayConnected(false)
        self.invalidateNodePushToTalkRoute()
        self.chatSessionRoutingRestoreTask?.cancel()
        self.chatSessionRoutingRestoreTask = nil
        self.synchronizeTalkSessionKey()
        ShareGatewayRelaySettings.clearConfig()
        showLocalCanvasOnDisconnect()
    }

    private func disableGatewayAutoReconnect() {
        // Runtime teardown and persisted startup routing must move together. Otherwise a relaunch
        // during target review silently reconnects the gateway the user just left.
        self.gatewayAutoReconnectEnabled = false
        UserDefaults.standard.set(false, forKey: "gateway.autoconnect")
    }
}

extension NodeAppModel {
    func resumeGatewayAfterTargetReview(_ config: GatewayConnectConfig) {
        let generation = self.beginGatewayConnectAttempt()
        self.setGatewayConnectionProgress(reconnecting: false)
        // Reapply the exact suspended route only after teardown; a newer target invalidates the generation.
        Task { [weak self] in
            guard let self else { return }
            await self.waitForGatewaySessionResetIfNeeded()
            guard generation == self.gatewayConnectGeneration else { return }
            self.applyGatewayConnectConfig(config, expectedGeneration: generation)
        }
    }

    private func prepareForGatewayConnect(
        stableID: String,
        preservingGatewayProblem: Bool = false,
        preservingFocusedChatSession: Bool = false)
    {
        self.invalidateNodePushToTalkRoute()
        self.operatorTalkConnectionGeneration &+= 1
        self.operatorTalkHydrationGeneration = nil
        self.chatSessionRoutingRestoreTask?.cancel()
        self.isAppleReviewDemoModeEnabled = false
        self.isScreenshotFixtureModeEnabled = false
        self.gatewayAutoReconnectEnabled = true
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        // A retained error is presentation history, not live operator control. Explicit retries
        // must retire the old pairing state so the replacement session can clear the snapshot.
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        if !preservingGatewayProblem {
            // Same-target reconnects keep the prior failure readable until success or a new failure.
            // Initial connects and target changes must not inherit another gateway's problem state.
            self.clearGatewayConnectionProblem()
        }
        self.credentialHandoffFailureGeneration = nil
        self.nodeGatewayTask?.cancel()
        self.operatorGatewayTask?.cancel()
        self.gatewayHealthMonitor.stop()
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        self.connectedGatewayID = stableID
        self.gatewayConnected = false
        self.setOperatorConnected(false)
        self.talkMode.updateGatewayConnected(false)
        self.voiceWakeSyncTask?.cancel()
        self.voiceWakeSyncTask = nil
        LiveActivityManager.shared.endActivity(reason: "new_gateway_connect")
        self.mainSessionBaseKey = "main"
        self.gatewaySessionScope = nil
        self.gatewayDefaultAgentId = nil
        self.gatewayAgents = []
        self.selectedAgentId = GatewaySettingsStore.loadGatewaySelectedAgentId(stableID: stableID)
        // Session keys are gateway-owned: transport reconnects keep the active chat,
        // while initial connects and target changes must not inherit another route.
        if !preservingFocusedChatSession {
            self.focusedChatSessionKey = nil
        }
        self.synchronizeTalkSessionKey()
        self.homeCanvasRevision &+= 1
        self.apnsLastRegisteredTokenHex = nil
        self.apnsLastRegisteredGatewayStableID = nil
        self.chatSessionRoutingRestoreTask = Task { [weak self] in
            guard !Task.isCancelled, self?.connectedGatewayID == stableID else { return }
            await self?.restoreChatSessionRoutingIdentityIfNeeded()
        }
    }

    private func clearGatewayConnectionProblem() {
        self.nodeGatewayProblem = nil
        if let operatorGatewayProblem {
            self.lastGatewayProblem = operatorGatewayProblem
            if operatorGatewayProblem.needsPairingApproval {
                self.gatewayPairingPaused = true
                self.gatewayPairingRequestId = operatorGatewayProblem.requestId
            } else {
                self.gatewayPairingPaused = false
                self.gatewayPairingRequestId = nil
            }
            return
        }
        self.lastGatewayProblem = nil
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
    }

    func beginGatewayPreconnectVerification(statusText: String) {
        // Preflight has not committed the replacement target yet. Keep the readable snapshot
        // while retiring live pairing control; the committed route switch clears the snapshot.
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.gatewayStatusText = statusText
    }

    private func applyGatewayConnectionProblem(_ problem: GatewayConnectionProblem) {
        guard !self.isLocalGatewayFixtureEnabled else { return }
        self.nodeGatewayProblem = problem
        self.lastGatewayProblem = problem
        self.gatewayStatusText = problem.statusText
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        self.gatewayConnected = false
        showLocalCanvasOnDisconnect()
        if problem.pauseReconnect {
            self.gatewayAutoReconnectEnabled = false
        }
        if problem.needsPairingApproval {
            self.gatewayPairingPaused = true
            self.gatewayPairingRequestId = problem.requestId
        } else {
            self.gatewayPairingPaused = false
            self.gatewayPairingRequestId = nil
        }
        if problem.needsPairingApproval || problem.pauseReconnect {
            LiveActivityManager.shared.showAttention(
                statusText: problem.needsPairingApproval
                    ? String(localized: "Approval needed")
                    : String(localized: "Action required"),
                agentName: self.activeAgentName,
                sessionKey: self.mainSessionKey)
        }
    }

    private func applyOperatorGatewayConnectionProblem(_ problem: GatewayConnectionProblem) {
        guard !self.isLocalGatewayFixtureEnabled else { return }
        self.operatorGatewayProblem = problem
        self.lastGatewayProblem = problem
        self.gatewayStatusText = problem.statusText
        if problem.needsPairingApproval {
            self.gatewayPairingPaused = true
            self.gatewayPairingRequestId = problem.requestId
        }
        if problem.needsPairingApproval || problem.pauseReconnect {
            LiveActivityManager.shared.showAttention(
                statusText: problem.needsPairingApproval
                    ? String(localized: "Approval needed")
                    : String(localized: "Action required"),
                agentName: self.activeAgentName,
                sessionKey: self.mainSessionKey)
        }
    }

    private func clearOperatorGatewayConnectionProblemIfCurrent() {
        guard let operatorGatewayProblem else { return }
        self.operatorGatewayProblem = nil
        guard self.lastGatewayProblem == operatorGatewayProblem else { return }
        if let nodeGatewayProblem {
            self.lastGatewayProblem = nodeGatewayProblem
            self.gatewayPairingPaused = nodeGatewayProblem.needsPairingApproval
            self.gatewayPairingRequestId = nodeGatewayProblem.needsPairingApproval
                ? nodeGatewayProblem.requestId
                : nil
        } else {
            self.lastGatewayProblem = nil
            self.gatewayPairingPaused = false
            self.gatewayPairingRequestId = nil
        }
        if self.gatewayServerName != nil {
            self.gatewayStatusText = "Connected"
        }
        if self.gatewayConnected {
            LiveActivityManager.shared.handleReconnect()
        }
    }

    private func currentGatewayProblemToKeep(forDisconnectReason reason: String) -> GatewayConnectionProblem? {
        guard let lastGatewayProblem,
              lastGatewayProblem == self.nodeGatewayProblem || lastGatewayProblem == self.operatorGatewayProblem,
              GatewayConnectionProblemMapper.shouldPreserve(
                  previousProblem: lastGatewayProblem,
                  overDisconnectReason: reason)
        else { return nil }
        return lastGatewayProblem
    }

    private func shouldStartOperatorGatewayLoop(
        token: String?,
        bootstrapToken: String?,
        password: String?,
        deviceAuthGatewayID: String,
        allowStoredDeviceAuth: Bool = true) -> Bool
    {
        Self.shouldStartOperatorGatewayLoop(
            token: token,
            bootstrapToken: bootstrapToken,
            password: password,
            hasStoredOperatorToken: allowStoredDeviceAuth && self.hasStoredGatewayRoleToken(
                "operator",
                gatewayID: deviceAuthGatewayID))
    }

    private func hasStoredGatewayRoleToken(_ role: String, gatewayID: String) -> Bool {
        guard let identity = DeviceIdentityStore.loadOrCreatePersisted() else { return false }
        return DeviceAuthStore.loadToken(
            deviceId: identity.deviceId,
            role: role,
            gatewayID: gatewayID) != nil
    }

    fileprivate nonisolated static func shouldStartOperatorGatewayLoop(
        token: String?,
        bootstrapToken: String?,
        password: String?,
        hasStoredOperatorToken: Bool) -> Bool
    {
        let trimmedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedToken.isEmpty {
            return true
        }
        let trimmedPassword = password?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPassword.isEmpty {
            return true
        }
        let trimmedBootstrapToken = bootstrapToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedBootstrapToken.isEmpty {
            return false
        }
        return hasStoredOperatorToken
    }

    private func currentGatewayReconnectAuth(
        fallbackToken: String?,
        fallbackBootstrapToken: String?,
        fallbackPassword: String?) -> (token: String?, bootstrapToken: String?, password: String?)
    {
        if let cfg = activeGatewayConnectConfig {
            return (cfg.token, cfg.bootstrapToken, cfg.password)
        }
        return (fallbackToken, fallbackBootstrapToken, fallbackPassword)
    }

    private func currentGatewayReconnectOptions(
        stableID: String,
        fallback: GatewayConnectOptions) -> GatewayConnectOptions
    {
        guard let config = activeGatewayConnectConfig,
              GatewayStableIdentifier.matches(config.effectiveStableID, stableID)
        else { return fallback }
        return config.nodeOptions
    }

    private nonisolated static func usesBootstrapCredential(
        token: String?,
        bootstrapToken: String?,
        password: String?) -> Bool
    {
        token?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
            password?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
            bootstrapToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func completeSuccessfulGatewayAuthHandoff(
        stableID: String,
        routeGeneration: UInt64,
        issuedRoles: Set<String>,
        nodeOptions: GatewayConnectOptions) throws -> GatewayConnectOptions?
    {
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return nil }

        // Bootstrap authentication is single-use. Do not keep a consumed bootstrap
        // route alive unless both replacement sessions can authenticate from secure storage.
        guard issuedRoles.isSuperset(of: ["node", "operator"]) else {
            return nodeOptions.allowStoredDeviceAuth ? nodeOptions : nil
        }
        guard let config = activeGatewayConnectConfig,
              GatewayStableIdentifier.matches(config.effectiveStableID, stableID)
        else { return nil }
        let instanceID = GatewaySettingsStore.currentInstanceID()
        let deviceAuthGatewayID = nodeOptions.deviceAuthGatewayID ?? stableID
        if let metadata = GatewaySettingsStore.loadGatewayCredentialMetadata(
            instanceId: instanceID,
            gatewayStableID: deviceAuthGatewayID),
            metadata.suppressStoredDeviceAuth
        {
            guard try GatewaySettingsStore.completeGatewayCredentialHandoff(
                instanceId: instanceID,
                gatewayStableID: deviceAuthGatewayID)
            else { return nil }
        }
        var reconnectOptions = nodeOptions
        reconnectOptions.allowStoredDeviceAuth = true
        self.activeGatewayConnectConfig = GatewayConnectConfig(
            url: config.url,
            stableID: config.stableID,
            tls: config.tls,
            token: config.token,
            bootstrapToken: nil,
            password: config.password,
            nodeOptions: reconnectOptions)

        if self.operatorGatewayTask == nil,
           self.shouldStartOperatorGatewayLoop(
               token: config.token,
               bootstrapToken: nil,
               password: config.password,
               deviceAuthGatewayID: deviceAuthGatewayID,
               allowStoredDeviceAuth: true)
        {
            let sessionBox = config.tls.map {
                WebSocketSessionBox(session: GatewayTLSPinningSession(params: $0))
            }
            self.startOperatorGatewayLoop(
                url: config.url,
                stableID: stableID,
                token: config.token,
                bootstrapToken: nil,
                password: config.password,
                nodeOptions: reconnectOptions,
                sessionBox: sessionBox)
        }
        return reconnectOptions
    }

    private func gatewayOptionsAfterSuccessfulConnection(
        _ nodeOptions: GatewayConnectOptions,
        stableID: String,
        routeGeneration: UInt64,
        auth: (token: String?, bootstrapToken: String?, password: String?)) async -> GatewayConnectOptions?
    {
        guard !nodeOptions.allowStoredDeviceAuth else { return nodeOptions }
        guard Self.usesBootstrapCredential(
            token: auth.token,
            bootstrapToken: auth.bootstrapToken,
            password: auth.password)
        else {
            return nodeOptions
        }
        let issuedRoles = await nodeGateway.currentIssuedDeviceAuthRoles()
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return nil }
        let reconnectOptions: GatewayConnectOptions?
        do {
            reconnectOptions = try self.completeSuccessfulGatewayAuthHandoff(
                stableID: stableID,
                routeGeneration: routeGeneration,
                issuedRoles: issuedRoles,
                nodeOptions: nodeOptions)
        } catch {
            await self.handleGatewayCredentialHandoffPersistenceFailure(
                stableID: stableID,
                routeGeneration: routeGeneration,
                error: error)
            return nil
        }
        guard let reconnectOptions else {
            await self.handleGatewayCredentialHandoffPersistenceFailure(
                stableID: stableID,
                routeGeneration: routeGeneration)
            return nil
        }
        return reconnectOptions
    }

    private func handleGatewayCredentialHandoffPersistenceFailure(
        stableID: String,
        routeGeneration: UInt64,
        error: Error? = nil) async
    {
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        guard self.credentialHandoffFailureGeneration != routeGeneration else { return }
        self.credentialHandoffFailureGeneration = routeGeneration
        self.disableGatewayAutoReconnect()
        self.nodeGatewayTask?.cancel()
        self.nodeGatewayTask = nil
        self.operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        await self.nodeGateway.disconnect()
        await self.operatorGateway.disconnect()
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        let technicalDetails = error.map {
            "Gateway credential handoff persistence failed: \($0.localizedDescription)"
        } ?? "Gateway credential handoff persistence failed."
        GatewayDiagnostics.log(technicalDetails)
        self.applyGatewayConnectionProblem(GatewayConnectionProblem(
            kind: .unknown,
            owner: .iphone,
            title: "Credential save failed",
            message: "Nova disconnected because it could not securely save the new gateway credential.",
            retryable: true,
            pauseReconnect: true,
            technicalDetails: technicalDetails))
    }

    private func refreshBackgroundReconnectSuppressionIfNeeded(source: String) {
        guard self.isBackgrounded else { return }
        guard !self.backgroundReconnectSuppressed else { return }
        guard let leaseUntil = backgroundReconnectLeaseUntil else {
            self.suppressBackgroundReconnect(reason: "\(source):no_lease", disconnectIfNeeded: true)
            return
        }
        if Date() >= leaseUntil {
            self.suppressBackgroundReconnect(reason: "\(source):lease_expired", disconnectIfNeeded: true)
        }
    }

    private func shouldPauseReconnectLoopInBackground(source: String) -> Bool {
        self.refreshBackgroundReconnectSuppressionIfNeeded(source: source)
        return self.isBackgrounded && self.backgroundReconnectSuppressed
    }

    private func gatewayReconnectLoopDelay(source: String) -> UInt64? {
        if !self.gatewayAutoReconnectEnabled || self.gatewayPairingPaused {
            return 1_000_000_000
        }
        return self.shouldPauseReconnectLoopInBackground(source: source)
            ? 2_000_000_000
            : nil
    }

    private func isCurrentGatewayRoute(generation: UInt64, stableID: String) -> Bool {
        generation == self.gatewayRouteGeneration &&
            GatewayStableIdentifier.matches(
                self.activeGatewayConnectConfig?.effectiveStableID,
                stableID)
    }

    private func isCurrentExecApprovalReadbackRoute(generation: UInt64, stableID: String) -> Bool {
        #if DEBUG
        if self.testExecApprovalPromptFetchHandler != nil {
            return generation == self.gatewayRouteGeneration &&
                GatewayStableIdentifier.matches(
                    self.currentExecApprovalGatewayStableID(),
                    stableID)
        }
        #endif
        return self.isCurrentGatewayRoute(generation: generation, stableID: stableID)
    }

    private func gatewayRouteCheck(
        generation: UInt64,
        stableID: String) -> @MainActor @Sendable () -> Bool
    {
        { [weak self] in
            self?.isCurrentGatewayRoute(generation: generation, stableID: stableID) == true
        }
    }

    private func handleOperatorGatewayConnected(
        url: URL,
        stableID: String,
        routeGeneration: UInt64) async
    {
        guard !self.isLocalGatewayFixtureEnabled,
              self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID)
        else { return }
        self.operatorTalkConnectionGeneration &+= 1
        let talkConnectionGeneration = self.operatorTalkConnectionGeneration
        self.operatorTalkHydrationGeneration = talkConnectionGeneration
        defer {
            if self.operatorTalkHydrationGeneration == talkConnectionGeneration {
                self.operatorTalkHydrationGeneration = nil
            }
        }
        self.setOperatorConnected(true)
        self.clearOperatorGatewayConnectionProblemIfCurrent()
        GatewayDiagnostics.log(
            "operator gateway connected host=\(url.host ?? "?") scheme=\(url.scheme ?? "?")")

        let shouldContinue: @MainActor @Sendable () -> Bool = { [weak self] in
            guard let self else { return false }
            return self.operatorTalkConnectionGeneration == talkConnectionGeneration &&
                self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID)
        }
        // Watch approval resolutions flush from the reconcile-gated watch path
        // (reconcileWatchExecApprovalCache), not eagerly on operator connect.
        if let chatSessionRoutingRestoreTask {
            await chatSessionRoutingRestoreTask.value
        }
        guard shouldContinue() else { return }
        self.chatSessionRoutingRestoreTask = nil
        await self.refreshBrandingFromGateway(shouldApply: shouldContinue)
        guard shouldContinue() else { return }
        await self.refreshAgentsFromGateway(shouldApply: shouldContinue)
        guard shouldContinue() else { return }
        await self.talkMode.reloadConfig(shouldApply: shouldContinue)
        guard shouldContinue() else { return }
        self.requestTalkPermissionUpgradeIfNeeded()
        if self.forceOperatorTalkPermissionUpgradeRequest {
            guard !self.talkMode.gatewayTalkPermissionState.requiresTalkPermissionAction else { return }
            // Completing the forced handshake must also release any approval pause so the
            // shared operator route keeps reconnecting after this successful connection.
            self.gatewayAutoReconnectEnabled = true
            self.gatewayPairingPaused = false
            self.gatewayPairingRequestId = nil
            self.cancelTalkPermissionUpgrade()
        }
        self.admitTalkAfterSessionHydration()
        await self.talkMode.prefetchRealtimeSessionIfReady(
            reason: "operator_connected",
            shouldApply: shouldContinue)
        guard shouldContinue() else { return }
        await refreshShareRouteFromGateway(shouldApply: shouldContinue)
        guard shouldContinue() else { return }
        await registerAPNsTokenIfNeeded(shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        await self.startVoiceWakeSync(shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        self.startGatewayHealthMonitor()
    }

    private func admitTalkAfterSessionHydration() {
        self.synchronizeTalkSessionKey()
        self.talkMode.updateGatewayConnected(true)
    }

    private func handleNodeGatewayConnected(
        url: URL,
        stableID: String,
        routeGeneration: UInt64,
        nodeOptions: GatewayConnectOptions,
        auth: (token: String?, bootstrapToken: String?, password: String?)) async
    {
        guard !self.isLocalGatewayFixtureEnabled,
              self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID)
        else { return }
        let usedBootstrapToken = Self.usesBootstrapCredential(
            token: auth.token,
            bootstrapToken: auth.bootstrapToken,
            password: auth.password)
        if usedBootstrapToken {
            let issuedRoles = await nodeGateway.currentIssuedDeviceAuthRoles()
            guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
            do {
                guard try self.completeSuccessfulGatewayAuthHandoff(
                    stableID: stableID,
                    routeGeneration: routeGeneration,
                    issuedRoles: issuedRoles,
                    nodeOptions: nodeOptions) != nil
                else {
                    await self.handleGatewayCredentialHandoffPersistenceFailure(
                        stableID: stableID,
                        routeGeneration: routeGeneration)
                    return
                }
            } catch {
                await self.handleGatewayCredentialHandoffPersistenceFailure(
                    stableID: stableID,
                    routeGeneration: routeGeneration,
                    error: error)
                return
            }
        }

        self.clearGatewayConnectionProblem()
        self.gatewayStatusText = "Connected"
        self.gatewayServerName = url.host ?? "gateway"
        self.gatewayConnected = true
        _ = GatewaySettingsStore.markGatewayConnected(
            stableID: stableID,
            atMs: Int(Date().timeIntervalSince1970 * 1000))
        self.screen.errorText = nil
        UserDefaults.standard.set(true, forKey: "gateway.autoconnect")
        LiveActivityManager.shared.handleReconnect()
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        ShareGatewayRelaySettings.saveConfig(ShareGatewayRelayConfig(
            gatewayURLString: url.absoluteString,
            gatewayStableID: nodeOptions.deviceAuthGatewayID,
            token: auth.token,
            password: auth.password,
            sessionKey: self.mainSessionKey,
            deliveryChannel: self.shareDeliveryChannel,
            deliveryTo: self.shareDeliveryTo))
        GatewayDiagnostics.log(
            "gateway connected host=\(url.host ?? "?") scheme=\(url.scheme ?? "?")")

        if let address = await nodeGateway.currentRemoteAddress() {
            guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
            self.gatewayRemoteAddress = address
        }
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        await showA2UIOnConnectIfNeeded()
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        let shouldContinue = self.gatewayRouteCheck(
            generation: routeGeneration,
            stableID: stableID)
        await onNodeGatewayConnected(shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        SignificantLocationMonitor.startIfNeeded(
            locationService: self.locationService,
            locationMode: self.locationMode(),
            gateway: self.nodeGateway,
            beforeSend: { [weak self] in
                await self?.handleSignificantLocationWakeIfNeeded()
            })
    }

    private func startOperatorGatewayLoop(
        url: URL,
        stableID: String,
        token: String?,
        bootstrapToken: String?,
        password: String?,
        nodeOptions: GatewayConnectOptions,
        sessionBox: WebSocketSessionBox?)
    {
        let routeGeneration = self.gatewayRouteGeneration
        // Async reconnect helpers can resume after Disconnect or a target switch. Only the
        // current route may install a new loop after those suspension points.
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        // Operator session reconnects independently (chat/talk/config/voicewake), but we tie its
        // lifecycle to the current gateway config so it doesn't keep running across Disconnect.
        self.operatorGatewayTask = Task { [weak self] in
            guard let self else { return }
            var attempt = 0
            while !Task.isCancelled,
                  self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID)
            {
                if let delay = self.gatewayReconnectLoopDelay(source: "operator_loop") {
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                }
                if await self.isOperatorConnected() {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }

                let reconnectAuth = self.currentGatewayReconnectAuth(
                    fallbackToken: token,
                    fallbackBootstrapToken: bootstrapToken,
                    fallbackPassword: password)
                // Bootstrap handoff enables stored auth in the active config. Reconnects must
                // consume that current ownership state instead of the loop's one-shot bootstrap options.
                let reconnectOptions = self.currentGatewayReconnectOptions(
                    stableID: stableID,
                    fallback: nodeOptions)
                let effectiveClientId =
                    GatewaySettingsStore.loadGatewayClientIdOverride(stableID: stableID) ?? reconnectOptions.clientId
                let talkPermissionUpgradeRequest = self.forceOperatorTalkPermissionUpgradeRequest
                let deviceAuthGatewayID = reconnectOptions.deviceAuthGatewayID ?? stableID
                let operatorOptions = self.makeOperatorConnectOptions(
                    clientId: effectiveClientId,
                    displayName: reconnectOptions.clientDisplayName,
                    deviceAuthGatewayID: deviceAuthGatewayID,
                    includeAdminScope: self.shouldRequestOperatorAdminScope(
                        gatewayID: deviceAuthGatewayID,
                        token: reconnectAuth.token,
                        password: reconnectAuth.password,
                        forceTalkPermissionUpgradeRequest: talkPermissionUpgradeRequest),
                    includeApprovalScope: self.shouldRequestOperatorApprovalScope(
                        gatewayID: deviceAuthGatewayID,
                        token: reconnectAuth.token,
                        password: reconnectAuth.password,
                        forceTalkPermissionUpgradeRequest: talkPermissionUpgradeRequest),
                    forceExplicitScopes: talkPermissionUpgradeRequest,
                    allowStoredDeviceAuth: reconnectOptions.allowStoredDeviceAuth)

                do {
                    try await self.operatorGateway.connect(
                        url: url,
                        credentials: GatewayNodeSessionCredentials(
                            token: reconnectAuth.token,
                            bootstrapToken: reconnectAuth.bootstrapToken,
                            password: reconnectAuth.password),
                        connectOptions: operatorOptions,
                        sessionBox: sessionBox,
                        extraHeadersProvider: {
                            GatewaySettingsStore.loadGatewayCustomHeaders(gatewayStableID: stableID)
                        },
                        onConnected: { [weak self] in
                            await self?.handleOperatorGatewayConnected(
                                url: url,
                                stableID: stableID,
                                routeGeneration: routeGeneration)
                        },
                        onDisconnected: { [weak self] reason in
                            guard let self else { return }
                            await MainActor.run {
                                guard !self.isLocalGatewayFixtureEnabled,
                                      self.isCurrentGatewayRoute(
                                          generation: routeGeneration,
                                          stableID: stableID)
                                else { return }
                                self.setOperatorConnected(false)
                                self.talkMode.updateGatewayConnected(false)
                                LiveActivityManager.shared.endActivity(reason: "operator_disconnected")
                            }
                            GatewayDiagnostics.log("operator gateway disconnected reason=\(reason)")
                            await MainActor.run {
                                guard self.isCurrentGatewayRoute(
                                    generation: routeGeneration,
                                    stableID: stableID)
                                else { return }
                                self.stopGatewayHealthMonitor()
                            }
                        },
                        onInvoke: { req in
                            // Operator session should not handle node.invoke requests.
                            BridgeInvokeResponse(
                                id: req.id,
                                ok: false,
                                error: NovaNodeError(
                                    code: .invalidRequest,
                                    message: "INVALID_REQUEST: operator session cannot invoke node commands"))
                        },
                        onRouteInvalidated: { [weak self] in
                            await MainActor.run {
                                self?.handleOperatorGatewayRouteInvalidated(
                                    routeGeneration: routeGeneration,
                                    stableID: stableID)
                            }
                        })

                    attempt = 0
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    guard self.isCurrentGatewayRoute(
                        generation: routeGeneration,
                        stableID: stableID) else { break }
                    attempt += 1
                    GatewayDiagnostics.log("operator gateway connect error: \(error.localizedDescription)")
                    let problem: GatewayConnectionProblem? = await MainActor.run {
                        let nextProblem = GatewayConnectionProblemMapper.map(error: error)
                        guard !self.isLocalGatewayFixtureEnabled,
                              self.isCurrentGatewayRoute(
                                  generation: routeGeneration,
                                  stableID: stableID)
                        else { return nil }
                        if let nextProblem {
                            if nextProblem.needsPairingApproval || nextProblem.pauseReconnect {
                                self.applyOperatorGatewayConnectionProblem(nextProblem)
                            }
                            if talkPermissionUpgradeRequest, nextProblem.kind == .pairingScopeUpgradeRequired {
                                self.talkMode.markTalkPermissionUpgradeRequested()
                            }
                        }
                        return nextProblem
                    }
                    if problem?.needsPairingApproval == true {
                        self.operatorGatewayTask?.cancel()
                        self.operatorGatewayTask = nil
                        await self.operatorGateway.disconnect()
                        break
                    }
                    if problem?.pauseReconnect == true {
                        self.operatorGatewayTask?.cancel()
                        self.operatorGatewayTask = nil
                        await self.operatorGateway.disconnect()
                        break
                    }
                    let sleepSeconds = min(8.0, 0.5 * pow(1.7, Double(attempt)))
                    try? await Task.sleep(nanoseconds: UInt64(sleepSeconds * 1_000_000_000))
                }
            }
        }
    }

    private func handleOperatorGatewayRouteInvalidated(routeGeneration: UInt64, stableID: String) {
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        self.invalidateOperatorTalkRoute()
    }

    private func invalidateOperatorTalkRoute() {
        self.operatorTalkConnectionGeneration &+= 1
        self.operatorTalkHydrationGeneration = nil
        // A socket replacement invalidates Talk, not gateway identity hydration. The
        // replacement connection must await the same restore before admitting capture.
        self.setOperatorConnected(false)
        self.talkMode.updateGatewayConnected(false)
        self.invalidateNodePushToTalkRoute()
    }

    private func handleNodeGatewayRouteInvalidated(routeGeneration: UInt64, stableID: String) {
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        self.invalidateNodePushToTalkRoute()
    }

    private func invalidateNodePushToTalkRoute() {
        self.talkPttCommandEpoch &+= 1
        self.voiceWake.invalidatePendingCommand()
        _ = self.talkMode.cancelPushToTalk(expectedTranscriptionOnly: false)
    }

    private func startNodeGatewayLoop(
        url: URL,
        stableID: String,
        token: String?,
        bootstrapToken: String?,
        password: String?,
        nodeOptions: GatewayConnectOptions,
        sessionBox: WebSocketSessionBox?)
    {
        let routeGeneration = self.gatewayRouteGeneration
        guard self.isCurrentGatewayRoute(generation: routeGeneration, stableID: stableID) else { return }
        let context = NodeGatewayLoopContext(
            url: url,
            stableID: stableID,
            routeGeneration: routeGeneration,
            fallbackToken: token,
            fallbackBootstrapToken: bootstrapToken,
            fallbackPassword: password,
            initialOptions: nodeOptions,
            sessionBox: sessionBox)
        self.nodeGatewayTask = Task { [weak self] in
            await self?.runNodeGatewayLoop(context)
        }
    }

    private func runNodeGatewayLoop(_ context: NodeGatewayLoopContext) async {
        var state = NodeGatewayLoopState(options: context.initialOptions)

        gatewayLoop: while !Task.isCancelled,
                           self.isCurrentGatewayRoute(
                               generation: context.routeGeneration,
                               stableID: context.stableID)
        {
            if await self.shouldDelayNodeGatewayConnectionAttempt() {
                continue
            }
            self.showNodeGatewayConnectingStatus(
                attempt: state.attempt,
                context: context)

            switch await self.performNodeGatewayConnectionAttempt(context: context, state: state) {
            case let .retry(nextState):
                state = nextState
            case .stop:
                break gatewayLoop
            case .stopPreservingStatus:
                // Pairing owns its status until explicit recovery.
                return
            }
        }

        self.resetNodeGatewayLoopStatusIfCurrent(context)
    }

    private func shouldDelayNodeGatewayConnectionAttempt() async -> Bool {
        if let delay = self.gatewayReconnectLoopDelay(source: "node_loop") {
            try? await Task.sleep(nanoseconds: delay)
            return true
        }
        if await self.isGatewayConnected() {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return true
        }
        return false
    }

    private func showNodeGatewayConnectingStatus(
        attempt: Int,
        context: NodeGatewayLoopContext)
    {
        guard !self.isLocalGatewayFixtureEnabled,
              self.isCurrentGatewayRoute(
                  generation: context.routeGeneration,
                  stableID: context.stableID)
        else { return }
        self.setGatewayConnectionProgress(reconnecting: attempt != 0)
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        LiveActivityManager.shared.showConnecting(
            statusText: (attempt == 0)
                ? String(localized: "Connecting...")
                : String(localized: "Reconnecting..."),
            agentName: self.activeAgentName,
            sessionKey: self.mainSessionKey)
    }

    private func performNodeGatewayConnectionAttempt(
        context: NodeGatewayLoopContext,
        state: NodeGatewayLoopState) async -> NodeGatewayLoopStep
    {
        let epochMs = Int(Date().timeIntervalSince1970 * 1000)
        let reconnectAuth = self.currentGatewayReconnectAuth(
            fallbackToken: context.fallbackToken,
            fallbackBootstrapToken: context.fallbackBootstrapToken,
            fallbackPassword: context.fallbackPassword)
        let connectedOptions = state.options
        GatewayDiagnostics.log("connect attempt epochMs=\(epochMs) url=\(context.url.absoluteString)")

        do {
            try await self.nodeGateway.connect(
                url: context.url,
                credentials: GatewayNodeSessionCredentials(
                    token: reconnectAuth.token,
                    bootstrapToken: reconnectAuth.bootstrapToken,
                    password: reconnectAuth.password),
                connectOptions: connectedOptions,
                sessionBox: context.sessionBox,
                extraHeadersProvider: {
                    GatewaySettingsStore.loadGatewayCustomHeaders(gatewayStableID: context.stableID)
                },
                onConnected: { [weak self] in
                    await self?.handleNodeGatewayConnected(
                        url: context.url,
                        stableID: context.stableID,
                        routeGeneration: context.routeGeneration,
                        nodeOptions: connectedOptions,
                        auth: reconnectAuth)
                },
                onDisconnected: { [weak self] reason in
                    guard let self else { return }
                    await MainActor.run {
                        guard !self.isLocalGatewayFixtureEnabled,
                              self.isCurrentGatewayRoute(
                                  generation: context.routeGeneration,
                                  stableID: context.stableID)
                        else { return }
                        if let currentProblem = self.currentGatewayProblemToKeep(forDisconnectReason: reason) {
                            self.gatewayStatusText = currentProblem.statusText
                        } else {
                            self.gatewayStatusText = "Disconnected: \(reason)"
                        }
                        self.gatewayServerName = nil
                        self.gatewayRemoteAddress = nil
                        self.gatewayConnected = false
                        self.showLocalCanvasOnDisconnect()
                    }
                    GatewayDiagnostics.log("gateway disconnected reason: \(reason)")
                },
                onInvoke: { [weak self] req in
                    guard let self else {
                        return BridgeInvokeResponse(
                            id: req.id,
                            ok: false,
                            error: NovaNodeError(
                                code: .unavailable,
                                message: "UNAVAILABLE: node not ready"))
                    }
                    return await self.handleInvoke(req, gatewayStableID: context.stableID)
                },
                onRouteInvalidated: { [weak self] in
                    await MainActor.run {
                        self?.handleNodeGatewayRouteInvalidated(
                            routeGeneration: context.routeGeneration,
                            stableID: context.stableID)
                    }
                })

            guard let reconnectOptions = await self.gatewayOptionsAfterSuccessfulConnection(
                connectedOptions,
                stableID: context.stableID,
                routeGeneration: context.routeGeneration,
                auth: reconnectAuth)
            else { return .stop }

            var nextState = state
            nextState.options = reconnectOptions
            nextState.attempt = 0
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return .retry(nextState)
        } catch {
            return await self.handleNodeGatewayConnectionError(
                error,
                context: context,
                state: state)
        }
    }

    private func handleNodeGatewayConnectionError(
        _ error: Error,
        context: NodeGatewayLoopContext,
        state: NodeGatewayLoopState) async -> NodeGatewayLoopStep
    {
        guard !Task.isCancelled,
              self.isCurrentGatewayRoute(
                  generation: context.routeGeneration,
                  stableID: context.stableID)
        else { return .stop }

        if !state.didFallbackClientID,
           let fallbackClientID = self.legacyClientIdFallback(
               currentClientId: state.options.clientId,
               error: error)
        {
            var nextState = state
            nextState.didFallbackClientID = true
            nextState.options.clientId = fallbackClientID
            GatewaySettingsStore.saveGatewayClientIdOverride(
                stableID: context.stableID,
                clientId: fallbackClientID)
            self.gatewayStatusText = "Gateway rejected client id. Retrying…"
            return .retry(nextState)
        }

        var nextState = state
        nextState.attempt += 1
        let problem = self.applyNodeGatewayConnectionError(
            error,
            context: context)
        GatewayDiagnostics.log("gateway connect error: \(error.localizedDescription)")

        if problem?.needsPairingApproval == true {
            // Stop both watchdogs so pairing keeps one stable request and remediation surface.
            self.operatorGatewayTask?.cancel()
            self.operatorGatewayTask = nil
            await self.operatorGateway.disconnect()
            await self.nodeGateway.disconnect()
            return .stopPreservingStatus
        }
        guard problem?.pauseReconnect != true else {
            return .retry(nextState)
        }

        let sleepSeconds = min(8.0, 0.5 * pow(1.7, Double(nextState.attempt)))
        try? await Task.sleep(nanoseconds: UInt64(sleepSeconds * 1_000_000_000))
        return .retry(nextState)
    }

    private func applyNodeGatewayConnectionError(
        _ error: Error,
        context: NodeGatewayLoopContext) -> GatewayConnectionProblem?
    {
        let nextProblem = self.mapNodeGatewayConnectionError(error)
        guard !self.isLocalGatewayFixtureEnabled,
              self.isCurrentGatewayRoute(
                  generation: context.routeGeneration,
                  stableID: context.stableID)
        else { return nil }
        self.recordNodeGatewayConnectionError(nextProblem, error: error)
        return nextProblem
    }

    private func recordNodeGatewayConnectionError(
        _ nextProblem: GatewayConnectionProblem?,
        error: Error)
    {
        if let nextProblem {
            if nextProblem == self.operatorGatewayProblem {
                // A node cancellation may echo an active operator approval failure. Keep its
                // control state owner-specific so resolving operator approval clears it cleanly.
                self.lastGatewayProblem = nextProblem
                self.gatewayStatusText = nextProblem.statusText
            } else {
                self.applyGatewayConnectionProblem(nextProblem)
            }
        } else {
            self.nodeGatewayProblem = nil
            if let operatorGatewayProblem {
                self.lastGatewayProblem = operatorGatewayProblem
                self.gatewayStatusText = operatorGatewayProblem.statusText
            } else {
                self.lastGatewayProblem = nil
                self.gatewayPairingPaused = false
                self.gatewayPairingRequestId = nil
                self.gatewayStatusText = "Gateway error: \(error.localizedDescription)"
            }
            self.gatewayServerName = nil
            self.gatewayRemoteAddress = nil
            self.gatewayConnected = false
            self.showLocalCanvasOnDisconnect()
        }
    }

    private func mapNodeGatewayConnectionError(_ error: Error) -> GatewayConnectionProblem? {
        GatewayConnectionProblemMapper.map(
            error: error,
            preserving: self.operatorGatewayProblem ?? self.nodeGatewayProblem)
    }

    private func resetNodeGatewayLoopStatusIfCurrent(_ context: NodeGatewayLoopContext) {
        guard self.credentialHandoffFailureGeneration != context.routeGeneration else { return }
        guard !self.isLocalGatewayFixtureEnabled,
              self.isCurrentGatewayRoute(
                  generation: context.routeGeneration,
                  stableID: context.stableID)
        else { return }
        self.nodeGatewayProblem = nil
        self.lastGatewayProblem = nil
        self.gatewayStatusText = "Offline"
        LiveActivityManager.shared.endActivity(reason: "gateway_loop_stopped")
        self.gatewayServerName = nil
        self.gatewayRemoteAddress = nil
        self.connectedGatewayID = nil
        self.gatewayConnected = false
        self.setOperatorConnected(false)
        self.talkMode.updateGatewayConnected(false)
        // Retain the last verified routing contract for offline capture; reconnect compares it
        // with the live gateway before replay.
        self.synchronizeTalkSessionKey()
        self.showLocalCanvasOnDisconnect()
    }

    private func shouldRequestOperatorApprovalScope(
        gatewayID: String,
        token: String?,
        password: String?,
        forceTalkPermissionUpgradeRequest: Bool = false) -> Bool
    {
        let storedOperatorScopes = DeviceIdentityStore.loadOrCreatePersisted()
            .flatMap { identity in
                DeviceAuthStore.loadToken(
                    deviceId: identity.deviceId,
                    role: "operator",
                    gatewayID: gatewayID)
            }?
            .scopes ?? []
        return Self.shouldRequestOperatorApprovalScope(
            token: token,
            password: password,
            storedOperatorScopes: storedOperatorScopes,
            forceTalkPermissionUpgradeRequest: forceTalkPermissionUpgradeRequest)
    }

    fileprivate nonisolated static func shouldRequestOperatorApprovalScope(
        token: String?,
        password: String?,
        storedOperatorScopes: [String],
        forceTalkPermissionUpgradeRequest: Bool = false) -> Bool
    {
        if forceTalkPermissionUpgradeRequest {
            return storedOperatorScopes.contains("operator.approvals")
        }
        let trimmedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedToken.isEmpty {
            return true
        }
        let trimmedPassword = password?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPassword.isEmpty {
            return true
        }
        return storedOperatorScopes.contains("operator.approvals")
    }

    private func shouldRequestOperatorAdminScope(
        gatewayID: String,
        token: String?,
        password: String?,
        forceTalkPermissionUpgradeRequest: Bool = false) -> Bool
    {
        let storedOperatorScopes = DeviceIdentityStore.loadOrCreatePersisted()
            .flatMap { identity in
                DeviceAuthStore.loadToken(
                    deviceId: identity.deviceId,
                    role: "operator",
                    gatewayID: gatewayID)
            }?
            .scopes ?? []
        return Self.shouldRequestOperatorAdminScope(
            token: token,
            password: password,
            storedOperatorScopes: storedOperatorScopes,
            forceTalkPermissionUpgradeRequest: forceTalkPermissionUpgradeRequest)
    }

    fileprivate nonisolated static func shouldRequestOperatorAdminScope(
        token: String?,
        password: String?,
        storedOperatorScopes: [String],
        forceTalkPermissionUpgradeRequest: Bool = false) -> Bool
    {
        if forceTalkPermissionUpgradeRequest {
            return false
        }
        let trimmedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedToken.isEmpty {
            return true
        }
        let trimmedPassword = password?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPassword.isEmpty {
            return true
        }
        return storedOperatorScopes.contains("operator.admin")
    }

    private func makeOperatorConnectOptions(
        clientId: String,
        displayName: String?,
        deviceAuthGatewayID: String? = nil,
        includeAdminScope: Bool = false,
        includeApprovalScope: Bool,
        forceExplicitScopes: Bool = false,
        allowStoredDeviceAuth: Bool = true) -> GatewayConnectOptions
    {
        var scopes = ["operator.read", "operator.write", "operator.talk.secrets"]
        if includeAdminScope {
            scopes.append("operator.admin")
        }
        // Older paired tokens request a scope upgrade before interactive prompts can arrive.
        if includeApprovalScope {
            scopes.append("operator.approvals")
            scopes.append("operator.questions")
        }
        return GatewayConnectOptions(
            role: "operator",
            scopes: scopes,
            scopesAreExplicit: forceExplicitScopes,
            caps: [NovaGatewayClientCapability.inlineWidgets],
            commands: [],
            permissions: [:],
            clientId: clientId,
            clientMode: "ui",
            clientDisplayName: displayName,
            includeDeviceIdentity: true,
            allowStoredDeviceAuth: allowStoredDeviceAuth,
            deviceAuthGatewayID: deviceAuthGatewayID)
    }

    private func legacyClientIdFallback(currentClientId: String, error: Error) -> String? {
        let normalizedClientId = currentClientId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedClientId == "nova-ios" else { return nil }
        let message = error.localizedDescription.lowercased()
        guard message.contains("invalid connect params"), message.contains("/client/id") else {
            return nil
        }
        return "moltbot-ios"
    }

    private func isOperatorConnected() async -> Bool {
        self.operatorConnected
    }

    private func setOperatorConnected(_ connected: Bool) {
        let changed = self.operatorConnected != connected
        self.operatorConnected = connected
        self.operatorStatusText = connected ? "Connected" : "Offline"
        self.refreshOperatorAdminScopeFromStore()
        guard connected else {
            guard changed else { return }
            Task { [weak self] in
                await self?.syncWatchAppSnapshot(reason: "operator_offline")
            }
            return
        }
        if changed {
            // Immediate retries are bounded per connection. A real reconnect grants queued
            // messages a fresh budget so one exhausted head cannot strand the durable outbox.
            self.watchMessageRetryAttempts.removeAll()
        }
        Task { [weak self] in
            guard let self else { return }
            await self.flushPendingExecApprovalResolvedPushes()
            var approvalStateIsAuthoritative = true
            if changed {
                approvalStateIsAuthoritative = await self.reconcileWatchExecApprovalCache(
                    reason: "operator_reconnected")
            }
            if changed, approvalStateIsAuthoritative {
                await self.flushPendingWatchExecApprovalResolutions()
            }
            await self.flushQueuedWatchMessagesIfAvailable()
            guard changed else { return }
            await self.syncWatchAppSnapshot(reason: "operator_online")
        }
    }

    private func refreshOperatorAdminScopeFromStore() {
        guard let config = activeGatewayConnectConfig else {
            self.hasOperatorAdminScope = false
            return
        }
        let gatewayID = config.nodeOptions.deviceAuthGatewayID ?? config.effectiveStableID
        self.hasOperatorAdminScope = DeviceIdentityStore.loadOrCreatePersisted()
            .flatMap { identity in
                DeviceAuthStore.loadToken(
                    deviceId: identity.deviceId,
                    role: "operator",
                    gatewayID: gatewayID)
            }?
            .scopes
            .contains("operator.admin") == true
    }
}

extension NodeAppModel {
    func enterAppleReviewDemoMode() {
        self.invalidateGatewayConnectAttempts()
        self.isAppleReviewDemoModeEnabled = true
        self.isScreenshotFixtureModeEnabled = false
        self.gatewayAutoReconnectEnabled = false
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.lastGatewayProblem = nil
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        self.credentialHandoffFailureGeneration = nil
        self.nodeGatewayTask?.cancel()
        self.nodeGatewayTask = nil
        self.operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        self.voiceWakeSyncTask?.cancel()
        self.voiceWakeSyncTask = nil
        self.gatewayHealthMonitor.stop()
        LiveActivityManager.shared.endActivity(reason: "apple_review_demo")

        Task {
            await self.operatorGateway.disconnect()
            await self.nodeGateway.disconnect()
        }

        self.gatewayStatusText = "Connected"
        self.nodeStatusText = "Connected"
        self.gatewayServerName = AppleReviewDemoMode.gatewayName
        self.gatewayRemoteAddress = AppleReviewDemoMode.gatewayAddress
        self.connectedGatewayID = AppleReviewDemoMode.gatewayID
        self.activeGatewayConnectConfig = nil
        self.gatewayConnected = true
        self.setOperatorConnected(false)
        UserDefaults.standard.set(false, forKey: "talk.enabled")
        UserDefaults.standard.set(false, forKey: "talk.background.enabled")
        self.talkMode.updateGatewayConnected(false)
        self.talkMode.setEnabled(false)
        self.talkMode.statusText = "Demo mode only"
        self.mainSessionBaseKey = "main"
        self.gatewaySessionScope = "per-sender"
        self.selectedAgentId = nil
        self.gatewayDefaultAgentId = "main"
        self.gatewayAgents = AppleReviewDemoMode.agents
        self.focusedChatSessionKey = nil
        self.synchronizeTalkSessionKey()
        self.homeCanvasRevision &+= 1
    }

    func enterScreenshotFixtureMode() {
        self.invalidateGatewayConnectAttempts()
        self.isAppleReviewDemoModeEnabled = false
        self.isScreenshotFixtureModeEnabled = true
        self.gatewayAutoReconnectEnabled = false
        self.gatewayPairingPaused = false
        self.gatewayPairingRequestId = nil
        self.lastGatewayProblem = nil
        self.nodeGatewayProblem = nil
        self.operatorGatewayProblem = nil
        self.nodeGatewayTask?.cancel()
        self.nodeGatewayTask = nil
        self.operatorGatewayTask?.cancel()
        self.operatorGatewayTask = nil
        self.voiceWakeSyncTask?.cancel()
        self.voiceWakeSyncTask = nil
        self.gatewayHealthMonitor.stop()
        LiveActivityManager.shared.endActivity(reason: "screenshot_fixture")

        Task {
            await self.operatorGateway.disconnect()
            await self.nodeGateway.disconnect()
        }

        self.gatewayStatusText = "Connected"
        self.nodeStatusText = "Connected"
        self.gatewayServerName = ScreenshotFixtureMode.gatewayName
        self.gatewayRemoteAddress = ScreenshotFixtureMode.gatewayAddress
        self.connectedGatewayID = ScreenshotFixtureMode.gatewayID
        self.activeGatewayConnectConfig = nil
        self.gatewayConnected = true
        self.setOperatorConnected(true)
        self.hasOperatorAdminScope = true
        self.mainSessionBaseKey = "main"
        self.gatewaySessionScope = "per-sender"
        self.selectedAgentId = nil
        self.gatewayDefaultAgentId = "main"
        self.gatewayAgents = ScreenshotFixtureMode.agents
        self.focusedChatSessionKey = nil
        self.synchronizeTalkSessionKey()
        self.talkMode.enterScreenshotFixtureMode()
        self.homeCanvasRevision &+= 1
    }
}

extension NodeAppModel {
    private struct PendingForegroundNodeAction: Decodable {
        var id: String
        var command: String
        var paramsJSON: String?
        var enqueuedAtMs: Int?
    }

    private struct PendingForegroundNodeActionsResponse: Decodable {
        var nodeId: String?
        var actions: [PendingForegroundNodeAction]
    }

    private struct PendingForegroundNodeActionsAckRequest: Encodable {
        var ids: [String]
    }

    private func refreshShareRouteFromGateway(shouldApply: () -> Bool = { true }) async {
        struct SessionRow: Decodable {
            var key: String
            var updatedAt: Double?
            var lastChannel: String?
            var lastTo: String?
        }
        struct SessionsListResult: Decodable {
            var sessions: [SessionRow]
        }

        let normalize: (String?) -> String? = { raw in
            let value = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        do {
            let request = NovaChatGatewayRequests.sessionsList(
                limit: 80,
                search: nil,
                archived: false,
                timeoutMs: 10000)
            let response = try await operatorGateway.request(request)
            let decoded = try JSONDecoder().decode(SessionsListResult.self, from: response)
            let currentKey = self.mainSessionKey
            let sorted = decoded.sessions.sorted { ($0.updatedAt ?? 0) > ($1.updatedAt ?? 0) }
            let exactMatch = sorted.first { row in
                row.key == currentKey && normalize(row.lastChannel) != nil && normalize(row.lastTo) != nil
            }
            let selected = exactMatch
            let channel = normalize(selected?.lastChannel)
            let to = normalize(selected?.lastTo)

            guard shouldApply() else { return }
            await MainActor.run {
                self.shareDeliveryChannel = channel
                self.shareDeliveryTo = to
                if let relay = ShareGatewayRelaySettings.loadConfig() {
                    ShareGatewayRelaySettings.saveConfig(
                        ShareGatewayRelayConfig(
                            gatewayURLString: relay.gatewayURLString,
                            gatewayStableID: relay.gatewayStableID,
                            token: relay.token,
                            password: relay.password,
                            sessionKey: self.mainSessionKey,
                            deliveryChannel: channel,
                            deliveryTo: to))
                }
            }
        } catch {
            // Best-effort only.
        }
    }

    func runSharePipelineSelfTest() async {
        self.recordShareEvent("Share self-test running…")

        let payload = SharedContentPayload(
            title: "Nova Share Self-Test",
            url: URL(string: "https://nova.ai/share-self-test"),
            text: "Validate iOS share->deep-link->gateway forwarding.")
        guard let deepLink = ShareToAgentDeepLink.buildURL(
            from: payload,
            instruction: "Reply with: SHARE SELF-TEST OK")
        else {
            self.recordShareEvent("Self-test failed: could not build deep link.")
            return
        }

        await handleDeepLink(url: deepLink)
    }

    func refreshLastShareEventFromRelay() {
        if let event = ShareGatewayRelaySettings.loadLastEvent() {
            self.lastShareEventText = event
        }
    }

    func recordShareEvent(_ text: String) {
        ShareGatewayRelaySettings.saveLastEvent(text)
        self.refreshLastShareEventFromRelay()
    }

    /// Back-compat hook retained for older gateway-connect flows.
    func onNodeGatewayConnected(
        shouldContinue: @MainActor @Sendable () -> Bool = { true }) async
    {
        guard shouldContinue() else { return }
        await self.registerAPNsTokenIfNeeded(shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        await self.syncWatchAppSnapshot(
            reason: "node_connected",
            includeChat: true,
            shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        await self.syncWatchExecApprovalSnapshot(
            reason: "node_connected",
            shouldContinue: shouldContinue)
        guard shouldContinue() else { return }
        await self.resumePendingForegroundNodeActionsIfNeeded(
            trigger: "node_connected",
            shouldContinue: shouldContinue)
    }

    private func resumePendingForegroundNodeActionsIfNeeded(
        trigger: String,
        shouldContinue: @MainActor @Sendable () -> Bool = { true }) async
    {
        guard shouldContinue() else { return }
        guard !self.isBackgrounded else { return }
        guard await isGatewayConnected() else { return }
        guard !self.pendingForegroundActionDrainInFlight else {
            self.pendingForegroundActionDrainRequested = true
            return
        }

        self.pendingForegroundActionDrainInFlight = true
        defer {
            self.pendingForegroundActionDrainInFlight = false
            if self.pendingForegroundActionDrainRequested {
                self.pendingForegroundActionDrainRequested = false
                // Serialize non-idempotent action execution, then retry against whichever
                // exact route is current after the suspended drain has unwound.
                Task { @MainActor [weak self] in
                    await self?.resumePendingForegroundNodeActionsIfNeeded(trigger: "coalesced")
                }
            }
        }

        let routeGeneration = self.gatewayRouteGeneration
        guard let gatewayStableID = self.connectedGatewayID,
              let nodeRoute = await self.nodeGateway.currentRoute(),
              shouldContinue(),
              self.isCurrentGatewayRoute(generation: routeGeneration, stableID: gatewayStableID)
        else { return }

        do {
            let routeContext = GatewaySessionRouteContext(
                route: nodeRoute,
                gatewayStableID: gatewayStableID,
                routeGeneration: routeGeneration)
            let payload = try await nodeGateway.request(
                method: "node.pending.pull",
                paramsJSON: "{}",
                timeoutSeconds: 6,
                ifCurrentRoute: nodeRoute)
            let decoded = try JSONDecoder().decode(
                PendingForegroundNodeActionsResponse.self,
                from: payload)
            guard await self.isCurrentGatewaySessionRoute(
                routeContext,
                session: self.nodeGateway,
                shouldContinue: shouldContinue)
            else { return }
            self.retainCompletedPendingForegroundActionIDs(
                presentIn: decoded.actions,
                gatewayStableID: gatewayStableID)
            guard !decoded.actions.isEmpty else { return }
            self.pendingActionLogger
                .info("pending actions trigger=\(trigger, privacy: .public)")
            self.pendingActionLogger.info("pending actions count=\(decoded.actions.count, privacy: .public)")
            await self.applyPendingForegroundNodeActions(
                decoded.actions,
                trigger: trigger,
                routeContext: routeContext,
                shouldContinue: shouldContinue)
        } catch {
            // Best-effort only.
        }
    }

    private func applyPendingForegroundNodeActions(
        _ actions: [PendingForegroundNodeAction],
        trigger: String,
        routeContext: GatewaySessionRouteContext? = nil,
        shouldContinue: @MainActor @Sendable () -> Bool = { true }) async
    {
        for action in actions {
            guard shouldContinue() else { return }
            if let routeContext {
                guard await self.isCurrentGatewaySessionRoute(
                    routeContext,
                    session: self.nodeGateway,
                    shouldContinue: shouldContinue)
                else { return }
            }
            guard !self.isBackgrounded else {
                self.pendingActionLogger.info(
                    "Pending action replay paused trigger=\(trigger, privacy: .public): app backgrounded")
                return
            }
            let req = BridgeInvokeRequest(
                id: action.id,
                command: action.command,
                paramsJSON: action.paramsJSON)
            let gatewayStableID = routeContext?.gatewayStableID
            let alreadyCompleted = gatewayStableID.map {
                self.completedPendingForegroundActionIDsByGateway[$0]?.contains(action.id) == true
            } ?? false
            if !alreadyCompleted {
                let result = await handleInvoke(
                    req,
                    gatewayStableID: gatewayStableID ?? self.connectedGatewayID)
                self.pendingActionLogger
                    .info("pending replay trigger=\(trigger, privacy: .public) id=\(action.id, privacy: .public)")
                self.pendingActionLogger.info("pending replay ok=\(result.ok, privacy: .public)")
                self.pendingActionLogger.info("pending replay command=\(action.command, privacy: .public)")
                guard result.ok else { return }
                if let gatewayStableID {
                    // The gateway queue is connection-independent. Remember successful local
                    // execution until its source gateway accepts the ACK so reconnects cannot replay it.
                    self.completedPendingForegroundActionIDsByGateway[gatewayStableID, default: []]
                        .insert(action.id)
                }
                guard shouldContinue() else { return }
            }
            let acked = await ackPendingForegroundNodeAction(
                id: action.id,
                trigger: trigger,
                command: action.command,
                routeContext: routeContext)
            guard acked else { return }
            if let gatewayStableID {
                self.removeCompletedPendingForegroundActionID(
                    action.id,
                    gatewayStableID: gatewayStableID)
            }
        }
    }

    private func retainCompletedPendingForegroundActionIDs(
        presentIn actions: [PendingForegroundNodeAction],
        gatewayStableID: String)
    {
        guard let completed = self.completedPendingForegroundActionIDsByGateway[gatewayStableID] else {
            return
        }
        let retained = completed.intersection(actions.map(\.id))
        if retained.isEmpty {
            self.completedPendingForegroundActionIDsByGateway.removeValue(forKey: gatewayStableID)
        } else {
            self.completedPendingForegroundActionIDsByGateway[gatewayStableID] = retained
        }
    }

    private func removeCompletedPendingForegroundActionID(
        _ id: String,
        gatewayStableID: String)
    {
        self.completedPendingForegroundActionIDsByGateway[gatewayStableID]?.remove(id)
        if self.completedPendingForegroundActionIDsByGateway[gatewayStableID]?.isEmpty == true {
            self.completedPendingForegroundActionIDsByGateway.removeValue(forKey: gatewayStableID)
        }
    }

    private func isCurrentGatewaySessionRoute(
        _ context: GatewaySessionRouteContext,
        session: GatewayNodeSession,
        shouldContinue: @MainActor @Sendable () -> Bool) async -> Bool
    {
        guard shouldContinue(),
              self.isCurrentGatewayRoute(
                  generation: context.routeGeneration,
                  stableID: context.gatewayStableID)
        else { return false }
        guard await session.currentRoute() == context.route else { return false }
        return shouldContinue() &&
            self.isCurrentGatewayRoute(
                generation: context.routeGeneration,
                stableID: context.gatewayStableID)
    }

    private func ackPendingForegroundNodeAction(
        id: String,
        trigger: String,
        command: String,
        routeContext: GatewaySessionRouteContext?) async -> Bool
    {
        do {
            let expectedRoute: GatewayNodeSessionRoute?
            if let routeContext {
                guard GatewayStableIdentifier.matches(
                    self.activeGatewayConnectConfig?.effectiveStableID,
                    routeContext.gatewayStableID),
                    let currentRoute = await self.nodeGateway.currentRoute(),
                    GatewayStableIdentifier.matches(
                        self.activeGatewayConnectConfig?.effectiveStableID,
                        routeContext.gatewayStableID)
                else { return false }
                expectedRoute = currentRoute
            } else {
                expectedRoute = nil
            }
            let payload = try JSONEncoder().encode(PendingForegroundNodeActionsAckRequest(ids: [id]))
            let paramsJSON = String(bytes: payload, encoding: .utf8) ?? "{}"
            _ = try await self.nodeGateway.request(
                method: "node.pending.ack",
                paramsJSON: paramsJSON,
                timeoutSeconds: 6,
                ifCurrentRoute: expectedRoute)
            return true
        } catch {
            self.pendingActionLogger
                .error("pending ack failed trigger=\(trigger, privacy: .public) id=\(id, privacy: .public)")
            self.pendingActionLogger.error("pending ack command=\(command, privacy: .public)")
            self.pendingActionLogger.error("pending ack error=\(String(describing: error), privacy: .public)")
            return false
        }
    }

    private func handleWatchQuickReply(_ event: WatchQuickReplyEvent) async {
        let replyID = event.replyId.trimmingCharacters(in: .whitespacesAndNewlines)
        let actionID = event.actionId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !replyID.isEmpty, !actionID.isEmpty else {
            self.watchReplyLogger.info("watch reply dropped: missing replyId/actionId")
            return
        }
        let payloadGatewayID = GatewayStableIdentifier.exact(event.gatewayStableID)
        let currentGatewayID = self.currentWatchChatGatewayStableID()
        let routedGatewayID = GatewayStableIdentifier.exact(
            self.watchMessageOutbox.gatewayStableID(forPromptID: event.promptId))
        let sourceGatewayID: String? = if let payloadGatewayID {
            payloadGatewayID
        } else if let routedGatewayID {
            routedGatewayID
        } else {
            nil
        }
        if let sourceGatewayID,
           let currentGatewayID,
           !GatewayStableIdentifier.matches(currentGatewayID, sourceGatewayID)
        {
            self.watchReplyLogger.info("watch reply dropped: stale gateway target")
            return
        }
        guard let sourceGatewayID else {
            self.watchReplyLogger.info("watch reply dropped: unresolved gateway target")
            return
        }
        let gatewayStableID = sourceGatewayID

        let message = WatchAppCommandEvent(
            commandId: replyID,
            command: .sendChat,
            sessionKey: event.sessionKey,
            gatewayStableID: gatewayStableID,
            text: Self.makeWatchReplyAgentMessage(event),
            sentAtMs: event.sentAtMs,
            transport: event.transport,
            messageKind: .quickReply)
        let needsReconnect = !self.isWatchMessageSendAvailable()
        await self.handleWatchMessage(message)
        guard needsReconnect else { return }

        let connected = await ensureOperatorApprovalConnectionForWatchReview(
            timeoutMs: 12000,
            reason: "watch_reply")
        guard connected,
              GatewayStableIdentifier.matches(
                  self.currentWatchChatGatewayStableID(),
                  gatewayStableID)
        else {
            self.watchReplyLogger.info("watch reply remains queued: gateway target unavailable")
            return
        }
        await self.flushQueuedWatchMessagesIfAvailable()
    }

    private static func makeWatchReplyAgentMessage(_ event: WatchQuickReplyEvent) -> String {
        let actionLabel = event.actionLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let promptId = event.promptId.trimmingCharacters(in: .whitespacesAndNewlines)
        let transport = event.transport.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = actionLabel?.isEmpty == false ? actionLabel! : event.actionId
        var lines: [String] = []
        lines.append("Watch reply: \(summary)")
        lines.append("promptId=\(promptId.isEmpty ? "unknown" : promptId)")
        lines.append("actionId=\(event.actionId)")
        lines.append("replyId=\(event.replyId)")
        if !transport.isEmpty {
            lines.append("transport=\(transport)")
        }
        if let sentAtMs = event.sentAtMs {
            lines.append("sentAtMs=\(sentAtMs)")
        }
        if let note = event.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("note=\(note)")
        }
        return lines.joined(separator: "\n")
    }

    private func restorePersistedWatchExecApprovalBridgeState() {
        guard let data = UserDefaults.standard.data(forKey: Self.watchExecApprovalBridgeStateKey),
              let state = try? JSONDecoder().decode(PersistedWatchExecApprovalBridgeState.self, from: data)
        else {
            return
        }
        // Shipped caches before unified approvals have no owner kind. Preserve only
        // their exact ID + gateway owner until approval.get rebuilds canonical state.
        let typedApprovals = state.approvals.filter {
            guard let kind = ApprovalKind(rawValue: $0.kind ?? "") else { return false }
            return kind == .exec || kind == .plugin
        }
        self.watchExecApprovalPromptsByID = typedApprovals.reduce(into: [:]) { result, prompt in
            guard let approvalID = Self.execApprovalIDKey(prompt.id) else { return }
            result[approvalID] = prompt
        }
        let legacyReadbacks = state.approvals.compactMap { prompt -> PersistedExecApprovalReadback? in
            guard prompt.kind == nil else { return nil }
            return PersistedExecApprovalReadback(
                approvalId: prompt.id,
                gatewayStableID: prompt.gatewayStableID)
        }
        var restoredReadbacks = Set<PersistedExecApprovalReadbackKey>()
        self.pendingPersistedExecApprovalReadbacks = ((state.pendingApprovalReadbacks ?? []) + legacyReadbacks)
            .filter { readback in
                guard let key = Self.persistedExecApprovalReadbackKey(readback) else { return false }
                return restoredReadbacks.insert(key).inserted
            }
            .sorted(by: Self.persistedExecApprovalReadbackSortsBefore)
        var restoredUncertainties = Set<ExecApprovalResolutionKey>()
        let persistedUncertainties = state.approvalUncertainties ?? []
        self.execApprovalUncertainties = persistedUncertainties.reduce(into: [:]) { result, uncertainty in
            guard !uncertainty.message.isEmpty,
                  let key = Self.persistedExecApprovalUncertaintyKey(uncertainty),
                  restoredUncertainties.insert(key).inserted
            else { return }
            result[key] = ExecApprovalUncertaintyState(
                token: UUID(),
                message: uncertainty.message)
        }
        for key in restoredUncertainties where !restoredReadbacks.contains(
            PersistedExecApprovalReadbackKey(
                approvalID: key.approvalID,
                gatewayID: key.gatewayID))
        {
            self.pendingPersistedExecApprovalReadbacks.append(PersistedExecApprovalReadback(
                approvalId: key.approvalID.rawValue,
                gatewayStableID: key.gatewayID.rawValue))
        }
        self.pendingPersistedExecApprovalReadbacks.sort(
            by: Self.persistedExecApprovalReadbackSortsBefore)
        var restoredPushes = Set<ExecApprovalPushKey>()
        self.pendingWatchExecApprovalRecoveryPushes = (state.pendingApprovalPushes ?? [])
            .filter { push in
                guard push.gatewayDeviceId?.isEmpty != true,
                      let pushKey = Self.execApprovalPushKey(push)
                else { return false }
                return restoredPushes.insert(pushKey).inserted
            }
            .sorted(by: Self.execApprovalPushSortsBefore)
        var restoredResolvedPushes = Set<ExecApprovalPushKey>()
        self.pendingExecApprovalResolvedPushes = (state.pendingResolvedPushes ?? [])
            .filter { push in
                guard push.gatewayDeviceId?.isEmpty != true,
                      let pushKey = Self.execApprovalPushKey(push)
                else { return false }
                return restoredResolvedPushes.insert(pushKey).inserted
            }
            .sorted(by: Self.execApprovalPushSortsBefore)
        var restoredReplyIDs = Set<String>()
        self.pendingWatchExecApprovalResolutions = Array((state.pendingResolutions ?? []).filter { event in
            let replyID = event.replyId.trimmingCharacters(in: .whitespacesAndNewlines)
            let approvalID = Self.validatedApprovalID(event.approvalId)
            let gatewayID = GatewayStableIdentifier.exact(event.gatewayStableID)
            return !replyID.isEmpty &&
                approvalID != nil &&
                gatewayID != nil &&
                restoredReplyIDs.insert(replyID).inserted
        }.suffix(32))
        self.pruneExpiredWatchExecApprovalPrompts()
        // This persisted cache backs the phone inbox too. Restore every supported kind
        // here; Watch publication applies its exec-only filter at the delivery boundary.
        for prompt in self.watchExecApprovalPromptsByID.values {
            guard let inboxKey = Self.execApprovalInboxKey(prompt) else { continue }
            self.execApprovalInboxPromptsByKey[inboxKey] = prompt
        }
        self.persistWatchExecApprovalBridgeState()
    }

    private func currentExecApprovalGatewayStableID() -> String? {
        let stableID = self.activeGatewayConnectConfig?.effectiveStableID
            ?? self.connectedGatewayID
        return GatewayStableIdentifier.exact(stableID)
    }

    private func isExecApprovalPromptCurrent(_ prompt: ExecApprovalPrompt) -> Bool {
        guard let kind = ApprovalKind(rawValue: prompt.kind ?? ""),
              kind == .exec || kind == .plugin
        else { return false }
        return GatewayStableIdentifier.matches(
            self.currentExecApprovalGatewayStableID(),
            prompt.gatewayStableID)
    }

    private func isWatchExecApprovalPromptCurrent(_ prompt: ExecApprovalPrompt) -> Bool {
        prompt.kind == ApprovalKind.exec.rawValue &&
            GatewayStableIdentifier.matches(
                self.currentExecApprovalGatewayStableID(),
                prompt.gatewayStableID)
    }

    private func invalidateExecApprovalSurfacesForGatewayChange() {
        self.pendingExecApprovalPromptRequestGeneration &+= 1
        self.dismissPendingExecApprovalPrompt()
        self.pendingNotificationPermissionGuidancePrompt = nil
        self.watchExecApprovalPromptsByID.removeAll()
        self.execApprovalInboxPromptsByKey.removeAll()
        self.dismissedExecApprovalPresentationKeys.removeAll()
        self.terminalExecApprovalKeys.removeAll()
        self.terminalExecApprovalKeyOrder.removeAll()
        self.resettableWatchResolutionAttempts.removeAll()
        // In-flight resolution attempts are owner-scoped write fences keyed by
        // (approvalID, gatewayStableID). They must survive a target switch so returning
        // to the owner cannot double-submit while the original write outcome is unknown;
        // completion defers and terminal cleanup remove them per key.
        // Uncertainties are owner-scoped durable records of lost write outcomes, not
        // gateway-local UI. They must survive a target switch so returning to the owner
        // keeps that approval frozen until approval.get classifies it canonically.
        let requestedPushes = self.pendingWatchExecApprovalRecoveryPushes
        self.pendingWatchExecApprovalRecoveryPushes.removeAll()
        let resolvedPushes = self.pendingExecApprovalResolvedPushes
        self.pendingExecApprovalResolvedPushes.removeAll()
        self.persistWatchExecApprovalBridgeState()
        Task { @MainActor [weak self] in
            if let self {
                // Keep notification pushes until terminal state so route invalidation can remove
                // only alerts owned by the old gateway, never a newly delivered replacement.
                var seen = Set<ExecApprovalPushKey>()
                for push in requestedPushes + resolvedPushes {
                    guard let pushKey = Self.execApprovalPushKey(push),
                          seen.insert(pushKey).inserted
                    else { continue }
                    await ApprovalNotificationBridge.removeNotifications(
                        for: push,
                        notificationCenter: self.notificationCenter)
                }
            }
            await self?.syncWatchExecApprovalSnapshot(reason: "gateway_changed")
        }
    }

    private func persistWatchExecApprovalBridgeState() {
        self.pruneExpiredWatchExecApprovalPrompts()
        let approvals = self.watchExecApprovalPromptsByID.values.sorted { lhs, rhs in
            let lhsExpires = lhs.expiresAtMs ?? Int64.max
            let rhsExpires = rhs.expiresAtMs ?? Int64.max
            if lhsExpires != rhsExpires {
                return lhsExpires < rhsExpires
            }
            return Self.approvalIDSortsBefore(lhs.id, rhs.id)
        }
        let pendingApprovalPushes = self.pendingWatchExecApprovalRecoveryPushes
            .sorted(by: Self.execApprovalPushSortsBefore)
        let pendingResolvedPushes = self.pendingExecApprovalResolvedPushes
            .sorted(by: Self.execApprovalPushSortsBefore)
        let approvalUncertainties = self.execApprovalUncertainties.map { key, state in
            PersistedExecApprovalUncertainty(
                approvalId: key.approvalID.rawValue,
                gatewayStableID: key.gatewayID.rawValue,
                message: state.message)
        }.sorted(by: Self.persistedExecApprovalUncertaintySortsBefore)
        guard let data = try? JSONEncoder().encode(
            PersistedWatchExecApprovalBridgeState(
                approvals: approvals,
                pendingApprovalReadbacks: self.pendingPersistedExecApprovalReadbacks,
                approvalUncertainties: approvalUncertainties,
                pendingApprovalPushes: pendingApprovalPushes,
                pendingResolvedPushes: pendingResolvedPushes,
                pendingResolutions: pendingWatchExecApprovalResolutions))
        else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.watchExecApprovalBridgeStateKey)
    }

    private func pruneExpiredWatchExecApprovalPrompts(nowMs: Int64? = nil) {
        let currentNowMs = nowMs ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.watchExecApprovalPromptsByID = self.watchExecApprovalPromptsByID.filter { _, prompt in
            guard let expiresAtMs = prompt.expiresAtMs else { return true }
            return expiresAtMs > currentNowMs
        }
    }

    private func handleWatchMessagingStatusChanged(_ status: WatchMessagingStatus) async {
        self.watchMessagingStatus = status
        GatewayDiagnostics.log(
            "watch exec approval: status changed "
                + "reachable=\(status.reachable) activation=\(status.activationState) "
                + "backgrounded=\(self.isBackgrounded)")
        guard status.supported, status.paired, status.appInstalled else { return }
        guard status.reachable || status.activationState == "activated" else { return }
        let reason = status.reachable ? "watch_reachable" : "watch_activated"
        await self.syncWatchAppSnapshot(reason: reason, includeChat: status.reachable)
        guard self.isBackgrounded else { return }
        await self.syncWatchExecApprovalSnapshot(reason: reason)
    }

    private func appendPendingWatchExecApprovalRecoveryPush(_ push: ExecApprovalNotificationPrompt) {
        guard let pushKey = Self.execApprovalPushKey(push),
              !self.pendingWatchExecApprovalRecoveryPushes.contains(where: {
                  Self.execApprovalPushKey($0) == pushKey
              })
        else { return }
        self.pendingWatchExecApprovalRecoveryPushes.append(push)
        self.pendingWatchExecApprovalRecoveryPushes.sort(by: Self.execApprovalPushSortsBefore)
        GatewayDiagnostics.log(
            "watch exec approval: queued recovery "
                + "id=\(push.approvalId) pendingCount=\(self.pendingWatchExecApprovalRecoveryPushes.count)")
        self.persistWatchExecApprovalBridgeState()
    }

    private func removePendingWatchExecApprovalRecoveryPush(_ push: ExecApprovalNotificationPrompt) {
        guard let pushKey = Self.execApprovalPushKey(push) else { return }
        let originalCount = self.pendingWatchExecApprovalRecoveryPushes.count
        self.pendingWatchExecApprovalRecoveryPushes.removeAll {
            Self.execApprovalPushKey($0) == pushKey
        }
        guard self.pendingWatchExecApprovalRecoveryPushes.count != originalCount else { return }
        GatewayDiagnostics.log(
            "watch exec approval: cleared recovery "
                + "id=\(push.approvalId) pendingCount=\(self.pendingWatchExecApprovalRecoveryPushes.count)")
        self.persistWatchExecApprovalBridgeState()
    }

    private func appendPendingExecApprovalResolvedPush(_ push: ExecApprovalNotificationPrompt) {
        guard let pushKey = Self.execApprovalPushKey(push),
              !self.pendingExecApprovalResolvedPushes.contains(where: {
                  Self.execApprovalPushKey($0) == pushKey
              })
        else { return }
        // A silent resolution push is not replayed by the gateway. Keep it until the
        // authenticated owner route returns so its matching notification cannot linger.
        self.pendingExecApprovalResolvedPushes.append(push)
        if self.pendingExecApprovalResolvedPushes.count > 32 {
            self.pendingExecApprovalResolvedPushes.removeFirst()
        }
        self.pendingExecApprovalResolvedPushes.sort(by: Self.execApprovalPushSortsBefore)
        self.persistWatchExecApprovalBridgeState()
    }

    private func removePendingExecApprovalResolvedPush(_ push: ExecApprovalNotificationPrompt) {
        guard let pushKey = Self.execApprovalPushKey(push) else { return }
        let originalCount = self.pendingExecApprovalResolvedPushes.count
        self.pendingExecApprovalResolvedPushes.removeAll {
            Self.execApprovalPushKey($0) == pushKey
        }
        guard self.pendingExecApprovalResolvedPushes.count != originalCount else { return }
        self.persistWatchExecApprovalBridgeState()
    }

    private func removePendingPersistedExecApprovalReadback(
        _ readback: PersistedExecApprovalReadback)
    {
        guard let readbackKey = Self.persistedExecApprovalReadbackKey(readback) else { return }
        let originalCount = self.pendingPersistedExecApprovalReadbacks.count
        self.pendingPersistedExecApprovalReadbacks.removeAll {
            Self.persistedExecApprovalReadbackKey($0) == readbackKey
        }
        guard self.pendingPersistedExecApprovalReadbacks.count != originalCount else { return }
        self.persistWatchExecApprovalBridgeState()
    }

    private func appendPendingPersistedExecApprovalReadback(
        approvalId: String,
        gatewayStableID: String)
    {
        let readback = PersistedExecApprovalReadback(
            approvalId: approvalId,
            gatewayStableID: gatewayStableID)
        guard let readbackKey = Self.persistedExecApprovalReadbackKey(readback),
              !self.pendingPersistedExecApprovalReadbacks.contains(where: {
                  Self.persistedExecApprovalReadbackKey($0) == readbackKey
              })
        else { return }
        // A requested event is an edge trigger, not replayed state. Retain its exact owner
        // until approval.get classifies it so a reconnect cannot lose a parked approval.
        self.pendingPersistedExecApprovalReadbacks.append(readback)
        if self.pendingPersistedExecApprovalReadbacks.count > 64 {
            self.pendingPersistedExecApprovalReadbacks.removeFirst()
        }
        self.pendingPersistedExecApprovalReadbacks.sort(
            by: Self.persistedExecApprovalReadbackSortsBefore)
        self.persistWatchExecApprovalBridgeState()
    }

    private func upsertWatchExecApprovalPrompt(_ prompt: ExecApprovalPrompt) {
        guard self.isExecApprovalPromptCurrent(prompt),
              let approvalID = Self.execApprovalIDKey(prompt.id),
              let inboxKey = Self.execApprovalInboxKey(prompt),
              !self.terminalExecApprovalKeys.contains(inboxKey)
        else { return }
        self.watchExecApprovalPromptsByID[approvalID] = prompt
        self.execApprovalInboxPromptsByKey[inboxKey] = prompt
        self.persistWatchExecApprovalBridgeState()
    }

    private func markExecApprovalOwnerTerminal(
        approvalId: String,
        gatewayStableID: String)
    {
        guard let approvalID = Self.execApprovalIDKey(approvalId),
              let inboxKey = Self.execApprovalInboxKey(
                  approvalID: approvalId,
                  gatewayStableID: gatewayStableID)
        else { return }
        if self.terminalExecApprovalKeys.insert(inboxKey).inserted {
            self.terminalExecApprovalKeyOrder.append(inboxKey)
            if self.terminalExecApprovalKeyOrder.count > 256 {
                let evictedKey = self.terminalExecApprovalKeyOrder.removeFirst()
                self.terminalExecApprovalKeys.remove(evictedKey)
            }
        }
        self.execApprovalInboxPromptsByKey.removeValue(forKey: inboxKey)
        self.dismissedExecApprovalPresentationKeys.remove(inboxKey)
        self.resettableWatchResolutionAttempts.removeValue(forKey: inboxKey)
        self.activeExecApprovalResolutionAttempts.removeValue(forKey: inboxKey)
        self.execApprovalUncertainties.removeValue(forKey: inboxKey)
        self.pendingPersistedExecApprovalReadbacks.removeAll {
            Self.persistedExecApprovalReadbackKey($0) == PersistedExecApprovalReadbackKey(
                approvalID: inboxKey.approvalID,
                gatewayID: inboxKey.gatewayID)
        }
        if GatewayStableIdentifier.matches(
            self.watchExecApprovalPromptsByID[approvalID]?.gatewayStableID,
            gatewayStableID)
        {
            self.watchExecApprovalPromptsByID.removeValue(forKey: approvalID)
        }
        self.persistWatchExecApprovalBridgeState()
    }

    private static func makeWatchExecApprovalItem(from prompt: ExecApprovalPrompt) -> NovaWatchExecApprovalItem {
        let decisions = prompt.allowedDecisions.compactMap(NovaWatchExecApprovalDecision.init(rawValue:))
        let preview = Self.trimmedOrNil(prompt.commandPreview) ?? Self.trimmedOrNil(prompt.commandText)
        return NovaWatchExecApprovalItem(
            id: prompt.id,
            gatewayStableID: prompt.gatewayStableID,
            commandText: prompt.commandText,
            commandPreview: preview,
            warningText: Self.trimmedOrNil(prompt.warningText),
            host: Self.trimmedOrNil(prompt.host),
            nodeId: Self.trimmedOrNil(prompt.nodeId),
            agentId: Self.trimmedOrNil(prompt.agentId),
            expiresAtMs: prompt.expiresAtMs,
            allowedDecisions: decisions,
            // Prefer the watch's neutral/default presentation until approval.get
            // carries an explicit risk signal for exec approvals.
            risk: nil)
    }

    private func publishWatchExecApprovalPrompt(
        _ prompt: ExecApprovalPrompt,
        reason: String,
        resetResolutionAttemptId: String? = nil,
        syncSnapshots: Bool = true) async
    {
        guard self.isWatchExecApprovalPromptCurrent(prompt),
              let inboxKey = Self.execApprovalInboxKey(prompt),
              !self.terminalExecApprovalKeys.contains(inboxKey)
        else { return }
        let deliveryGeneration = self.gatewayConnectGeneration
        let message = NovaWatchExecApprovalPromptMessage(
            approval: Self.makeWatchExecApprovalItem(from: prompt),
            sentAtMs: Int64(Date().timeIntervalSince1970 * 1000),
            resetResolutionAttemptId: resetResolutionAttemptId)
        do {
            _ = try await self.watchMessagingService.sendExecApprovalPrompt(message)
            self.watchExecApprovalLogger.debug(
                "watch exec approval prompt sent id=\(prompt.id, privacy: .public) reason=\(reason, privacy: .public)")
        } catch {
            self.watchExecApprovalLogger
                .error(
                    "watch approval prompt failed id=\(prompt.id, privacy: .public) reason=\(reason, privacy: .public)")
            self.watchExecApprovalLogger.error(
                "watch approval prompt error=\(error.localizedDescription, privacy: .public)")
        }
        guard syncSnapshots else { return }
        if deliveryGeneration != self.gatewayConnectGeneration {
            // WatchConnectivity may finish by durably queueing the old payload after a route
            // switch. Publish the replacement owner snapshots after that send completes.
            await self.syncWatchAppSnapshot(reason: "\(reason)_route_repair")
            await self.syncWatchExecApprovalSnapshot(reason: "\(reason)_route_repair")
            return
        }
        await self.syncWatchAppSnapshot(reason: "\(reason)_app")
        await self.syncWatchExecApprovalSnapshot(reason: "\(reason)_snapshot")
    }

    private func publishWatchExecApprovalResolved(
        approvalId: String,
        gatewayStableID: String,
        decision: NovaWatchExecApprovalDecision?,
        outcome: NovaWatchExecApprovalOutcome,
        outcomeText: String,
        resolvedAtMs: Int64? = nil,
        source: String,
        syncSnapshots: Bool = true) async
    {
        guard let approvalID = Self.validatedApprovalID(approvalId),
              Self.execApprovalIDKey(approvalID) != nil
        else { return }
        self.markExecApprovalOwnerTerminal(
            approvalId: approvalID,
            gatewayStableID: gatewayStableID)
        let message = NovaWatchExecApprovalResolvedMessage(
            approvalId: approvalID,
            gatewayStableID: gatewayStableID,
            decision: decision,
            outcome: outcome,
            resolvedAtMs: resolvedAtMs ?? Int64(Date().timeIntervalSince1970 * 1000),
            source: source,
            outcomeText: outcomeText)
        do {
            _ = try await self.watchMessagingService.sendExecApprovalResolved(message)
        } catch {
            self.watchExecApprovalLogger
                .error(
                    "watch approval resolve failed id=\(approvalID, privacy: .public)")
            self.watchExecApprovalLogger.error(
                "watch approval resolve error=\(error.localizedDescription, privacy: .public)")
        }
        if syncSnapshots {
            await self.syncWatchAppSnapshot(reason: "resolved_app")
            await self.syncWatchExecApprovalSnapshot(reason: "resolved_snapshot")
        }
    }

    private func publishWatchExecApprovalTerminal(
        _ terminal: ExecApprovalTerminalResult,
        gatewayStableID: String,
        source: String,
        syncSnapshots: Bool = true) async
    {
        guard terminal.kind == .exec else {
            self.markExecApprovalOwnerTerminal(
                approvalId: terminal.id,
                gatewayStableID: gatewayStableID)
            return
        }
        if let outcome = Self.watchExecApprovalOutcome(for: terminal.verdict) {
            await self.publishWatchExecApprovalResolved(
                approvalId: terminal.id,
                gatewayStableID: gatewayStableID,
                decision: terminal.decision.flatMap(NovaWatchExecApprovalDecision.init(rawValue:)),
                outcome: outcome,
                outcomeText: Self.execApprovalTerminalText(
                    terminal,
                    alreadyResolved: source == "another-reviewer"),
                resolvedAtMs: terminal.resolvedAtMs,
                source: source,
                syncSnapshots: syncSnapshots)
            return
        }
        switch terminal.verdict {
        case .allowOnce, .allowAlways, .deny:
            preconditionFailure("terminal decision outcome must be mapped")
        case .expired:
            await self.publishWatchExecApprovalExpired(
                approvalId: terminal.id,
                gatewayStableID: gatewayStableID,
                reason: .expired,
                syncSnapshots: syncSnapshots)
        case .cancelled:
            await self.publishWatchExecApprovalExpired(
                approvalId: terminal.id,
                gatewayStableID: gatewayStableID,
                reason: .unavailable,
                syncSnapshots: syncSnapshots)
        case .resolvedUnknown:
            await self.publishWatchExecApprovalExpired(
                approvalId: terminal.id,
                gatewayStableID: gatewayStableID,
                reason: .resolved,
                syncSnapshots: syncSnapshots)
        }
    }

    private static func watchExecApprovalOutcome(
        for verdict: ExecApprovalTerminalVerdict) -> NovaWatchExecApprovalOutcome?
    {
        switch verdict {
        case .allowOnce:
            .allowedOnce
        case .allowAlways:
            .allowedAlways
        case .deny:
            .denied
        case .expired, .cancelled, .resolvedUnknown:
            nil
        }
    }

    private func publishWatchExecApprovalExpired(
        approvalId: String,
        gatewayStableID: String,
        reason: NovaWatchExecApprovalCloseReason,
        approvalKind: ApprovalKind = .exec,
        syncSnapshots: Bool = true) async
    {
        guard let approvalID = Self.validatedApprovalID(approvalId),
              Self.execApprovalIDKey(approvalID) != nil
        else { return }
        self.markExecApprovalOwnerTerminal(
            approvalId: approvalID,
            gatewayStableID: gatewayStableID)
        guard approvalKind == .exec else { return }
        let message = NovaWatchExecApprovalExpiredMessage(
            approvalId: approvalID,
            gatewayStableID: gatewayStableID,
            reason: reason,
            expiredAtMs: Int64(Date().timeIntervalSince1970 * 1000))
        do {
            _ = try await self.watchMessagingService.sendExecApprovalExpired(message)
        } catch {
            self.watchExecApprovalLogger
                .error(
                    "watch approval expiry failed id=\(approvalID, privacy: .public)")
            self.watchExecApprovalLogger.error(
                "watch approval expiry error=\(error.localizedDescription, privacy: .public)")
        }
        if syncSnapshots {
            await self.syncWatchAppSnapshot(reason: "expired_\(reason.rawValue)_app")
            await self.syncWatchExecApprovalSnapshot(reason: "expired_\(reason.rawValue)")
        }
    }

    private func syncWatchExecApprovalSnapshot(
        reason: String,
        requestId: String? = nil,
        requestGatewayStableID: String? = nil,
        shouldContinue: @MainActor @Sendable () -> Bool = { true }) async
    {
        guard shouldContinue() else { return }
        let deliveryGeneration = self.gatewayConnectGeneration
        self.pruneExpiredWatchExecApprovalPrompts()
        GatewayDiagnostics.log(
            "watch exec approval: sync snapshot start "
                + "reason=\(reason) cacheCount=\(self.watchExecApprovalPromptsByID.count) "
                + "backgrounded=\(self.isBackgrounded)")
        let approvals = self.watchExecApprovalPromptsByID.values
            .filter(self.isWatchExecApprovalPromptCurrent)
            .sorted { lhs, rhs in
                let lhsExpires = lhs.expiresAtMs ?? Int64.max
                let rhsExpires = rhs.expiresAtMs ?? Int64.max
                if lhsExpires != rhsExpires {
                    return lhsExpires < rhsExpires
                }
                return Self.approvalIDSortsBefore(lhs.id, rhs.id)
            }
            .map(Self.makeWatchExecApprovalItem)
        let gatewayStableID = self.currentExecApprovalGatewayStableID()
        let exactRequestGatewayStableID = GatewayStableIdentifier.exact(requestGatewayStableID)
        let requestOwnerMatches = if let gatewayStableID, let exactRequestGatewayStableID {
            GatewayStableIdentifier.matches(gatewayStableID, exactRequestGatewayStableID)
        } else {
            false
        }
        let canAcknowledgeRequest = requestId?.isEmpty == false && requestOwnerMatches
        let message = NovaWatchExecApprovalSnapshotMessage(
            approvals: approvals,
            gatewayStableID: gatewayStableID,
            sentAtMs: Int64(Date().timeIntervalSince1970 * 1000),
            snapshotId: UUID().uuidString,
            requestId: canAcknowledgeRequest ? requestId : nil,
            requestGatewayStableID: canAcknowledgeRequest ? exactRequestGatewayStableID : nil)
        do {
            guard shouldContinue() else { return }
            _ = try await self.watchMessagingService.syncExecApprovalSnapshot(message)
            GatewayDiagnostics.log(
                "watch exec approval: sync snapshot sent reason=\(reason) count=\(approvals.count)")
            self.watchExecApprovalLogger
                .debug("watch approval snapshot reason=\(reason, privacy: .public)")
            self.watchExecApprovalLogger.debug(
                "watch approval snapshot count=\(approvals.count, privacy: .public)")
            if deliveryGeneration != self.gatewayConnectGeneration {
                await self.syncWatchExecApprovalSnapshot(reason: "\(reason)_route_repair")
            }
        } catch {
            GatewayDiagnostics.log(
                "watch exec approval: sync snapshot failed reason=\(reason) error=\(error.localizedDescription)")
            self.watchExecApprovalLogger
                .error(
                    "watch approval snapshot failed reason=\(reason, privacy: .public)")
            self.watchExecApprovalLogger.error(
                "watch approval snapshot error=\(error.localizedDescription, privacy: .public)")
        }
    }

    private func makeWatchChatPreview() async -> WatchChatPreview {
        do {
            let payload: NovaChatHistoryPayload
            if self.isAppleReviewDemoModeEnabled {
                payload = try await self.appleReviewDemoChatTransport.requestHistory(sessionKey: self.chatSessionKey)
            } else {
                guard self.isOperatorGatewayConnected else {
                    return WatchChatPreview(
                        items: [],
                        status: NovaWatchAppStatus(code: .chatConnectIPhone),
                        statusText: "Connect iPhone chat to read messages")
                }
                payload = try await IOSGatewayChatTransport(gateway: self.operatorSession)
                    .requestHistory(sessionKey: self.chatSessionKey)
            }

            let items = Self.makeWatchChatItems(from: payload.messages ?? [])
            return WatchChatPreview(
                items: items,
                status: items.isEmpty
                    ? NovaWatchAppStatus(code: .chatNoMessages)
                    : nil,
                statusText: items.isEmpty ? "No chat messages yet" : nil)
        } catch {
            GatewayDiagnostics.log("watch app snapshot: chat preview failed error=\(error.localizedDescription)")
            return WatchChatPreview(
                items: [],
                status: NovaWatchAppStatus(code: .chatUnavailable),
                statusText: "Chat unavailable")
        }
    }

    private nonisolated static func watchChatReplyText(
        from raw: [NovaKit.AnyCodable],
        runId: String,
        submittedText: String,
        submittedAtMs: Int64) -> String?
    {
        let entries = raw.compactMap(self.decodeWatchChatMessage)
        if let directReply = entries.last(where: {
            self.isTerminalWatchAssistant($0) && $0.message.idempotencyKey == runId
        }) {
            return directReply.text
        }

        let userIdempotencyKey = "\(runId):user"
        let exactUserIndex = entries.lastIndex(where: {
            $0.message.role.lowercased() == "user" &&
                $0.message.idempotencyKey == userIdempotencyKey
        })
        let queuedUserIndex = entries.lastIndex(where: { entry in
            guard entry.message.role.lowercased() == "user",
                  let timestampMs = self.watchTimestampMs(entry.message.timestamp),
                  timestampMs >= submittedAtMs
            else {
                return false
            }
            return entry.text.contains(submittedText)
        })
        guard let userIndex = exactUserIndex ?? queuedUserIndex else { return nil }
        return entries[(userIndex + 1)...].first(where: {
            self.isTerminalWatchAssistant($0)
        })?.text
    }

    private nonisolated static func isTerminalWatchAssistant(_ entry: WatchChatMessageEntry) -> Bool {
        guard entry.message.role.lowercased() == "assistant" else { return false }
        if entry.isMessageToolMirror {
            return true
        }
        guard let stopReason = entry.message.stopReason?.lowercased() else { return false }
        // Tool-use rows can contain visible progress text, but a later assistant row owns the final reply.
        return stopReason != "tooluse" && stopReason != "tool_use" && stopReason != "tool_calls"
    }

    private nonisolated static func decodeWatchChatMessage(
        _ raw: NovaKit.AnyCodable) -> WatchChatMessageEntry?
    {
        guard let data = try? JSONEncoder().encode(raw),
              let message = try? JSONDecoder().decode(NovaChatMessage.self, from: data),
              let text = nonEmptyWatchChatText(watchChatText(from: message))
        else {
            return nil
        }
        let metadata = try? JSONDecoder().decode(WatchChatMetadataEnvelope.self, from: data)
        return WatchChatMessageEntry(
            message: message,
            text: text,
            serverId: metadata?.metadata?.id,
            isMessageToolMirror: metadata?.messageToolMirror != nil)
    }

    private nonisolated static func makeWatchChatItems(
        from raw: [NovaKit.AnyCodable]) -> [NovaWatchChatItem]
    {
        let readableMessages = raw.compactMap(self.decodeWatchChatMessage)
        var idOccurrences: [String: Int] = [:]
        let identified = readableMessages.map { entry -> (WatchChatMessageEntry, String) in
            let baseId = entry.serverId.map { "\(entry.message.role)-\($0)" }
                ?? self.watchChatFallbackKey(entry)
            idOccurrences[baseId, default: 0] += 1
            let stableId = "\(baseId)-\(idOccurrences[baseId]!)"
            return (entry, stableId)
        }
        return identified.suffix(self.watchChatPreviewItemLimit).map { entry, stableId in
            let timestampMs = self.watchTimestampMs(entry.message.timestamp)
            return NovaWatchChatItem(
                id: stableId,
                role: entry.message.role,
                text: self.truncatedWatchChatText(entry.text),
                timestampMs: timestampMs)
        }
    }

    private nonisolated static func watchChatFallbackKey(_ entry: WatchChatMessageEntry) -> String {
        let timestamp = self.watchTimestampMs(entry.message.timestamp).map(String.init) ?? "missing"
        let source = "\(entry.message.role)\u{0}\(timestamp)\u{0}\(entry.text)"
        let digest = SHA256.hash(data: Data(source.utf8)).map { String(format: "%02x", $0) }.joined()
        return "\(entry.message.role)-\(digest)"
    }

    private nonisolated static func watchChatText(from message: NovaChatMessage) -> String {
        let parts = message.content.compactMap { content -> String? in
            let kind = (content.type ?? "text").lowercased()
            guard kind.isEmpty || kind == "text" || kind == "output_text" else { return nil }
            if let text = self.nonEmptyWatchChatText(content.text) {
                return text
            }
            if let text = self.nonEmptyWatchChatText(content.content?.value as? String) {
                return text
            }
            if let dict = content.content?.value as? [String: NovaKit.AnyCodable],
               let text = self.nonEmptyWatchChatText(dict["text"]?.value as? String)
            {
                return text
            }
            return nil
        }
        let contentText = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !contentText.isEmpty {
            return contentText
        }
        return message.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private nonisolated static func nonEmptyWatchChatText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private nonisolated static func truncatedWatchChatText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 240 else { return trimmed }
        return "\(trimmed.prefix(237))..."
    }

    private nonisolated static func watchTimestampMs(_ timestamp: Double?) -> Int64? {
        guard let timestamp, timestamp.isFinite, timestamp >= 0 else { return nil }
        let milliseconds = timestamp > 100_000_000_000 ? timestamp : timestamp * 1000
        let maxReasonableEpochMs: Double = 32_503_680_000_000
        guard milliseconds.isFinite,
              milliseconds >= 0,
              milliseconds <= maxReasonableEpochMs
        else {
            return nil
        }
        return Int64(milliseconds)
    }

    private func makeWatchAppSnapshot(
        chatPreview: WatchChatPreview? = nil) -> NovaWatchAppSnapshotMessage
    {
        self.pruneExpiredWatchExecApprovalPrompts()
        let watchGatewayConnected = self.isAppleReviewDemoModeEnabled
            || (self.gatewayConnected && self.operatorConnected)
        let displayStatusText = self.gatewayDisplayStatusText
        let watchGatewayStatusText = watchGatewayConnected || displayStatusText != "Connected"
            ? displayStatusText
            : self.operatorStatusText
        return NovaWatchAppSnapshotMessage(
            gatewayStatus: self.makeWatchGatewayStatus(connected: watchGatewayConnected),
            gatewayStatusText: watchGatewayStatusText,
            gatewayConnected: watchGatewayConnected,
            agentName: self.chatAgentName,
            agentAvatarURL: self.chatAgentAvatarURL,
            agentAvatarText: self.chatAgentAvatarText,
            sessionKey: self.chatSessionKey,
            gatewayStableID: self.currentWatchChatGatewayStableID(),
            talkStatus: self.makeWatchTalkStatus(),
            talkStatusText: self.talkMode.statusText,
            talkEnabled: self.talkMode.isEnabled,
            talkListening: self.talkMode.isListening,
            talkSpeaking: self.talkMode.isSpeaking,
            pendingApprovalCount: self.watchExecApprovalPromptsByID.count,
            chatItems: chatPreview?.items,
            chatStatus: chatPreview?.status,
            chatStatusText: chatPreview?.statusText,
            sentAtMs: Int64(Date().timeIntervalSince1970 * 1000),
            snapshotId: UUID().uuidString)
    }

    private func makeWatchGatewayStatus(connected: Bool) -> NovaWatchAppStatus {
        if connected {
            return NovaWatchAppStatus(code: .gatewayConnected)
        }
        if let problem = self.lastGatewayProblem {
            return Self.makeWatchGatewayProblemStatus(problem)
        }
        if let watchGatewayConnectionStatus {
            return NovaWatchAppStatus(code: watchGatewayConnectionStatus)
        }
        let statusText = self.gatewayStatusText == "Connected"
            ? self.operatorStatusText
            : self.gatewayStatusText
        if statusText == "Offline" {
            return NovaWatchAppStatus(code: .gatewayOffline)
        }
        return NovaWatchAppStatus(code: .legacy, verbatim: statusText)
    }

    func setGatewayConnectionProgress(reconnecting: Bool) {
        self.gatewayStatusText = reconnecting ? "Reconnecting…" : "Connecting…"
        self.watchGatewayConnectionStatus = reconnecting
            ? .gatewayReconnecting
            : .gatewayConnecting
    }

    private static func makeWatchGatewayProblemStatus(
        _ problem: GatewayConnectionProblem) -> NovaWatchAppStatus
    {
        let requestID: String? = switch problem.kind {
        case .pairingRequired, .pairingRoleUpgradeRequired, .pairingScopeUpgradeRequired,
             .pairingMetadataUpgradeRequired, .protocolMismatch:
            problem.requestId
        default:
            nil
        }
        let code: NovaWatchAppStatusCode = requestID != nil
            ? .gatewayProblemWithRequestID
            : .gatewayProblem
        let requestArguments = requestID.map { [$0] } ?? []
        return switch problem.titlePresentation {
        case let .localized(key):
            NovaWatchAppStatus(
                code: code,
                localizationKey: key,
                arguments: requestArguments)
        case let .localizedFormat(key, arguments):
            NovaWatchAppStatus(
                code: code,
                localizationKey: key,
                arguments: arguments + requestArguments)
        case let .verbatim(value):
            NovaWatchAppStatus(
                code: code,
                arguments: requestArguments,
                verbatim: value)
        }
    }

    private func makeWatchTalkStatus() -> NovaWatchAppStatus {
        if self.talkMode.isSpeaking {
            return NovaWatchAppStatus(code: .talkSpeaking)
        }
        if self.talkMode.isListening {
            return NovaWatchAppStatus(code: .talkListening)
        }
        if self.talkMode.hasActivePushToTalkSession {
            return self.makeWatchTalkPresentationStatus()
        }
        switch self.talkMode.watchPresentation {
        case .localized, .verbatim:
            return self.makeWatchTalkPresentationStatus()
        case .phase:
            break
        }
        if !self.talkMode.isEnabled {
            return NovaWatchAppStatus(code: .talkOff)
        }
        if !self.talkMode.isGatewayConnected {
            return NovaWatchAppStatus(code: .talkOffline)
        }
        switch self.talkMode.gatewayTalkPermissionState {
        case .unknown, .ready:
            break
        case let .missingScope(scope):
            return NovaWatchAppStatus(code: .talkPermissionRequired, arguments: [scope])
        case .requestingUpgrade:
            return NovaWatchAppStatus(code: .talkRequestingApproval)
        case .upgradeRequested:
            return NovaWatchAppStatus(code: .talkApprovalRequested)
        case let .requestFailed(message), let .loadFailed(message):
            return NovaWatchAppStatus(code: .talkFailure, verbatim: message)
        case .apiKeyMissing:
            return NovaWatchAppStatus(code: .talkAPIKeyMissing)
        }
        return self.makeWatchTalkPresentationStatus()
    }

    private func makeWatchTalkPresentationStatus() -> NovaWatchAppStatus {
        switch self.talkM