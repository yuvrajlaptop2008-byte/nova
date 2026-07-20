import Testing
@testable import NovaKit

struct GatewayTLSPinningTests {
    @Test func `first use pinning requires system trust`() {
        #expect(GatewayTLSFirstUsePolicy.allowsFirstUsePin(systemTrustOk: true))
        #expect(!GatewayTLSFirstUsePolicy.allowsFirstUsePin(systemTrustOk: false))
    }
}
