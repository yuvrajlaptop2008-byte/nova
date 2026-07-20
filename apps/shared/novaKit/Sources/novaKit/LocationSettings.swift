import Foundation

public enum NovaLocationMode: String, Codable, Sendable, CaseIterable {
    case off
    case whileUsing
    case always
}
