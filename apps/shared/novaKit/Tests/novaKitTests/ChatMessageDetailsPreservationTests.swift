import Foundation
import NovaKit
import Testing
@testable import NovaChatUI

// Tool-result diff metadata rides on `NovaChatMessage.details`; every
// field-enumerating message rebuild must carry it or inline diffs silently
// disappear after cache-warm reconciliation.
@Suite("ChatMessageDetailsPreservation")
struct ChatMessageDetailsPreservationTests {
    private func toolResultMessage(id: UUID = UUID()) -> NovaChatMessage {
        NovaChatMessage(
            id: id,
            role: "toolResult",
            content: [
                NovaChatMessageContent(
                    type: "text",
                    text: "Successfully replaced 1 block(s).",
                    mimeType: nil,
                    fileName: nil,
                    content: nil),
            ],
            timestamp: 1,
            toolCallId: "call-1",
            toolName: "edit",
            details: AnyCodable(["diff": AnyCodable("+1 added\n-1 removed")]))
    }

    @MainActor @Test func `decode pipeline keeps message details`() throws {
        let payloadData = try JSONEncoder().encode([self.toolResultMessage()])
        let anyMessages = try JSONDecoder().decode([AnyCodable].self, from: payloadData)
        let decoded = NovaChatViewModel.decodeMessages(anyMessages)

        #expect(decoded.first?.details != nil)
    }

    @MainActor @Test func `canonical adoption keeps incoming details`() {
        let incoming = self.toolResultMessage()
        let existing = self.toolResultMessage()

        let adopted = NovaChatViewModel.adoptingCanonicalMessage(incoming, over: existing)

        #expect(adopted.id == existing.id)
        #expect(adopted.details != nil)
    }
}
