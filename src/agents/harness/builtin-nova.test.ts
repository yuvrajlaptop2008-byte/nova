// Built-in Nova harness tests cover logical thinking-mode boundaries.
import { beforeEach, describe, expect, it, vi } from "vitest";

const runEmbeddedAttempt = vi.hoisted(() => vi.fn());

vi.mock("../embedded-agent-runner/run/attempt.js", () => ({ runEmbeddedAttempt }));

import { createNovaAgentHarness } from "./builtin-nova.js";

describe("createNovaAgentHarness", () => {
  beforeEach(() => {
    runEmbeddedAttempt.mockReset();
    runEmbeddedAttempt.mockResolvedValue({});
  });

  it("preserves logical Ultra for the embedded attempt", async () => {
    const params = { thinkLevel: "ultra" } as never;

    await createNovaAgentHarness().runAttempt(params);

    expect(runEmbeddedAttempt).toHaveBeenCalledWith(params);
  });
});
