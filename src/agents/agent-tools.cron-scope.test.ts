/**
 * Tests cron-triggered tool assembly.
 * Ensures cron runs scope cron tool behavior to self-removal of the current
 * job only.
 */
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AnyAgentTool } from "./tools/common.js";

const mocks = vi.hoisted(() => {
  const stubTool = (name: string) =>
    ({
      name,
      label: name,
      displaySummary: name,
      description: name,
      parameters: { type: "object", properties: {} },
      execute: vi.fn(),
    }) satisfies AnyAgentTool;

  return {
    createNovaToolsOptions: vi.fn(),
    stubTool,
  };
});

vi.mock("./nova-tools.js", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./nova-tools.js")>();
  return {
    createNovaTools: (options: unknown) => {
      mocks.createNovaToolsOptions(options);
      return [mocks.stubTool("cron")];
    },
    filterToolsByClientCaps: actual.filterToolsByClientCaps,
  };
});

import "./test-helpers/fast-bash-tools.js";
import "./test-helpers/fast-coding-tools.js";
import { createNovaCodingTools } from "./agent-tools.js";

function firstNovaToolsOptions(): { cronSelfRemoveOnlyJobId?: string } | undefined {
  return mocks.createNovaToolsOptions.mock.calls[0]?.[0] as
    | { cronSelfRemoveOnlyJobId?: string }
    | undefined;
}

describe("createNovaCodingTools cron scope", () => {
  beforeEach(() => {
    mocks.createNovaToolsOptions.mockClear();
  });

  it("scopes cron-triggered jobs to self-removal", () => {
    const tools = createNovaCodingTools({
      trigger: "cron",
      jobId: "job-current",
    });

    expect(tools.map((tool) => tool.name)).toContain("cron");
    expect(firstNovaToolsOptions()?.cronSelfRemoveOnlyJobId).toBe("job-current");
  });

  it("does not scope non-cron sessions", () => {
    createNovaCodingTools({
      trigger: "user",
      jobId: "job-current",
    });

    expect(firstNovaToolsOptions()?.cronSelfRemoveOnlyJobId).toBeUndefined();
  });
});
