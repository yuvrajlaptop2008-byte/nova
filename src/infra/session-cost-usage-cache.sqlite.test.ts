import fs from "node:fs";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { cleanupTempDirs, makeTempDir } from "../../test/helpers/temp-dir.js";
import {
  closeNovaAgentDatabasesForTest,
  openNovaAgentDatabase,
  resolveNovaAgentSqlitePath,
} from "../state/nova-agent-db.js";
import { closeNovaStateDatabaseForTest, openNovaStateDatabase } from "../state/nova-state-db.js";
import { withEnv } from "../test-utils/env.js";
import {
  isSessionCostUsageRefreshRunning,
  readSessionCostUsageRollupRows,
  writeSessionCostUsageRollup,
} from "./session-cost-usage-cache.sqlite.js";

const tempDirs: string[] = [];

function countRegisteredAgentDatabases(): number {
  const row = openNovaStateDatabase()
    .db.prepare("SELECT count(*) AS count FROM agent_databases")
    .get() as {
    count: number;
  };
  return row.count;
}

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
  cleanupTempDirs(tempDirs);
});

describe("session cost usage SQLite cache", () => {
  it("returns empty values without creating a missing agent database", () => {
    const stateDir = makeTempDir(tempDirs, "nova-usage-cache-missing-");

    withEnv({ NOVA_STATE_DIR: stateDir }, () => {
      const databasePath = resolveNovaAgentSqlitePath({ agentId: "worker-1" });

      expect(readSessionCostUsageRollupRows("worker-1", databasePath)).toEqual([]);
      expect(isSessionCostUsageRefreshRunning("worker-1", databasePath)).toBe(false);
      expect(fs.existsSync(databasePath)).toBe(false);
      expect(fs.existsSync(path.join(stateDir, "state", "nova.sqlite"))).toBe(false);
    });
  });

  it("does not register readonly cache reads while writes still register", () => {
    const stateDir = makeTempDir(tempDirs, "nova-usage-cache-registry-");

    withEnv({ NOVA_STATE_DIR: stateDir }, () => {
      const agentId = "worker-1";
      const database = openNovaAgentDatabase({ agentId });
      const databasePath = database.path;
      closeNovaAgentDatabasesForTest();

      const stateDatabase = openNovaStateDatabase();
      stateDatabase.db.prepare("DELETE FROM agent_databases").run();
      expect(countRegisteredAgentDatabases()).toBe(0);

      expect(readSessionCostUsageRollupRows(agentId, databasePath)).toEqual([]);
      expect(isSessionCostUsageRefreshRunning(agentId, databasePath)).toBe(false);
      expect(countRegisteredAgentDatabases()).toBe(0);

      expect(
        writeSessionCostUsageRollup({
          agentId,
          databasePath,
          rollupId: "session.jsonl",
          previousValueJson: null,
          valueJson: "{}",
          updatedAt: 1,
        }),
      ).toBe(true);
      expect(countRegisteredAgentDatabases()).toBe(1);
    });
  });
});
