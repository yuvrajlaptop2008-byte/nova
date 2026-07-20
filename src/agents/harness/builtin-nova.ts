/**
 * Built-in Nova harness registration.
 *
 * Harness selection uses this factory to expose the embedded Nova runtime
 * through the same AgentHarness contract as external harness plugins.
 */
import { NOVA_EMBEDDED_CONTEXT_ENGINE_HOST } from "../../context-engine/host-compat.js";
import { runEmbeddedAttempt } from "../embedded-agent-runner/run/attempt.js";
import type { AgentHarness } from "./types.js";

/** Creates the built-in harness backed by the embedded Nova agent runner. */
export function createNovaAgentHarness(): AgentHarness {
  return {
    id: "nova",
    label: "Nova embedded agent",
    contextEngineHostCapabilities: NOVA_EMBEDDED_CONTEXT_ENGINE_HOST.capabilities,
    supports: () => ({ supported: true, priority: 0 }),
    runAttempt: runEmbeddedAttempt,
  };
}
