// Agent database cache tests cover bounded process-local SQLite handle ownership.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  closeNovaAgentDatabasesForTest,
  disposeNovaAgentDatabaseByPath,
  isNovaAgentDatabaseOpen,
  listNovaRegisteredAgentDatabases,
  NOVA_AGENT_DB_OPEN_HANDLE_CAP,
  openNovaAgentDatabase,
} from "./nova-agent-db.js";
import { closeNovaStateDatabaseForTest } from "./nova-state-db.js";

const tempStateDirs: string[] = [];

function createTempStateDir(): string {
  const stateDir = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "nova-agent-db-cache-")));
  tempStateDirs.push(stateDir);
  return stateDir;
}

function fillAgentDatabaseCache(env: NodeJS.ProcessEnv, prefix: string): void {
  for (let index = 0; index < NOVA_AGENT_DB_OPEN_HANDLE_CAP; index += 1) {
    openNovaAgentDatabase({ agentId: `${prefix}-${index}`, env });
  }
}

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
  for (const stateDir of tempStateDirs.splice(0)) {
    fs.rmSync(stateDir, { force: true, recursive: true });
  }
});

describe("nova agent database handle cache", () => {
  it("keeps only the capped number of open handles", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const databases = Array.from({ length: NOVA_AGENT_DB_OPEN_HANDLE_CAP + 1 }, (_, index) =>
      openNovaAgentDatabase({ agentId: `worker-${index}`, env }),
    );
    const leastRecentlyUsed = databases[0]!;

    expect(databases.filter((database) => database.db.isOpen)).toHaveLength(
      NOVA_AGENT_DB_OPEN_HANDLE_CAP,
    );
    expect(isNovaAgentDatabaseOpen(leastRecentlyUsed.path)).toBe(false);
    expect(leastRecentlyUsed.db.isOpen).toBe(false);
  });

  it("refreshes cache-hit recency before evicting the true LRU handle", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const recentlyUsed = openNovaAgentDatabase({ agentId: "recently-used", env });
    const untouched = Array.from({ length: NOVA_AGENT_DB_OPEN_HANDLE_CAP - 1 }, (_, index) =>
      openNovaAgentDatabase({ agentId: `untouched-${index}`, env }),
    );
    const leastRecentlyUsed = untouched[0]!;

    expect(openNovaAgentDatabase({ agentId: "recently-used", env })).toBe(recentlyUsed);
    openNovaAgentDatabase({ agentId: "newest", env });

    expect(recentlyUsed.db.isOpen).toBe(true);
    expect(isNovaAgentDatabaseOpen(recentlyUsed.path)).toBe(true);
    expect(leastRecentlyUsed.db.isOpen).toBe(false);
    expect(isNovaAgentDatabaseOpen(leastRecentlyUsed.path)).toBe(false);
  });

  it("never evicts an LRU handle with an open transaction", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const transactionOwner = openNovaAgentDatabase({ agentId: "transaction-owner", env });
    transactionOwner.db.exec("BEGIN IMMEDIATE");
    try {
      const untouched = Array.from({ length: NOVA_AGENT_DB_OPEN_HANDLE_CAP - 1 }, (_, index) =>
        openNovaAgentDatabase({ agentId: `untouched-${index}`, env }),
      );
      const leastRecentlyUsed = untouched[0]!;
      openNovaAgentDatabase({ agentId: "newest", env });

      expect(transactionOwner.db.isOpen).toBe(true);
      expect(transactionOwner.db.isTransaction).toBe(true);
      expect(isNovaAgentDatabaseOpen(transactionOwner.path)).toBe(true);
      expect(leastRecentlyUsed.db.isOpen).toBe(false);
      expect(isNovaAgentDatabaseOpen(leastRecentlyUsed.path)).toBe(false);
    } finally {
      transactionOwner.db.exec("ROLLBACK");
    }
  });

  it("reopens an evicted database without losing durable rows", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const evicted = openNovaAgentDatabase({ agentId: "evicted", env });
    evicted.db
      .prepare(
        "INSERT INTO auth_profile_state (state_key, state_json, updated_at) VALUES (?, ?, ?)",
      )
      .run("cache-eviction", JSON.stringify({ preserved: true }), 42);

    fillAgentDatabaseCache(env, "filler");
    expect(evicted.db.isOpen).toBe(false);

    const reopened = openNovaAgentDatabase({ agentId: "evicted", env });
    expect(reopened).not.toBe(evicted);
    expect(
      reopened.db
        .prepare("SELECT state_json, updated_at FROM auth_profile_state WHERE state_key = ?")
        .get("cache-eviction"),
    ).toEqual({ state_json: JSON.stringify({ preserved: true }), updated_at: 42 });
  });

  it("registers a first open without refreshing registry metadata after eviction", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const nowSpy = vi.spyOn(Date, "now").mockReturnValue(1_000);
    try {
      const evicted = openNovaAgentDatabase({ agentId: "evicted", env });
      expect(
        listNovaRegisteredAgentDatabases({ env }).find(
          (entry) => entry.agentId === "evicted" && entry.path === evicted.path,
        ),
      ).toMatchObject({ lastSeenAt: 1_000 });

      nowSpy.mockReturnValue(2_000);
      fillAgentDatabaseCache(env, "registry-filler");
      expect(evicted.db.isOpen).toBe(false);

      openNovaAgentDatabase({ agentId: "evicted", env });
      expect(
        listNovaRegisteredAgentDatabases({ env }).find(
          (entry) => entry.agentId === "evicted" && entry.path === evicted.path,
        ),
      ).toMatchObject({ lastSeenAt: 1_000 });
    } finally {
      nowSpy.mockRestore();
    }
  });

  it("validates ownership when an evicted path is requested for another agent", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const evicted = openNovaAgentDatabase({ agentId: "worker-a", env });
    fillAgentDatabaseCache(env, "ownership-filler");
    expect(evicted.db.isOpen).toBe(false);

    expect(() => openNovaAgentDatabase({ agentId: "worker-b", env, path: evicted.path })).toThrow(
      /belongs to agent worker-a/,
    );
  });

  it("revalidates and registers a database after explicit disposal", () => {
    const env = { NOVA_STATE_DIR: createTempStateDir() };
    const nowSpy = vi.spyOn(Date, "now").mockReturnValue(1_000);
    try {
      const disposed = openNovaAgentDatabase({ agentId: "disposed", env });
      expect(
        listNovaRegisteredAgentDatabases({ env }).find(
          (entry) => entry.agentId === "disposed" && entry.path === disposed.path,
        ),
      ).toMatchObject({ lastSeenAt: 1_000 });

      expect(disposeNovaAgentDatabaseByPath(disposed.path, { env })).toBe(true);
      expect(
        listNovaRegisteredAgentDatabases({ env }).some(
          (entry) => entry.agentId === "disposed" && entry.path === disposed.path,
        ),
      ).toBe(false);

      nowSpy.mockReturnValue(2_000);
      openNovaAgentDatabase({ agentId: "disposed", env, path: disposed.path });
      expect(
        listNovaRegisteredAgentDatabases({ env }).find(
          (entry) => entry.agentId === "disposed" && entry.path === disposed.path,
        ),
      ).toMatchObject({ lastSeenAt: 2_000 });
    } finally {
      nowSpy.mockRestore();
    }
  });
});
