import CoreLocation
import Foundation
import NovaKit
import UIKit

typealias NovaCameraSnapResult = (format: String, base64: String, width: Int, height: Int)
typealias NovaCameraClipResult = (format: String, base64: String, durationMs: Int, hasAudio: Bool)

protocol CameraServicing: Sendable {
    func listDevices() async -> [CameraController.CameraDeviceInfo]
    func snap(
        params: NovaCameraSnapParams,
        defaultFacing: NovaCameraFacing) async throws -> NovaCameraSnapResult
    func clip(
        params: NovaCameraClipParams,
        defaultFacing: NovaCameraFacing) async throws -> NovaCameraClipResult
}

protocol ScreenRecordingServicing: Sendable {
    func record(
        screenIndex: Int?,
        durationMs: Int?,
        fps: Double?,
        includeAudio: Bool?,
        outPath: String?) async throws -> String
}

@MainActor
protocol LocationServicing: Sendable {
    func authorizationStatus() -> CLAuthorizationStatus
    func accuracyAuthorization() -> CLAccuracyAuthorization
    func ensureAuthorization(mode: NovaLocationMode) async -> CLAuthorizationStatus
    func currentLocation(
        params: NovaLocationGetParams,
        desiredAccuracy: NovaLocationAccuracy,
        maxAgeMs: Int?,
        timeoutMs: Int?) async throws -> CLLocation
    func setBackgroundLocationUpdatesEnabled(_ enabled: Bool)
    func setAuthorizationChangeHandler(
        _ handler: @escaping @MainActor @Sendable (CLAuthorizationStatus) -> Void)
    func startMonitoringSignificantLocationChanges(onUpdate: @escaping @Sendable (CLLocation) -> Void)
    func stopMonitoringSignificantLocationChanges()
}

@MainActor
protocol DeviceStatusServicing: Sendable {
    func status() async throws -> NovaDeviceStatusPayload
    func info() -> NovaDeviceInfoPayload
}

protocol PhotosServicing: Sendable {
    func latest(params: NovaPhotosLatestParams) async throws -> NovaPhotosLatestPayload
}

protocol ContactsServicing: Sendable {
    func search(params: NovaContactsSearchParams) async throws -> NovaContactsSearchPayload
    func add(params: NovaContactsAddParams) async throws -> NovaContactsAddPayload
}

protocol CalendarServicing: Sendable {
    func events(params: NovaCalendarEventsParams) async throws -> NovaCalendarEventsPayload
    func add(params: NovaCalendarAddParams) async throws -> NovaCalendarAddPayload
}

protocol RemindersServicing: Sendable {
    func list(params: NovaRemindersListParams) async throws -> NovaRemindersListPayload
    func add(params: NovaRemindersAddParams) async throws -> NovaRemindersAddPayload
}

protocol MotionServicing: Sendable {
    func activities(params: NovaMotionActivityParams) async throws -> NovaMotionActivityPayload
    func pedometer(params: NovaPedometerParams) async throws -> NovaPedometerPayload
}

struct WatchMessagingStatus: Equatable {
    var supported: Bool
    var paired: Bool
    var appInstalled: Bool
    var reachable: Bool
    var activationState: String
}

struct WatchQuickReplyEvent: Codable, Equatable {
    var replyId: String
    var promptId: String
    var actionId: String
    var actionLabel: String?
    var sessionKey: String?
    var gatewayStableID: String?
    var note: String?
    var sentAtMs: Int64?
    var transport: String
}

enum WatchMessageKind: String, Codable, Equatable {
    case chat
    case quickReply
}

struct WatchExecApprovalResolveEvent: Codable, Equatable {
    var replyId: String
    var approvalId: String
    var gatewayStableID: String?
    var decision: NovaWatchExecApprovalDecision
    var sentAtMs: Int64?
    var transport: String
}

struct WatchExecApprovalSnapshotRequestItem: Equatable {
    var approvalId: String
    var activeResolutionAttemptId: String?
}

struct WatchExecApprovalSnapshotRequestEvent: Equatable {
    var requestId: String
    var gatewayStableID: String?
    var heldApprovals: [WatchExecApprovalSnapshotRequestItem]
    var sentAtMs: Int64?
    var transport: String

    init(
        requestId: String,
        gatewayStableID: String? = nil,
        heldApprovals: [WatchExecApprovalSnapshotRequestItem] = [],
        sentAtMs: Int64?,
        transport: String)
    {
        self.requestId = requestId
        self.gatewayStableID = gatewayStableID
        self.heldApprovals = heldApprovals
        self.sentAtMs = sentAtMs
        self.transport = transport
    }
}

struct WatchAppSnapshotRequestEvent: Equatable {
    var requestId: String
    var sentAtMs: Int64?
    var transport: String
}

struct WatchAppCommandEvent: Codable, Equatable {
    var commandId: String
    var command: NovaWatchAppCommand
    var sessionKey: String?
    var gatewayStableID: String?
    var text: String?
    var sentAtMs: Int64?
    var transport: String
    var messageKind: WatchMessageKind?
}

struct WatchNotificationSendResult: Equatable {
    var deliveredImmediately: Bool
    var queuedForDelivery: Bool
    var transport: String
}

protocol WatchMessagingServicing: AnyObject, Sendable {
    func status() async -> WatchMessagingStatus
    func setStatusHandler(_ handler: (@Sendable (WatchMessagingStatus) -> Void)?)
    func setReplyHandler(_ handler: (@Sendable (WatchQuickReplyEvent) -> Void)?)
    func setExecApprovalResolveHandler(_ handler: (@Sendable (WatchExecApprovalResolveEvent) -> Void)?)
    func setExecApprovalSnapshotRequestHandler(
        _ handler: (@Sendable (WatchExecApprovalSnapshotRequestEvent) -> Void)?)
    func setAppSnapshotRequestHandler(_ handler: (@Sendable (WatchAppSnapshotRequestEvent) -> Void)?)
    func setAppCommandHandler(_ handler: (@Sendable (WatchAppCommandEvent) -> Void)?)
    func sendDirectNodeSetup(setupCode: String) async throws -> WatchNotificationSendResult
    func sendNotification(
        id: String,
        params: NovaWatchNotifyParams,
        gatewayStableID: String?) async throws -> WatchNotificationSendResult
    func sendExecApprovalPrompt(
        _ message: NovaWatchExecApprovalPromptMessage) async throws -> WatchNotificationSendResult
    func sendExecApprovalResolved(
        _ message: NovaWatchExecApprovalResolvedMessage) async throws -> WatchNotificationSendResult
    func sendExecApprovalExpired(
        _ message: NovaWatchExecApprovalExpiredMessage) async throws -> WatchNotificationSendResult
    func syncExecApprovalSnapshot(
        _ message: NovaWatchExecApprovalSnapshotMessage) async throws -> WatchNotificationSendResult
    func syncAppSnapshot(
        _ message: NovaWatchAppSnapshotMessage) async throws -> WatchNotificationSendResult
    func sendChatCompletion(
        _ message: NovaWatchChatCompletionMessage) async throws -> WatchNotificationSendResult
}

extension CameraController: CameraServicing {}
extension ScreenRecordService: ScreenRecordingServicing {}
extension LocationService: LocationServicing {}
