import Foundation

public enum NovaTalkCommand: String, Codable, Sendable {
    case pttStart = "talk.ptt.start"
    case pttStop = "talk.ptt.stop"
    case pttCancel = "talk.ptt.cancel"
    case pttOnce = "talk.ptt.once"
}

public struct NovaTalkPTTStartPayload: Codable, Sendable, Equatable {
    public var captureId: String

    public init(captureId: String) {
        self.captureId = captureId
    }
}

public struct NovaTalkPTTStopPayload: Codable, Sendable, Equatable {
    public var captureId: String
    public var transcript: String?
    public var status: String

    public init(captureId: String, transcript: String?, status: String) {
        self.captureId = captureId
        self.transcript = transcript
        self.status = status
    }
}
