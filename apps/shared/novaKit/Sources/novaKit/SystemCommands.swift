import Foundation

public enum NovaSystemCommand: String, Codable, Sendable {
    case run = "system.run"
    case which = "system.which"
    case notify = "system.notify"
    case execApprovalsGet = "system.execApprovals.get"
    case execApprovalsSet = "system.execApprovals.set"
}

public enum NovaFileSystemCommand: String, Codable, Sendable {
    case listDir = "fs.listDir"
}

public enum NovaNotificationPriority: String, Codable, Sendable {
    case passive
    case active
    case timeSensitive
}

public enum NovaNotificationDelivery: String, Codable, Sendable {
    case system
    case overlay
    case auto
}

public struct NovaSystemNotifyParams: Codable, Sendable, Equatable {
    public var title: String
    public var body: String
    public var sound: String?
    public var priority: NovaNotificationPriority?
    public var delivery: NovaNotificationDelivery?

    public init(
        title: String,
        body: String,
        sound: String? = nil,
        priority: NovaNotificationPriority? = nil,
        delivery: NovaNotificationDelivery? = nil)
    {
        self.title = title
        self.body = body
        self.sound = sound
        self.priority = priority
        self.delivery = delivery
    }
}
