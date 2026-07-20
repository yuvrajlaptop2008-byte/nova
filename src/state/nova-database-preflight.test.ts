import { afterAll, afterEach, describe, expect, it } from "vitest";
import packageJson from "../../package.json" with { type: "json" };
import { cleanupTempDirs, makeTempDir } from "../../test/helpers/temp-dir.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import {
  closeNovaAgentDatabasesForTest,
  NOVA_AGENT_SCHEMA_VERSION,
  openNovaAgentDatabase,
} from "./nova-agent-db.js";
import { preflightNovaDatabaseSchemas } from "./nova-database-preflight.js";
import {
  closeNovaStateDatabaseForTest,
  NOVA_STATE_SCHEMA_VERSION,
  openNovaStateDatabase,
} from "./nova-state-db.js";

const tempDirs: string[] = [];

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
});

afterAll(() => cleanupTempDirs(tempDirs));

describe("Nova database schema preflight", () => {
  it("keeps package schema support metadata aligned", () => {
    expect(packageJson.nova.schemaVersions).toEqual({
      state: NOVA_STATE_SCHEMA_VERSION,
      agent: NOVA_AGENT_SCHEMA_VERSION,
    });
  });

  it("collects newer state and registered agent schemas with writer builds", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-preflight-");
    const env = { NOVA_STATE_DIR: stateDir };
    const statePath = openNovaStateDatabase({ env }).path;
    const agentPath = openNovaAgentDatabase({ agentId: "worker-1", env }).path;
    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();

    const { DatabaseSync } = requireNodeSqlite();
    const state = new DatabaseSync(statePath);
    try {
      state.exec(`PRAGMA user_version = ${NOVA_STATE_SCHEMA_VERSION + 1};`);
      state
        .prepare("UPDATE schema_meta SET app_version = ? WHERE meta_key = 'primary'")
        .run("state-writer-build");
    } finally {
      state.close();
    }
    const agent = new DatabaseSync(agentPath);
    try {
      agent.exec(`PRAGMA user_version = ${NOVA_AGENT_SCHEMA_VERSION + 1};`);
      agent
        .prepare("UPDATE schema_meta SET app_version = ? WHERE meta_key = 'primary'")
        .run("agent-writer-build");
    } finally {
      agent.close();
    }

    expect(
      preflightNovaDatabaseSchemas({
        env,
        supportedVersions: {
          state: NOVA_STATE_SCHEMA_VERSION,
          agent: NOVA_AGENT_SCHEMA_VERSION,
        },
      }),
    ).toEqual({
      incompatible: [
        {
          kind: "state",
          path: statePath,
          foundVersion: NOVA_STATE_SCHEMA_VERSION + 1,
          supportedVersion: NOVA_STATE_SCHEMA_VERSION,
          writerAppVersion: "state-writer-build",
        },
        {
          kind: "agent",
          path: agentPath,
          agentId: "worker-1",
          foundVersion: NOVA_AGENT_SCHEMA_VERSION + 1,
          supportedVersion: NOVA_AGENT_SCHEMA_VERSION,
          writerAppVersion: "agent-writer-build",
        },
      ],
      indeterminate: [],
    });
  });

  it("reports an existing unreadable state database as indeterminate", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-preflight-unreadable-state-");
    const env = { NOVA_STATE_DIR: stateDir };
    const statePath = openNovaStateDatabase({ env }).path;
    closeNovaStateDatabaseForTest();
    fs.writeFileSync(statePath, "not a sqlite database");

    expect(
      preflightNovaDatabaseSchemas({
        env,
        supportedVersions: {
          state: NOVA_STATE_SCHEMA_VERSION,
          agent: NOVA_AGENT_SCHEMA_VERSION,
        },
      }),
    ).toEqual({
      incompatible: [],
      indeterminate: [
        { kind: "state", path: statePath, reason: expect.stringMatching(/database|file/iu) },
      ],
    });
  });

  it("reports a failed agent registry query as indeterminate", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-preflight-registry-");
    const env = { NOVA_STATE_DIR: stateDir };
    const statePath = openNovaStateDatabase({ env }).path;
    closeNovaStateDatabaseForTest();
    const { DatabaseSync } = requireNodeSqlite();
    const state = new DatabaseSync(statePath);
    try {
      state.exec("DROP TABLE agent_databases; CREATE TABLE agent_databases (bad TEXT) STRICT;");
    } finally {
      state.close();
    }

    expect(
      preflightNovaDatabaseSchemas({
        env,
        supportedVersions: {
          state: NOVA_STATE_SCHEMA_VERSION,
          agent: NOVA_AGENT_SCHEMA_VERSION,
        },
      }),
    ).toEqual({
      incompatible: [],
      indeterminate: [
        {
          kind: "state",
          path: statePath,
          reason: expect.stringContaining("agent database registry query failed"),
        },
      ],
    });
  });

  it("reports an existing unreadable registered agent database as indeterminate", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-preflight-unreadable-agent-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentPath = openNovaAgentDatabase({ agentId: "worker-1", env }).path;
    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();
    fs.writeFileSync(agentPath, "not a sqlite database");

    expect(
      preflightNovaDatabaseSchemas({
        env,
        supportedVersions: {
          state: NOVA_STATE_SCHEMA_VERSION,
          agent: NOVA_AGENT_SCHEMA_VERSION,
        },
      }),
    ).toEqual({
      incompatible: [],
      indeterminate: [
        { kind: "agent", path: agentPath, reason: expect.stringMatching(/database|file/iu) },
      ],
    });
  });
});
import fs from "node:fs";
