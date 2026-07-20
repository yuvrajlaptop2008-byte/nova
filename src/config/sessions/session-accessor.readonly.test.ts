import fs from "node:fs";
import { afterEach, describe, expect, it } from "vitest";
import { cleanupTempDirs, makeTempDir } from "../../../test/helpers/temp-dir.js";
import {
  closeNovaAgentDatabasesForTest,
  isNovaAgentDatabaseOpen,
  resolveNovaAgentSqlitePath,
} from "../../state/nova-agent-db.js";
import { closeNovaStateDatabaseForTest, openNovaStateDatabase } from "../../state/nova-state-db.js";
import {
  listSessionEntries,
  listSessionEntriesReadOnly,
  upsertSessionEntry,
} from "./session-accessor.js";

const tempDirs: string[] = [];

function countRegisteredAgentDatabases(env: NodeJS.ProcessEnv): number {
  const row = openNovaStateDatabase({ env })
    .db.prepare("SELECT count(*) AS count FROM agent_databases")
    .get() as { count: number };
  return row.count;
}

function clearRegisteredAgentDatabases(env: NodeJS.ProcessEnv): void {
  openNovaStateDatabase({ env }).db.prepare("DELETE FROM agent_databases").run();
}

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
  cleanupTempDirs(tempDirs);
});

describe("session accessor readonly listing", () => {
  it("returns the same entries as the writable listing for a populated agent database", async () => {
    const stateDir = makeTempDir(tempDirs, "nova-session-readonly-populated-");
    const env = { NOVA_STATE_DIR: stateDir };
    const listScope = { agentId: "worker-1", env };

    await upsertSessionEntry(
      { ...listScope, sessionKey: "agent:worker-1:main" },
      { sessionId: "session-1", updatedAt: 10 },
    );
    await upsertSessionEntry(
      { ...listScope, sessionKey: "agent:worker-1:telegram:dm:42" },
      { sessionId: "session-2", updatedAt: 20 },
    );
    const writableEntries = listSessionEntries(listScope);
    closeNovaAgentDatabasesForTest();

    expect(listSessionEntriesReadOnly(listScope)).toEqual(writableEntries);
  });

  it("returns an empty list without creating or registering a missing agent database", () => {
    const stateDir = makeTempDir(tempDirs, "nova-session-readonly-missing-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentId = "worker-1";
    const databasePath = resolveNovaAgentSqlitePath({ agentId, env });
    clearRegisteredAgentDatabases(env);

    expect(listSessionEntriesReadOnly({ agentId, env })).toEqual([]);
    expect(fs.existsSync(databasePath)).toBe(false);
    expect(countRegisteredAgentDatabases(env)).toBe(0);
  });

  it("does not register a populated database during readonly health-style listing", async () => {
    const stateDir = makeTempDir(tempDirs, "nova-session-readonly-registry-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentId = "worker-1";
    const scope = { agentId, env };

    await upsertSessionEntry(
      { ...scope, sessionKey: "agent:worker-1:main" },
      { sessionId: "session-1", updatedAt: 10 },
    );
    const databasePath = resolveNovaAgentSqlitePath({ agentId, env });
    closeNovaAgentDatabasesForTest();
    clearRegisteredAgentDatabases(env);

    expect(listSessionEntriesReadOnly(scope)).toHaveLength(1);
    expect(countRegisteredAgentDatabases(env)).toBe(0);
    expect(isNovaAgentDatabaseOpen(databasePath)).toBe(false);
  });
});
