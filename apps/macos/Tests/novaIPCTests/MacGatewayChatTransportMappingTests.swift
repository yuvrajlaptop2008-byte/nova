import Foundation
import NovaChatUI
import NovaKit
import NovaProtocol
import Testing
@testable import Nova

struct MacGatewayChatTransportMappingTests {
    @Test func `mac chat advertises inline widgets`() {
        #expect(GatewayConnection.operatorClientCaps == [NovaGatewayClientCapability.inlineWidgets])
    }

    @Test func `bare global session target carries normalized selected agent`() {
        let transport = MacGatewayChatTransport(defaultGlobalAgentID: "  Agent-A  ")

        #expect(transport.sessionTarget(for: " GLOBAL ") == .init(
            sessionKey: "GLOBAL",
            agentID: "agent-a"))
        #expect(transport.sessionTarget(for: "agent:agent-a:main") == .init(
            sessionKey: "agent:agent-a:main",
            agentID: nil))
        #expect(transport.sessionTarget(for: "main") == .init(
            sessionKey: "main",
            agentID: nil))

        let snapshotObserverTransport = transport
        snapshotObserverTransport.updateDefaultGlobalAgentID("Agent-B")
        #expect(transport.sessionTarget(for: "global") == .init(
            sessionKey: "global",
            agentID: "agent-b"))
    }

    @Test func `bare global session target tolerates missing selected agent`() {
        let transport = MacGatewayChatTransport()

        #expect(transport.sessionTarget(for: "global") == .init(
            sessionKey: "global",
            agentID: nil))
    }

    @Test func `session settings request preserves verbosity patch`() {
        let request = MacGatewayChatTransport.sessionSettingsRequest(
            sessionKey: "global",
            agentID: "reviewer",
            patch: NovaChatSessionSettingsPatch(
                model: .some("openai/gpt-5.6-sol"),
                thinkingLevel: .some(nil),
                fastMode: .some(.on),
                verboseLevel: .some("full")))

        #expect(request.method == "sessions.patch")
        #expect(request.params["key"]?.value as? String == "global")
        #expect(request.params["agentId"]?.value as? String == "reviewer")
        #expect(request.params["model"]?.value as? String == "openai/gpt-5.6-sol")
        #expect(request.params["thinkingLevel"]?.value is NSNull)
        #expect(request.params["fastMode"]?.value as? Bool == true)
        #expect(request.params["verboseLevel"]?.value as? String == "full")
    }

    @Test func `full message request uses generated gateway field names`() throws {
        let request = try MacGatewayChatTransport.fullMessageRequest(
            sessionKey: "global",
            agentID: "reviewer",
            messageID: "msg-42")

        #expect(request.method == "chat.message.get")
        #expect(request.params["sessionKey"]?.value as? String == "global")
        #expect(request.params["agentId"]?.value as? String == "reviewer")
        #expect(request.params["messageId"]?.value as? String == "msg-42")
        #expect(request.params["maxChars"]?.value as? Int == 500_000)
    }

    @Test func `message rewind and fork requests map session targets`() {
        let rewind = MacGatewayChatTransport.rewindSessionRequest(
            sessionKey: "global",
            agentID: "reviewer",
            entryId: "msg-42")
        let fork = MacGatewayChatTransport.forkSessionAtMessageRequest(
            sessionKey: "agent:reviewer:main",
            agentID: nil,
            entryId: "msg-43")

        #expect(rewind.method == "sessions.rewind")
        #expect(rewind.params["sessionKey"]?.value as? String == "global")
        #expect(rewind.params["agentId"]?.value as? String == "reviewer")
        #expect(rewind.params["entryId"]?.value as? String == "msg-42")
        #expect(fork.method == "sessions.fork")
        #expect(fork.params["sessionKey"]?.value as? String == "agent:reviewer:main")
        #expect(fork.params["agentId"] == nil)
        #expect(fork.params["entryId"]?.value as? String == "msg-43")
    }

    @Test func `legacy trace preference migrates to independent defaults once`() throws {
        let suiteName = "MacGatewayChatTransportMappingTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(false, forKey: NovaChatWindowShell.assistantTraceDefaultsKey)

        #expect(WebChatTracePreferences.displayOptions(defaults: defaults).isEmpty)
        #expect(defaults.object(forKey: NovaChatWindowShell.assistantReasoningDefaultsKey) as? Bool == false)
        #expect(defaults.object(forKey: NovaChatWindowShell.assistantToolActivityDefaultsKey) as? Bool == false)

        defaults.set(true, forKey: NovaChatWindowShell.assistantReasoningDefaultsKey)
        #expect(WebChatTracePreferences.displayOptions(defaults: defaults) == [.reasoning])
    }

    @Test func `snapshot maps to health`() {
        let snapshot = Snapshot(
            presence: [],
            health: ["ok": NovaProtocol.AnyCodable(false)],
            stateversion: StateVersion(presence: 1, health: 1),
            uptimems: 123,
            configpath: nil,
            statedir: nil,
            sessiondefaults: nil,
            authmode: nil,
            updateavailable: nil)

        let hello = HelloOk(
            type: "hello",
            _protocol: 2,
            server: [:],
            features: [:],
            snapshot: snapshot,
            controluitabs: nil,
            pluginsurfaceurls: nil,
            auth: [:],
            policy: [:])

        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.snapshot(hello))
        switch mapped {
        case let .health(ok):
            #expect(ok == false)
        default:
            Issue.record("expected .health from snapshot, got \(String(describing: mapped))")
        }
    }

    @Test func `health event maps to health`() {
        let frame = EventFrame(
            type: "event",
            event: "health",
            payload: NovaProtocol.AnyCodable(["ok": NovaProtocol.AnyCodable(true)]),
            seq: 1,
            stateversion: nil)

        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))
        switch mapped {
        case let .health(ok):
            #expect(ok == true)
        default:
            Issue.record("expected .health from health event, got \(String(describing: mapped))")
        }
    }

    @Test func `tick event maps to tick`() {
        let frame = EventFrame(type: "event", event: "tick", payload: nil, seq: 1, stateversion: nil)
        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))
        #expect({
            if case .tick = mapped {
                return true
            }
            return false
        }())
    }

    @Test func `sessions changed event maps to authoritative refresh signal`() {
        let payload = NovaProtocol.AnyCodable([
            "sessionKey": NovaProtocol.AnyCodable("agent:main:main"),
            "agentId": NovaProtocol.AnyCodable("main"),
            "reason": NovaProtocol.AnyCodable("command-metadata"),
        ])
        let frame = EventFrame(
            type: "event",
            event: "sessions.changed",
            payload: payload,
            seq: 1,
            stateversion: nil)

        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))
        guard case let .sessionsChanged(change) = mapped else {
            Issue.record("expected .sessionsChanged, got \(String(describing: mapped))")
            return
        }
        #expect(change == .init(
            sessionKey: "agent:main:main",
            agentId: "main",
            reason: "command-metadata"))
    }

    @Test func `chat event maps to chat`() {
        let payload = NovaProtocol.AnyCodable([
            "runId": NovaProtocol.AnyCodable("run-1"),
            "sessionKey": NovaProtocol.AnyCodable("main"),
            "state": NovaProtocol.AnyCodable("final"),
        ])
        let frame = EventFrame(type: "event", event: "chat", payload: payload, seq: 1, stateversion: nil)
        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))

        switch mapped {
        case let .chat(chat):
            #expect(chat.runId == "run-1")
            #expect(chat.sessionKey == "main")
            #expect(chat.state == "final")
        default:
            Issue.record("expected .chat from chat event, got \(String(describing: mapped))")
        }
    }

    @Test func `session message event maps to session message`() {
        let payload = NovaProtocol.AnyCodable([
            "sessionKey": NovaProtocol.AnyCodable("agent:main:main"),
            "messageId": NovaProtocol.AnyCodable("msg-1"),
            "messageSeq": NovaProtocol.AnyCodable(7),
            "message": NovaProtocol.AnyCodable([
                "role": NovaProtocol.AnyCodable("user"),
                "content": NovaProtocol.AnyCodable([
                    NovaProtocol.AnyCodable([
                        "type": NovaProtocol.AnyCodable("text"),
                        "text": NovaProtocol.AnyCodable("spoken transcript"),
                    ]),
                ]),
                "timestamp": NovaProtocol.AnyCodable(1234.5),
            ]),
        ])
        let frame = EventFrame(type: "event", event: "session.message", payload: payload, seq: 1, stateversion: nil)
        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))

        switch mapped {
        case let .sessionMessage(message):
            #expect(message.sessionKey == "agent:main:main")
            #expect(message.messageId == "msg-1")
            #expect(message.messageSeq == 7)
            #expect(message.message?.role == "user")
            #expect(message.message?.content.first?.text == "spoken transcript")
        default:
            Issue.record("expected .sessionMessage from session.message event, got \(String(describing: mapped))")
        }
    }

    @Test func `unknown event maps to nil`() {
        let frame = EventFrame(
            type: "event",
            event: "unknown",
            payload: NovaProtocol.AnyCodable(["a": NovaProtocol.AnyCodable(1)]),
            seq: 1,
            stateversion: nil)
        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.event(frame))
        #expect(mapped == nil)
    }

    @Test func `seq gap maps to seq gap`() {
        let mapped = MacGatewayChatTransport.mapPushToTransportEvent(.seqGap(expected: 1, received: 9))
        #expect({
            if case .seqGap = mapped {
                return true
            }
            return false
        }())
    }
}
