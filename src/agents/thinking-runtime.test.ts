import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import type { NovaConfig } from "../config/types.nova.js";
import {
  clearAgentHarnesses,
  listRegisteredAgentHarnesses,
  registerAgentHarness,
  restoreRegisteredAgentHarnesses,
} from "./harness/registry.js";
import type { AgentHarness } from "./harness/types.js";
import { resolveCandidateThinkingLevel, resolveEffectiveAgentRuntime } from "./thinking-runtime.js";

function openAIConfig(runtime: string): NovaConfig {
  return {
    agents: {
      defaults: {
        models: {
          "openai/gpt-5.6-luna": { agentRuntime: { id: runtime } },
        },
      },
    },
  };
}

describe("resolveEffectiveAgentRuntime", () => {
  let registeredHarnesses: ReturnType<typeof listRegisteredAgentHarnesses>;

  beforeAll(() => {
    registeredHarnesses = listRegisteredAgentHarnesses();
  });

  beforeEach(() => {
    clearAgentHarnesses();
  });

  afterAll(() => {
    restoreRegisteredAgentHarnesses(registeredHarnesses);
  });

  it("keeps cold-start official OpenAI Luna on implicit Codex policy", () => {
    expect(
      resolveEffectiveAgentRuntime({
        cfg: {},
        provider: "openai",
        modelId: "gpt-5.6-luna",
      }),
    ).toBe("codex");
  });

  it("resolves residual auto to Nova when no plugin harness is registered", () => {
    expect(
      resolveEffectiveAgentRuntime({
        cfg: {
          models: {
            providers: {
              openai: {
                baseUrl: "http://127.0.0.1:8080/v1",
                models: [],
              },
            },
          },
        },
        provider: "openai",
        modelId: "gpt-5.6-luna",
      }),
    ).toBe("nova");
  });

  it("uses static auto-selection facts before resolving provider routes", () => {
    const supports = vi.fn<AgentHarness["supports"]>(() => ({ supported: true, priority: 100 }));
    registerAgentHarness({
      id: "codex",
      label: "Codex",
      autoSelection: { providerIds: ["openai", "codex"] },
      supports,
      runAttempt: async () => {
        throw new Error("not exercised");
      },
    });

    expect(
      resolveEffectiveAgentRuntime({
        cfg: {},
        provider: "deepseek",
        modelId: "deepseek-v4-pro",
      }),
    ).toBe("nova");
    expect(supports).not.toHaveBeenCalled();
  });

  it("keeps an authored custom route on Nova before registered harness selection", () => {
    const supports = vi.fn<AgentHarness["supports"]>(({ provider }) =>
      provider === "openai" ? { supported: true, priority: 100 } : { supported: false },
    );
    const codexHarness: AgentHarness = {
      id: "codex",
      label: "Codex",
      supports,
      runAttempt: async () => {
        throw new Error("not exercised");
      },
    };
    registerAgentHarness(codexHarness);

    expect(
      resolveEffectiveAgentRuntime({
        cfg: {
          models: {
            providers: {
              openai: {
                baseUrl: "http://127.0.0.1:8080/v1",
                models: [],
              },
            },
          },
        },
        provider: "openai",
        modelId: "gpt-5.6-luna",
      }),
    ).toBe("nova");
    expect(supports).not.toHaveBeenCalled();
  });

  it("prefers explicit session overrides", () => {
    const cfg = openAIConfig("nova");
    expect(
      resolveEffectiveAgentRuntime({
        cfg,
        provider: "openai",
        modelId: "gpt-5.6-luna",
        sessionEntry: { agentRuntimeOverride: "codex", agentHarnessId: "nova" },
      }),
    ).toBe("codex");
  });

  it("ignores legacy harness ids when choosing a runtime", () => {
    const cfg = openAIConfig("nova");
    expect(
      resolveEffectiveAgentRuntime({
        cfg,
        provider: "openai",
        modelId: "gpt-5.6-luna",
        sessionEntry: { agentHarnessId: "codex" },
      }),
    ).toBe("nova");
  });

  it("uses configured runtime policy without session hints", () => {
    const cfg = openAIConfig("nova");
    expect(
      resolveEffectiveAgentRuntime({
        cfg,
        provider: "openai",
        modelId: "gpt-5.6-luna",
      }),
    ).toBe("nova");
  });

  it("lets an explicit Nova override replace configured Codex policy", () => {
    expect(
      resolveEffectiveAgentRuntime({
        cfg: openAIConfig("codex"),
        provider: "openai",
        modelId: "gpt-5.6-luna",
        sessionEntry: { agentRuntimeOverride: "nova", agentHarnessId: "codex" },
      }),
    ).toBe("nova");
  });

  it("keeps a supported candidate level unchanged", () => {
    expect(
      resolveCandidateThinkingLevel({
        cfg: {},
        provider: "demo",
        modelId: "demo-model",
        level: "medium",
      }),
    ).toBe("medium");
  });

  it("clamps an unsupported candidate level without changing the requested value", () => {
    const requested = "ultra" as const;

    expect(
      resolveCandidateThinkingLevel({
        cfg: {},
        provider: "demo",
        modelId: "demo-model",
        level: requested,
      }),
    ).toBe("high");
    expect(requested).toBe("ultra");
  });

  it("re-evaluates every candidate from the immutable request so later support can upgrade", () => {
    const cfg: NovaConfig = {
      agents: {
        defaults: {
          models: {
            "openai/gpt-5.6-luna": { agentRuntime: { id: "codex" } },
            "openai/gpt-5.6-sol": { agentRuntime: { id: "codex" } },
          },
        },
      },
    };
    const requested = "ultra" as const;

    expect(
      resolveCandidateThinkingLevel({
        cfg,
        provider: "openai",
        modelId: "gpt-5.6-luna",
        level: requested,
      }),
    ).toBe("max");
    expect(
      resolveCandidateThinkingLevel({
        cfg,
        provider: "openai",
        modelId: "gpt-5.6-sol",
        level: requested,
      }),
    ).toBe("ultra");
  });
});
