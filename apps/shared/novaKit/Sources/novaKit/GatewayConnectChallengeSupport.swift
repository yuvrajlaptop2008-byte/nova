import Foundation
import NovaProtocol

public enum GatewayConnectChallengeSupport {
    public static func nonce(from payload: [String: NovaProtocol.AnyCodable]?) -> String? {
        guard let nonce = payload?["nonce"]?.value as? String else { return nil }
        let trimmed = nonce.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
