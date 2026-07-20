import Foundation

public enum NovaCameraCommand: String, Codable, Sendable {
    case list = "camera.list"
    case snap = "camera.snap"
    case clip = "camera.clip"
}

public enum NovaCameraFacing: String, Codable, Sendable {
    case back
    case front
}

public enum NovaCameraImageFormat: String, Codable, Sendable {
    case jpg
    case jpeg
}

public enum NovaCameraVideoFormat: String, Codable, Sendable {
    case mp4
}

public struct NovaCameraSnapParams: Codable, Sendable, Equatable {
    public var facing: NovaCameraFacing?
    public var maxWidth: Int?
    public var quality: Double?
    public var format: NovaCameraImageFormat?
    public var deviceId: String?
    public var delayMs: Int?

    public init(
        facing: NovaCameraFacing? = nil,
        maxWidth: Int? = nil,
        quality: Double? = nil,
        format: NovaCameraImageFormat? = nil,
        deviceId: String? = nil,
        delayMs: Int? = nil)
    {
        self.facing = facing
        self.maxWidth = maxWidth
        self.quality = quality
        self.format = format
        self.deviceId = deviceId
        self.delayMs = delayMs
    }
}

public struct NovaCameraClipParams: Codable, Sendable, Equatable {
    public var facing: NovaCameraFacing?
    public var durationMs: Int?
    public var includeAudio: Bool?
    public var format: NovaCameraVideoFormat?
    public var deviceId: String?

    public init(
        facing: NovaCameraFacing? = nil,
        durationMs: Int? = nil,
        includeAudio: Bool? = nil,
        format: NovaCameraVideoFormat? = nil,
        deviceId: String? = nil)
    {
        self.facing = facing
        self.durationMs = durationMs
        self.includeAudio = includeAudio
        self.format = format
        self.deviceId = deviceId
    }
}
