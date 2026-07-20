// Cleanup utility tests cover filesystem cleanup helpers, temp paths, and command runtime behavior.
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { expectDefined } from "@nova/normalization-core";
import { afterEach, beforeEach, describe, expect, it, test, vi } from "vitest";
import { useAutoCleanupTempDirTracker } from "../../test/helpers/temp-dir.js";
import type { NovaConfig } from "../config/config.js";
import type { RuntimeEnv } from "../runtime.js";
import { withEnvAsync } from "../test-utils/env.js";

const tempDirs = useAutoCleanupTempDirTracker(afterEach);

const workspaceStateMocks = vi.hoisted(() => ({
  deleteWorkspaceState: vi.fn(),
  prepareWorkspaceStateDeletion: vi.fn((workspaceDir: string) => ({ workspaceDir })),
}));

vi.mock("../agents/workspace-state-store.js", async () => ({
  ...(await vi.importActual<typeof import("../agents/workspace-state-store.js")>(
    "../agents/workspace-state-store.js",
  )),
  deleteWorkspaceState: workspaceStateMocks.deleteWorkspaceState,
  prepareWorkspaceStateDeletion: workspaceStateMocks.prepareWorkspaceStateDeletion,
}));

import {
  buildCleanupPlan,
  removePath,
  removeStateAndLinkedPaths,
  removeWorkspaceDirs,
} from "./cleanup-utils.js";

describe("buildCleanupPlan", () => {
  test("resolves inside-state flags and workspace dirs", () => {
    const tmpRoot = path.join(path.parse(process.cwd()).root, "tmp");
    const defaultWorkspace = path.join(tmpRoot, "nova-workspace-default");
    const opsWorkspace = path.join(tmpRoot, "nova-workspace-ops");
    const cfg = {
      agents: {
        defaults: { workspace: defaultWorkspace },
        list: [{ id: "main" }, { id: "ops", workspace: opsWorkspace }],
      },
    };
    const plan = buildCleanupPlan({
      cfg: cfg as unknown as NovaConfig,
      stateDir: path.join(tmpRoot, "nova-state"),
      configPath: path.join(tmpRoot, "nova-state", "nova.json"),
      oauthDir: path.join(tmpRoot, "nova-oauth"),
    });

    expect(plan.configInsideState).toBe(true);
    expect(plan.oauthInsideState).toBe(false);
    expect(new Set(plan.workspaceDirs)).toEqual(new Set([defaultWorkspace, opsWorkspace]));
  });

  test("includes implicit per-agent workspaces under the state dir", () => {
    const tmpRoot = path.join(path.parse(process.cwd()).root, "tmp", "nova-cleanup-plan");
    const home = path.join(tmpRoot, "home");
    const stateDir = path.join(home, ".nova");
    const cfg = {
      agents: {
        list: [{ id: "main" }, { id: "work" }],
      },
    };

    return withEnvAsync(
      {
        HOME: home,
        NOVA_STATE_DIR: stateDir,
        NOVA_WORKSPACE_DIR: undefined,
      },
      async () => {
        const plan = buildCleanupPlan({
          cfg: cfg as unknown as NovaConfig,
          stateDir,
          configPath: path.join(stateDir, "nova.json"),
          oauthDir: path.join(stateDir, "credentials"),
        });

        expect(new Set(plan.workspaceDirs)).toEqual(
          new Set([path.join(stateDir, "workspace"), path.join(stateDir, "workspace-work")]),
        );
      },
    );
  });
});

describe("cleanup path removals", () => {
  beforeEach(() => {
    workspaceStateMocks.deleteWorkspaceState.mockClear();
  });

  function createRuntimeMock() {
    return {
      log: vi.fn<(message: string) => void>(),
      error: vi.fn<(message: string) => void>(),
    } as unknown as RuntimeEnv & {
      log: ReturnType<typeof vi.fn<(message: string) => void>>;
      error: ReturnType<typeof vi.fn<(message: string) => void>>;
    };
  }

  it("removes state and only linked paths outside state", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = path.join(path.parse(process.cwd()).root, "tmp", "nova-cleanup");
    const stateRemoved = await removeStateAndLinkedPaths(
      {
        stateDir: path.join(tmpRoot, "state"),
        configPath: path.join(tmpRoot, "state", "nova.json"),
        oauthDir: path.join(tmpRoot, "oauth"),
        configInsideState: true,
        oauthInsideState: false,
      },
      runtime,
      { dryRun: true },
    );

    expect(runtime.log.mock.calls.map(([line]) => line.replaceAll("\\", "/"))).toEqual([
      "[dry-run] remove /tmp/nova-cleanup/state",
      "[dry-run] remove /tmp/nova-cleanup/oauth",
    ]);
    expect(stateRemoved).toBe(true);
  });

  it("reports when the state directory survives removal", async () => {
    const runtime = createRuntimeMock();
    const rmSpy = vi.spyOn(fs, "rm").mockRejectedValueOnce(new Error("permission denied"));

    try {
      const stateRemoved = await removeStateAndLinkedPaths(
        {
          stateDir: "/tmp/nova-cleanup-state-failure",
          configPath: "/tmp/nova-cleanup-state-failure/nova.json",
          oauthDir: "/tmp/nova-cleanup-state-failure/credentials",
          configInsideState: true,
          oauthInsideState: true,
        },
        runtime,
      );
      expect(stateRemoved).toBe(false);
    } finally {
      rmSpy.mockRestore();
    }
  });

  it("preserves nested workspace paths during state-only removal", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "nova-cleanup-"));
    const stateDir = path.join(tmpRoot, ".nova");
    const workspaceDir = path.join(stateDir, "workspace");
    const workspaceFile = path.join(workspaceDir, "project.txt");
    const configPath = path.join(stateDir, "nova.json");
    const cacheFile = path.join(stateDir, "cache.json");

    try {
      await fs.mkdir(workspaceDir, { recursive: true });
      await fs.writeFile(workspaceFile, "keep me");
      await fs.writeFile(configPath, "{}");
      await fs.writeFile(cacheFile, "remove me");

      await removeStateAndLinkedPaths(
        {
          stateDir,
          configPath,
          oauthDir: path.join(stateDir, "credentials"),
          configInsideState: true,
          oauthInsideState: true,
        },
        runtime,
        { preservePaths: [workspaceDir] },
      );

      await expect(fs.readFile(workspaceFile, "utf8")).resolves.toBe("keep me");
      await expect(fs.stat(configPath)).rejects.toThrow();
      await expect(fs.stat(cacheFile)).rejects.toThrow();
    } finally {
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });

  it("removes every workspace directory", async () => {
    const runtime = createRuntimeMock();
    const workspaces = ["/tmp/nova-workspace-1", "/tmp/nova-workspace-2"];

    await removeWorkspaceDirs(workspaces, runtime, { dryRun: true });

    const logs = runtime.log.mock.calls.map(([line]) => line);
    expect(logs).toEqual([
      "[dry-run] remove /tmp/nova-workspace-1",
      "[dry-run] remove /tmp/nova-workspace-2",
    ]);
  });

  it("deletes workspace state only after workspace removal succeeds", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = tempDirs.make("nova-cleanup-workspace-");
    const workspaceDir = path.join(tmpRoot, "workspace");

    try {
      await fs.mkdir(workspaceDir, { recursive: true });

      await removeWorkspaceDirs([workspaceDir], runtime, { removeStateRows: true });

      await expect(fs.stat(workspaceDir)).rejects.toThrow();
      expect(workspaceStateMocks.deleteWorkspaceState).toHaveBeenCalledWith({ workspaceDir });
    } finally {
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });

  it("cleans workspace state when the workspace directory is already missing", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = tempDirs.make("nova-cleanup-missing-workspace-");
    const workspaceDir = path.join(tmpRoot, "workspace");
    const siblingMarker = `${workspaceDir}.attested`;

    try {
      await fs.writeFile(
        siblingMarker,
        "nova-workspace-attestation:v1\n2026-07-15T11:00:00.000Z\n",
      );

      await removeWorkspaceDirs([workspaceDir], runtime, { removeStateRows: true });

      await expect(fs.stat(siblingMarker)).rejects.toThrow();
      expect(workspaceStateMocks.deleteWorkspaceState).toHaveBeenCalledWith({ workspaceDir });
    } finally {
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });

  it("removes a retired sibling marker after workspace removal without opening SQLite", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = tempDirs.make("nova-cleanup-legacy-");
    const workspaceDir = path.join(tmpRoot, "workspace");
    const siblingMarker = `${workspaceDir}.attested`;

    try {
      await fs.mkdir(workspaceDir, { recursive: true });
      await fs.writeFile(
        siblingMarker,
        "nova-workspace-attestation:v1\n2026-07-15T11:00:00.000Z\n",
      );

      await removeWorkspaceDirs([workspaceDir], runtime);

      await expect(fs.stat(workspaceDir)).rejects.toThrow();
      await expect(fs.stat(siblingMarker)).rejects.toThrow();
      expect(workspaceStateMocks.deleteWorkspaceState).not.toHaveBeenCalled();
    } finally {
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });

  it("does not delete workspace state during dry-run", async () => {
    const runtime = createRuntimeMock();

    await removeWorkspaceDirs(["/tmp/nova-workspace"], runtime, {
      dryRun: true,
      removeStateRows: true,
    });

    expect(workspaceStateMocks.deleteWorkspaceState).not.toHaveBeenCalled();
  });

  it("previews retired sibling-marker cleanup during workspace dry-run", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = tempDirs.make("nova-cleanup-dry-run-legacy-");
    const workspaceDir = path.join(tmpRoot, "workspace");
    const siblingMarker = `${workspaceDir}.attested`;

    try {
      await fs.mkdir(workspaceDir, { recursive: true });
      await fs.writeFile(
        siblingMarker,
        "nova-workspace-attestation:v1\n2026-07-15T11:00:00.000Z\n",
      );

      await removeWorkspaceDirs([workspaceDir], runtime, { dryRun: true });

      expect(runtime.log).toHaveBeenCalledWith(`[dry-run] remove ${siblingMarker}`);
      await expect(fs.lstat(siblingMarker)).resolves.toBeDefined();
    } finally {
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });

  it("retains workspace state when filesystem removal fails", async () => {
    const runtime = createRuntimeMock();
    const rmSpy = vi.spyOn(fs, "rm").mockRejectedValueOnce(new Error("permission denied"));

    try {
      await removeWorkspaceDirs(["/tmp/nova-workspace"], runtime, {
        removeStateRows: true,
      });
    } finally {
      rmSpy.mockRestore();
    }

    expect(workspaceStateMocks.deleteWorkspaceState).not.toHaveBeenCalled();
  });

  it("refuses to remove the current working directory", async () => {
    const runtime = createRuntimeMock();
    const result = await removePath(process.cwd(), runtime, { dryRun: true });

    expect(result.ok).toBe(false);
    expect(result.skipped).toBeUndefined();
    expect(runtime.error.mock.calls.length).toBe(1);
    expect(
      expectDefined(runtime.error.mock.calls[0], "runtime.error.mock.calls[0] test invariant")[0],
    ).toMatch(/Refusing to remove unsafe path/);
    expect(runtime.log.mock.calls.length).toBe(0);
  });

  it("refuses to remove a directory containing the current working directory", async () => {
    const runtime = createRuntimeMock();
    const tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "nova-cleanup-cwd-"));
    const nestedCwd = path.join(tmpRoot, "nested");
    const cwdSpy = vi.spyOn(process, "cwd");

    try {
      await fs.mkdir(nestedCwd);
      cwdSpy.mockReturnValue(nestedCwd);

      const result = await removePath(tmpRoot, runtime, { dryRun: true });

      expect(result.ok).toBe(false);
      expect(result.skipped).toBeUndefined();
      expect(runtime.error.mock.calls.length).toBe(1);
      expect(
        expectDefined(runtime.error.mock.calls[0], "runtime.error.mock.calls[0] test invariant")[0],
      ).toMatch(/Refusing to remove unsafe path/);
      expect(runtime.log.mock.calls.length).toBe(0);
    } finally {
      cwdSpy.mockRestore();
      await fs.rm(tmpRoot, { recursive: true, force: true });
    }
  });
});
