import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  closeNovaStateDatabaseForTest,
  openNovaStateDatabase,
  type NovaStateDatabase,
} from "../../state/nova-state-db.js";
import {
  createDispatchEnvironmentFixtures,
  REQUEST,
  seedActivePlacement,
} from "./placement-dispatch-test-fixtures.js";
import { forceAbandonWorkerEnvironment } from "./placement-force-abandon.js";
import { createWorkerSessionPlacementStore } from "./placement-store.js";

describe("forced worker environment abandonment", () => {
  let root: string;
  let database: NovaStateDatabase;

  beforeEach(async () => {
    root = await fs.mkdtemp(path.join(await fs.realpath(os.tmpdir()), "nova-force-worker-"));
    database = openNovaStateDatabase({ env: { NOVA_STATE_DIR: root } });
  });

  afterEach(async () => {
    closeNovaStateDatabaseForTest();
    await fs.rm(root, { recursive: true, force: true });
  });

  it("records result loss and releases a pending worker claim before teardown", async () => {
    const store = createWorkerSessionPlacementStore({ database, now: () => 1_000 });
    const { environmentId } = createDispatchEnvironmentFixtures();
    const active = seedActivePlacement(store, { environmentId, ownerEpoch: 2 });
    if (active.state !== "active") {
      throw new Error("active placement fixture was not active");
    }
    const claim = store.claimTurn({
      ...REQUEST,
      claimId: "forced-claim",
      runId: "forced-run",
      owner: { kind: "worker", environmentId, ownerEpoch: 2 },
    });
    store.markWorkspaceResultPending(claim);

    await forceAbandonWorkerEnvironment({
      placements: store,
      environmentId,
      resolveWorkspacePath: async () => root,
    });

    expect(store.get(REQUEST.sessionId)).toMatchObject({
      state: "failed",
      turnClaim: null,
      recoveryError: "Cloud worker result abandoned by forced operator teardown",
    });
    expect(store.listPendingWorkspaceResults()).toEqual([]);
  });

  it("releases a pending worker claim when its workspace is already gone", async () => {
    const store = createWorkerSessionPlacementStore({ database, now: () => 1_000 });
    const { environmentId } = createDispatchEnvironmentFixtures();
    const active = seedActivePlacement(store, { environmentId, ownerEpoch: 2 });
    if (active.state !== "active") {
      throw new Error("active placement fixture was not active");
    }
    const claim = store.claimTurn({
      ...REQUEST,
      claimId: "forced-missing-workspace-claim",
      runId: "forced-missing-workspace-run",
      owner: { kind: "worker", environmentId, ownerEpoch: 2 },
    });
    store.markWorkspaceResultPending(claim);
    store.recordStagedWorkspaceResult(
      claim,
      "refs/nova/worker-results/forced-missing-workspace-claim",
    );

    await forceAbandonWorkerEnvironment({
      placements: store,
      environmentId,
      resolveWorkspacePath: async () => {
        throw new Error("session-owned managed worktree is missing");
      },
    });

    expect(store.get(REQUEST.sessionId)).toMatchObject({
      state: "failed",
      turnClaim: null,
      recoveryError: "Cloud worker result abandoned by forced operator teardown",
    });
    expect(store.listPendingWorkspaceResults()).toEqual([]);
  });
});
