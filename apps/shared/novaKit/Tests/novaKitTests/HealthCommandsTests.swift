import Foundation
import Testing
@testable import NovaKit

struct HealthCommandsTests {
    @Test func `health summary periods use the node command wire values`() throws {
        #expect(NovaHealthCommand.summary.rawValue == "health.summary")
        #expect(NovaHealthSummaryPeriod.allCases.map(\.rawValue) == ["today"])

        let params = NovaHealthSummaryParams(period: .today)
        let data = try JSONEncoder().encode(params)
        #expect(String(decoding: data, as: UTF8.self) == #"{"period":"today"}"#)
    }
}
