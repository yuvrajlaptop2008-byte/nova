import Foundation

public enum NovaDeviceCommand: String, Codable, Sendable {
    case status = "device.status"
    case info = "device.info"
}

public enum NovaBatteryState: String, Codable, Sendable {
    case unknown
    case unplugged
    case charging
    case full
}

public enum NovaThermalState: String, Codable, Sendable {
    case nominal
    case fair
    case serious
    case critical
}

public enum NovaNetworkPathStatus: String, Codable, Sendable {
    case satisfied
    case unsatisfied
    case requiresConnection
}

public enum NovaNetworkInterfaceType: String, Codable, Sendable {
    case wifi
    case cellular
    case wired
    case other
}

public struct NovaBatteryStatusPayload: Codable, Sendable, Equatable {
    public var level: Double?
    public var state: NovaBatteryState
    public var lowPowerModeEnabled: Bool

    public init(level: Double?, state: NovaBatteryState, lowPowerModeEnabled: Bool) {
        self.level = level
        self.state = state
        self.lowPowerModeEnabled = lowPowerModeEnabled
    }
}

public struct NovaThermalStatusPayload: Codable, Sendable, Equatable {
    public var state: NovaThermalState

    public init(state: NovaThermalState) {
        self.state = state
    }
}

public struct NovaStorageStatusPayload: Codable, Sendable, Equatable {
    public var totalBytes: Int64
    public var freeBytes: Int64
    public var usedBytes: Int64

    public init(totalBytes: Int64, freeBytes: Int64, usedBytes: Int64) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.usedBytes = usedBytes
    }
}

public struct NovaNetworkStatusPayload: Codable, Sendable, Equatable {
    public var status: NovaNetworkPathStatus
    public var isExpensive: Bool
    public var isConstrained: Bool
    public var interfaces: [NovaNetworkInterfaceType]

    public init(
        status: NovaNetworkPathStatus,
        isExpensive: Bool,
        isConstrained: Bool,
        interfaces: [NovaNetworkInterfaceType])
    {
        self.status = status
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.interfaces = interfaces
    }
}

public struct NovaDeviceStatusPayload: Codable, Sendable, Equatable {
    public var battery: NovaBatteryStatusPayload
    public var thermal: NovaThermalStatusPayload
    public var storage: NovaStorageStatusPayload
    public var network: NovaNetworkStatusPayload
    public var uptimeSeconds: Double

    public init(
        battery: NovaBatteryStatusPayload,
        thermal: NovaThermalStatusPayload,
        storage: NovaStorageStatusPayload,
        network: NovaNetworkStatusPayload,
        uptimeSeconds: Double)
    {
        self.battery = battery
        self.thermal = thermal
        self.storage = storage
        self.network = network
        self.uptimeSeconds = uptimeSeconds
    }
}

public struct NovaDeviceInfoPayload: Codable, Sendable, Equatable {
    public var deviceName: String
    public var modelIdentifier: String
    public var systemName: String
    public var systemVersion: String
    public var appVersion: String
    public var appBuild: String
    public var locale: String

    public init(
        deviceName: String,
        modelIdentifier: String,
        systemName: String,
        systemVersion: String,
        appVersion: String,
        appBuild: String,
        locale: String)
    {
        self.deviceName = deviceName
        self.modelIdentifier = modelIdentifier
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.locale = locale
    }
}
