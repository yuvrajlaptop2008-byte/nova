import AVFoundation
import Contacts
import CoreLocation
import CoreMotion
import EventKit
import Foundation
import NovaKit
import ReplayKit
import Speech
import UIKit

struct GatewayManualTransportPresentation: Equatable {
    let requiresTLS: Bool
    let effectiveTLS: Bool
    let helperText: String?
}

extension GatewayConnectionController {
    func buildGatewayURL(host: String, port: Int, useTLS: Bool) -> URL? {
        let scheme = useTLS ? "wss" : "ws"
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        return components.url
    }

    func resolveManualUseTLS(host: String, useTLS: Bool) -> Bool {
        Self.manualTransportPresentation(
            host: host,
            requestedTLS: useTLS).effectiveTLS
    }

    static func manualTransportPresentation(
        host: String,
        requestedTLS: Bool) -> GatewayManualTransportPresentation
    {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let requiresTLS = !trimmedHost.isEmpty && !LoopbackHost.isLocalNetworkHost(trimmedHost)
        let effectiveTLS = requestedTLS || requiresTLS
        let helperText: String? = if requiresTLS {
            String(localized: "Secure connection is required for this host.")
        } else if effectiveTLS {
            nil
        } else {
            String(localized: "Use only on a trusted private network.")
        }
        return GatewayManualTransportPresentation(
            requiresTLS: requiresTLS,
            effectiveTLS: effectiveTLS,
            helperText: helperText)
    }

    func manualStableID(host: String, port: Int) -> String {
        ManualAuthOverride.manualStableID(host: host, port: port)
    }

    func makeConnectOptions(
        stableID: String?,
        deviceAuthGatewayID: String?,
        allowStoredDeviceAuth: Bool = true) async -> GatewayConnectOptions
    {
        let defaults = UserDefaults.standard
        let displayName = self.resolvedDisplayName(defaults: defaults)
        let resolvedClientId = self.resolvedClientId(defaults: defaults, stableID: stableID)
        let permissions = await self.currentPermissions()

        return GatewayConnectOptions(
            role: "node",
            scopes: [],
            caps: self.currentCaps(),
            commands: self.currentCommands(),
            permissions: permissions,
            clientId: resolvedClientId,
            clientMode: "node",
            clientDisplayName: displayName,
            allowStoredDeviceAuth: allowStoredDeviceAuth,
            deviceAuthGatewayID: GatewayStableIdentifier.exact(deviceAuthGatewayID))
    }

    private func resolvedClientId(defaults: UserDefaults, stableID: String?) -> String {
        if let stableID,
           let override = GatewaySettingsStore.loadGatewayClientIdOverride(stableID: stableID)
        {
            return override
        }
        let manualClientId = defaults.string(forKey: "gateway.manual.clientId")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if manualClientId?.isEmpty == false {
            return manualClientId!
        }
        return "nova-ios"
    }

    private func resolvedDisplayName(defaults: UserDefaults) -> String {
        let key = "node.displayName"
        let existingRaw = defaults.string(forKey: key)
        let resolved = NodeDisplayName.resolve(
            existing: existingRaw,
            deviceName: UIDevice.current.name,
            interfaceIdiom: UIDevice.current.userInterfaceIdiom)
        let existing = existingRaw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if existing.isEmpty || NodeDisplayName.isGeneric(existing) {
            defaults.set(resolved, forKey: key)
        }
        return resolved
    }

    private func currentCaps() -> [String] {
        var caps = [
            NovaCapability.canvas.rawValue,
            NovaCapability.screen.rawValue,
        ]

        // Default-on: if the key doesn't exist yet, treat it as enabled.
        let cameraEnabled =
            UserDefaults.standard.object(forKey: "camera.enabled") == nil
                ? true
                : UserDefaults.standard.bool(forKey: "camera.enabled")
        if cameraEnabled { caps.append(NovaCapability.camera.rawValue) }

        let voiceWakeEnabled = UserDefaults.standard.bool(forKey: VoiceWakePreferences.enabledKey)
        if voiceWakeEnabled { caps.append(NovaCapability.voiceWake.rawValue) }

        let locationModeRaw = UserDefaults.standard.string(forKey: "location.enabledMode") ?? "off"
        let locationMode = NovaLocationMode(rawValue: locationModeRaw) ?? .off
        if locationMode != .off { caps.append(NovaCapability.location.rawValue) }

        caps.append(NovaCapability.device.rawValue)
        caps.append(NovaCapability.talk.rawValue)
        if WatchMessagingService.isSupportedOnDevice() {
            caps.append(NovaCapability.watch.rawValue)
        }
        caps.append(NovaCapability.photos.rawValue)
        caps.append(NovaCapability.contacts.rawValue)
        caps.append(NovaCapability.calendar.rawValue)
        caps.append(NovaCapability.reminders.rawValue)
        if Self.motionAvailable() {
            caps.append(NovaCapability.motion.rawValue)
        }
        if HealthAuthorization.isEnabled {
            caps.append(NovaCapability.health.rawValue)
        }

        return caps
    }

    private func currentCommands() -> [String] {
        var commands: [String] = [
            NovaCanvasCommand.present.rawValue,
            NovaCanvasCommand.hide.rawValue,
            NovaCanvasCommand.navigate.rawValue,
            NovaCanvasCommand.evalJS.rawValue,
            NovaCanvasCommand.snapshot.rawValue,
            NovaCanvasA2UICommand.push.rawValue,
            NovaCanvasA2UICommand.pushJSONL.rawValue,
            NovaCanvasA2UICommand.reset.rawValue,
            NovaScreenCommand.record.rawValue,
            NovaSystemCommand.notify.rawValue,
            NovaChatCommand.push.rawValue,
            NovaTalkCommand.pttStart.rawValue,
            NovaTalkCommand.pttStop.rawValue,
            NovaTalkCommand.pttCancel.rawValue,
            NovaTalkCommand.pttOnce.rawValue,
        ]

        let caps = Set(self.currentCaps())
        if caps.contains(NovaCapability.camera.rawValue) {
            commands.append(NovaCameraCommand.list.rawValue)
            commands.append(NovaCameraCommand.snap.rawValue)
            commands.append(NovaCameraCommand.clip.rawValue)
        }
        if caps.contains(NovaCapability.location.rawValue) {
            commands.append(NovaLocationCommand.get.rawValue)
        }
        if caps.contains(NovaCapability.device.rawValue) {
            commands.append(NovaDeviceCommand.status.rawValue)
            commands.append(NovaDeviceCommand.info.rawValue)
        }
        if caps.contains(NovaCapability.watch.rawValue) {
            commands.append(NovaWatchCommand.status.rawValue)
            commands.append(NovaWatchCommand.notify.rawValue)
        }
        if caps.contains(NovaCapability.photos.rawValue) {
            commands.append(NovaPhotosCommand.latest.rawValue)
        }
        if caps.contains(NovaCapability.contacts.rawValue) {
            commands.append(NovaContactsCommand.search.rawValue)
            commands.append(NovaContactsCommand.add.rawValue)
        }
        if caps.contains(NovaCapability.calendar.rawValue) {
            commands.append(NovaCalendarCommand.events.rawValue)
            commands.append(NovaCalendarCommand.add.rawValue)
        }
        if caps.contains(NovaCapability.reminders.rawValue) {
            commands.append(NovaRemindersCommand.list.rawValue)
            commands.append(NovaRemindersCommand.add.rawValue)
        }
        if caps.contains(NovaCapability.motion.rawValue) {
            commands.append(NovaMotionCommand.activity.rawValue)
            commands.append(NovaMotionCommand.pedometer.rawValue)
        }
        if caps.contains(NovaCapability.health.rawValue) {
            commands.append(NovaHealthCommand.summary.rawValue)
        }

        return commands
    }

    private func currentPermissions() async -> [String: Bool] {
        var permissions: [String: Bool] = [:]
        permissions["camera"] = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        permissions["microphone"] = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        permissions["speechRecognition"] = SFSpeechRecognizer.authorizationStatus() == .authorized
        let locationStatus = CLLocationManager().authorizationStatus
        let locationServicesEnabled = await Self.locationServicesEnabled()
        permissions["location"] = Self.isLocationAvailable(
            servicesEnabled: locationServicesEnabled,
            status: locationStatus)
        permissions["screenRecording"] = RPScreenRecorder.shared().isAvailable

        permissions["photos"] = PhotoLibraryAccess.canRead(PhotoLibraryAccess.authorizationStatus())
        let contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
        permissions["contacts"] = contactsStatus == .authorized || contactsStatus == .limited

        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        permissions["calendar"] = Self.hasEventKitReadAccess(calendarStatus)
        let remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
        permissions["reminders"] = Self.hasEventKitReadAccess(remindersStatus)

        let motionStatus = CMMotionActivityManager.authorizationStatus()
        let pedometerStatus = CMPedometer.authorizationStatus()
        permissions["motion"] =
            motionStatus == .authorized || pedometerStatus == .authorized

        return permissions
    }

    private static func locationServicesEnabled() async -> Bool {
        await Task.detached(priority: .utility) {
            CLLocationManager.locationServicesEnabled()
        }.value
    }

    private static func isLocationAvailable(servicesEnabled: Bool, status: CLAuthorizationStatus) -> Bool {
        guard servicesEnabled else { return false }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    private static func hasEventKitReadAccess(_ status: EKAuthorizationStatus) -> Bool {
        status == .fullAccess
    }

    private static func motionAvailable() -> Bool {
        CMMotionActivityManager.isActivityAvailable() || CMPedometer.isStepCountingAvailable()
    }
}

#if DEBUG
extension GatewayConnectionController {
    func _test_resolvedDisplayName(defaults: UserDefaults) -> String {
        self.resolvedDisplayName(defaults: defaults)
    }

    func _test_currentCaps() -> [String] {
        self.currentCaps()
    }

    func _test_currentCommands() -> [String] {
        self.currentCommands()
    }

    func _test_currentPermissions() async -> [String: Bool] {
        await self.currentPermissions()
    }

    static func _test_hasEventKitReadAccess(_ status: EKAuthorizationStatus) -> Bool {
        self.hasEventKitReadAccess(status)
    }

    static func _test_isLocationAvailable(servicesEnabled: Bool, status: CLAuthorizationStatus) -> Bool {
        self.isLocationAvailable(servicesEnabled: servicesEnabled, status: status)
    }

    func _test_resolveManualUseTLS(host: String, useTLS: Bool) -> Bool {
        self.resolveManualUseTLS(host: host, useTLS: useTLS)
    }
}
#endif
