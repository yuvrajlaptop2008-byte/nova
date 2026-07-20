import fs from "node:fs/promises";
import path from "node:path";
import { expect, it } from "vitest";
import { closeNovaStateDatabaseForTest } from "../state/nova-state-db.js";
import { createNovaTestState } from "../test-utils/nova-test-state.js";
import { createAgent } from "./agent-create.js";
import {
  DEFAULT_IDENTITY_FILENAME,
  ensureAgentWorkspace,
  isWorkspaceBootstrapPending,
} from "./workspace.js";

it("keeps a fresh named workspace pending through the first run setup", async () => {
  const state = await createNovaTestState({
    layout: "state-only",
    scenario: "minimal",
    label: "named-agent-hatch",
  });
  const workspace = state.path("named-workspace");

  try {
    const created = await createAgent({ name: "Researcher", workspace });

    expect(created).toMatchObject({ status: "created", bootstrapPending: true });
    expect(await isWorkspaceBootstrapPending(workspace)).toBe(true);

    const firstRunWorkspace = await ensureAgentWorkspace({
      dir: workspace,
      ensureBootstrapFiles: true,
    });
    expect(firstRunWorkspace.bootstrapPending).toBe(true);
    expect(await isWorkspaceBootstrapPending(workspace)).toBe(true);
    expect(
      await fs.readFile(path.join(workspace, DEFAULT_IDENTITY_FILENAME), "utf8"),
    ).not.toContain("Researcher");
  } finally {
    closeNovaStateDatabaseForTest();
    await state.cleanup();
  }
});
