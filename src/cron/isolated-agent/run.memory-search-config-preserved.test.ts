import { describe, expect, it } from "vitest";
import { resolveMemorySearchConfig } from "../../agents/memory-search.js";
import type { NovaConfig } from "../../config/types.nova.js";
import type { MemorySearchConfig } from "../../config/types.tools.js";
import { buildCronAgentDefaultsConfig } from "./run-config.js";

describe("buildCronAgentDefaultsConfig memory search preservation", () => {
  it("keeps global memory search defaults when the agent override is partial", () => {
    const defaultMemorySearch = {
      enabled: true,
      provider: "openai",
      model: "text-embedding-3-large",
      sources: ["memory", "sessions"],
      remote: { apiKey: "redacted" },
      query: {
        hybrid: {
          temporalDecay: { enabled: true },
        },
      },
    } satisfies MemorySearchConfig;
    const agentMemorySearch = {
      experimental: { sessionMemory: true },
      query: {
        hybrid: {
          temporalDecay: { enabled: false },
        },
      },
    } satisfies MemorySearchConfig;
    const agentDefaults = buildCronAgentDefaultsConfig({
      defaults: { memorySearch: defaultMemorySearch },
      agentConfigOverride: { memorySearch: agentMemorySearch },
    });
    const runCfg: NovaConfig = {
      plugins: { enabled: false },
      agents: {
        defaults: agentDefaults,
        list: [{ id: "main", default: true, memorySearch: agentMemorySearch }],
      },
    };

    expect(agentDefaults.memorySearch).toEqual(defaultMemorySearch);
    expect(resolveMemorySearchConfig(runCfg, "main")).toMatchObject({
      provider: "openai",
      model: "text-embedding-3-large",
      sources: ["memory", "sessions"],
      remote: { apiKey: "redacted" },
      experimental: { sessionMemory: true },
      query: {
        hybrid: {
          temporalDecay: { enabled: false },
        },
      },
    });
  });
});
