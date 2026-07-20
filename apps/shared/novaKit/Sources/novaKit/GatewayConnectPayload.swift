import Foundation
import NovaProtocol

enum GatewayConnectPayload {
    static func makeClient(
        options: GatewayConnectOptions,
        displayName: String,
        platform: String) -> [String: NovaProtocol.AnyCodable]
    {
        var client: [String: NovaProtocol.AnyCodable] = [
            "id": NovaProtocol.AnyCodable(options.clientId),
            "displayName": NovaProtocol.AnyCodable(displayName),
            "version": NovaProtocol.AnyCodable(
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"),
            "platform": NovaProtocol.AnyCodable(platform),
            "mode": NovaProtocol.AnyCodable(options.clientMode),
            "instanceId": NovaProtocol.AnyCodable(InstanceIdentity.instanceId),
            "deviceFamily": NovaProtocol.AnyCodable(InstanceIdentity.deviceFamily),
        ]
        if let model = InstanceIdentity.modelIdentifier {
            client["modelIdentifier"] = NovaProtocol.AnyCodable(model)
        }
        return client
    }
}
