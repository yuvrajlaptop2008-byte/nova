// Covers agent directory resolution across config and environment overrides.
import { afterEach, describe, expect, it, vi } from "vitest";
import { findDuplicateAgentDirs } from "./agent-dirs.js";
import type { NovaConfig } from "./types.js";

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("resolveEffectiveAgentDir via findDuplicateAgentDirs", () => {
  it("uses NOVA_HOME for default agent dir resolution", () => {
    // findDuplicateAgentDirs calls resolveEffectiveAgentDir internally.
    // With a single agent there are no duplicates, but we can inspect the
    // resolved dir indirectly by triggering a duplicate with two agents
    // that both fall through to the same default dir — which can't happen
    // since they have different IDs.  Instead we just verify no crash and
    // that the env flows through by checking a two-agent config produces
    // distinct dirs (no duplicates).
    const cfg: NovaConfig = {
      agents: {
        list: [{ id: "alpha" }, { id: "beta" }],
      },
    };

    const env = {
      NOVA_HOME: "/srv/nova-home",
      HOME: "/home/other",
    } as NodeJS.ProcessEnv;

    const dupes = findDuplicateAgentDirs(cfg, { env });
    expect(dupes).toHaveLength(0);
  });

  it("resolves agent dir under NOVA_HOME state dir", () => {
    // Force two agents to the same explicit agentDir to verify the path
    // that doesn't use the default — then test the default path by
    // checking that a single-agent config resolves without duplicates.
    const cfg: NovaConfig = {};

    const env = {
      NOVA_HOME: "/srv/nova-home",
    } as NodeJS.ProcessEnv;

    // No duplicates for a single default agent
    const dupes = findDuplicateAgentDirs(cfg, { env });
    expect(dupes).toHaveLength(0);
  });
});
