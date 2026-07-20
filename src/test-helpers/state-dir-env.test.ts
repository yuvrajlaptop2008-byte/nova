// State dir environment tests cover isolated state directory env helpers.
import fs from "node:fs/promises";
import path from "node:path";
import { describe, expect, it } from "vitest";
import {
  restoreStateDirEnv,
  setStateDirEnv,
  snapshotStateDirEnv,
  withStateDirEnv,
} from "./state-dir-env.js";

type EnvSnapshot = {
  nova?: string;
};

function snapshotCurrentStateDirVars(): EnvSnapshot {
  return {
    nova: process.env.NOVA_STATE_DIR,
  };
}

function expectStateDirVars(snapshot: EnvSnapshot) {
  expect(process.env.NOVA_STATE_DIR).toBe(snapshot.nova);
}

async function expectPathMissing(filePath: string) {
  try {
    await fs.stat(filePath);
    throw new Error(`Expected ${filePath} to be missing`);
  } catch (error) {
    expect((error as NodeJS.ErrnoException).code).toBe("ENOENT");
  }
}

async function expectStateDirEnvRestored(params: {
  prev: EnvSnapshot;
  capturedStateDir: string;
  capturedTempRoot: string;
}) {
  expectStateDirVars(params.prev);
  await expectPathMissing(params.capturedStateDir);
  await expectPathMissing(params.capturedTempRoot);
}

describe("state-dir-env helpers", () => {
  it("set/snapshot/restore round-trips NOVA_STATE_DIR", () => {
    const prev = snapshotCurrentStateDirVars();
    const snapshot = snapshotStateDirEnv();

    setStateDirEnv("/tmp/nova-state-dir-test");
    expect(process.env.NOVA_STATE_DIR).toBe("/tmp/nova-state-dir-test");

    restoreStateDirEnv(snapshot);
    expectStateDirVars(prev);
  });

  it("withStateDirEnv sets env for callback and cleans up temp root", async () => {
    const prev = snapshotCurrentStateDirVars();

    let capturedTempRoot = "";
    let capturedStateDir = "";
    await withStateDirEnv("nova-state-dir-env-", async ({ tempRoot, stateDir }) => {
      capturedTempRoot = tempRoot;
      capturedStateDir = stateDir;
      expect(process.env.NOVA_STATE_DIR).toBe(stateDir);
      await fs.writeFile(path.join(stateDir, "probe.txt"), "ok", "utf8");
    });

    await expectStateDirEnvRestored({ prev, capturedStateDir, capturedTempRoot });
  });

  it("withStateDirEnv restores env and cleans temp root when callback throws", async () => {
    const prev = snapshotCurrentStateDirVars();

    let capturedTempRoot = "";
    let capturedStateDir = "";
    await expect(
      withStateDirEnv("nova-state-dir-env-", async ({ tempRoot, stateDir }) => {
        capturedTempRoot = tempRoot;
        capturedStateDir = stateDir;
        throw new Error("boom");
      }),
    ).rejects.toThrow("boom");

    await expectStateDirEnvRestored({ prev, capturedStateDir, capturedTempRoot });
  });
});
