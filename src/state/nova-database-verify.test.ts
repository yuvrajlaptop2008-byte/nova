import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { afterAll, afterEach, describe, expect, it } from "vitest";
import { cleanupTempDirs, makeTempDir } from "../../test/helpers/temp-dir.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import { readSqliteNumberPragma } from "../infra/sqlite-pragma.test-support.js";
import {
  clearNovaAgentDatabaseOpenFailure,
  closeNovaAgentDatabasesForTest,
  openNovaAgentDatabase,
} from "./nova-agent-db.js";
import {
  applyNovaDatabaseVerificationResults,
  runDatabaseVerifyWorker,
} from "./nova-database-verify.impl.js";
import {
  type NovaDatabaseVerifyTarget,
  verifyNovaDatabases,
} from "./nova-database-verify.worker.js";
import {
  clearNovaDatabaseQuarantine,
  readNovaDatabaseQuarantine,
  recordNovaDatabaseQuarantine,
} from "./nova-quarantine-store.js";
import {
  closeNovaStateDatabaseForTest,
  openNovaStateDatabase,
  repairNovaStateDatabaseSchema,
} from "./nova-state-db.js";

const tempDirs: string[] = [];

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
});

afterAll(() => cleanupTempDirs(tempDirs));

function createUnsafeIndexDrift(databasePath: string): void {
  const { DatabaseSync } = requireNodeSqlite();
  const database = new DatabaseSync(databasePath);
  try {
    database.exec(`
      CREATE TABLE unsafe_index_records (
        id INTEGER PRIMARY KEY,
        indexed_value TEXT NOT NULL,
        alternate_value TEXT NOT NULL
      );
      CREATE INDEX unsafe_index_records_value ON unsafe_index_records(indexed_value);
      INSERT INTO unsafe_index_records (indexed_value, alternate_value)
      VALUES ('alpha', 'zeta'), ('beta', 'eta'), ('gamma', 'theta');
    `);
    database.enableDefensive?.(false);
    database.exec("PRAGMA writable_schema = ON;");
    database
      .prepare(
        "UPDATE sqlite_schema SET sql = 'CREATE INDEX unsafe_index_records_value ON unsafe_index_records(alternate_value)' WHERE name = 'unsafe_index_records_value'",
      )
      .run();
    const schemaVersion = readSqliteNumberPragma(database, "schema_version");
    database.exec(`PRAGMA writable_schema = OFF; PRAGMA schema_version = ${schemaVersion + 1};`);
  } finally {
    database.close();
  }
}

function quarantineStorePath(stateDir: string): string {
  return path.join(stateDir, "state", "nova-quarantine.sqlite");
}

describe("Nova database integrity verifier", () => {
  it("detects corruption off-thread, quarantines it, and latches later opens", async () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentPath = openNovaAgentDatabase({ agentId: "worker-1", env }).path;
    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();
    createUnsafeIndexDrift(agentPath);
    const targets: NovaDatabaseVerifyTarget[] = [
      { kind: "agent", label: "Nova agent database worker-1", path: agentPath },
    ];

    const directResults = verifyNovaDatabases(targets);
    expect(directResults).toEqual([
      {
        path: agentPath,
        ok: false,
        error: expect.stringMatching(/missing from index unsafe_index_records_value/iu),
        terminal: true,
      },
    ]);
    await expect(runDatabaseVerifyWorker(targets)).resolves.toEqual(directResults);

    // The drift lives outside schema_meta, so the rescoped open still succeeds;
    // the recorder must then quarantine this live handle, not just future opens.
    const liveHandle = openNovaAgentDatabase({ agentId: "worker-1", env });
    expect(liveHandle.db.isOpen).toBe(true);

    applyNovaDatabaseVerificationResults({
      env,
      results: directResults,
      targets,
    });
    expect(liveHandle.db.isOpen).toBe(false);
    expect(readNovaDatabaseQuarantine(agentPath, { env })).toEqual({
      kind: "agent",
      quarantinedAt: expect.any(Number),
      reason: directResults[0]?.error,
    });

    expect(() => openNovaAgentDatabase({ agentId: "worker-1", env })).toThrow(
      expect.objectContaining({ name: "SqliteIntegrityError" }),
    );

    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();
    expect(() => openNovaAgentDatabase({ agentId: "worker-1", env })).toThrow(
      expect.objectContaining({
        name: "SqliteIntegrityError",
        message: expect.stringContaining(directResults[0]?.error ?? ""),
      }),
    );
    clearNovaAgentDatabaseOpenFailure(agentPath, { env });
    expect(openNovaAgentDatabase({ agentId: "worker-1", env }).db.isOpen).toBe(true);
  });

  it("reports an uncleared quarantine row instead of claiming repair success", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-clear-failure-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentPath = openNovaAgentDatabase({ agentId: "worker-1", env }).path;
    openNovaStateDatabase({ env });
    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();
    applyNovaDatabaseVerificationResults({
      env,
      results: [{ path: agentPath, ok: false, error: "corrupt index", terminal: true }],
      targets: [{ kind: "agent", label: "Nova agent database worker-1", path: agentPath }],
    });
    closeNovaStateDatabaseForTest();

    const storePath = quarantineStorePath(stateDir);
    // A read-only quarantine store cannot drop the row; the clear must say so
    // instead of letting doctor report success while the next open still refuses.
    fs.chmodSync(storePath, 0o444);
    try {
      expect(clearNovaAgentDatabaseOpenFailure(agentPath, { env })).toBe(false);
      expect(
        recordNovaDatabaseQuarantine({
          env,
          kind: "agent",
          path: agentPath,
          reason: "new reason",
        }),
      ).toBe(false);
    } finally {
      fs.chmodSync(storePath, 0o600);
    }
    expect(clearNovaAgentDatabaseOpenFailure(agentPath, { env })).toBe(true);
    expect(openNovaAgentDatabase({ agentId: "worker-1", env }).db.isOpen).toBe(true);
  });

  it("keeps healthy opens on the missing-store fast path", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-clean-");
    const env = { NOVA_STATE_DIR: stateDir };

    openNovaStateDatabase({ env });
    openNovaAgentDatabase({ agentId: "worker-1", env });

    expect(fs.existsSync(quarantineStorePath(stateDir))).toBe(false);
  });

  it("records and clears dedicated quarantine rows with rollback journaling", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-store-");
    const env = { NOVA_STATE_DIR: stateDir };
    const databasePath = path.join(stateDir, "agent.sqlite");
    const storePath = quarantineStorePath(stateDir);

    expect(clearNovaDatabaseQuarantine(databasePath, { env })).toBe(true);
    expect(
      recordNovaDatabaseQuarantine({
        env,
        kind: "agent",
        path: databasePath,
        reason: "corrupt index",
      }),
    ).toBe(true);
    expect(readNovaDatabaseQuarantine(databasePath, { env })).toEqual({
      kind: "agent",
      quarantinedAt: expect.any(Number),
      reason: "corrupt index",
    });

    const { DatabaseSync } = requireNodeSqlite();
    const raw = new DatabaseSync(storePath, { readOnly: true });
    try {
      expect(raw.prepare("PRAGMA journal_mode").get()).toEqual({ journal_mode: "delete" });
      expect(readSqliteNumberPragma(raw, "synchronous")).toBe(2);
      expect(readSqliteNumberPragma(raw, "user_version")).toBe(1);
    } finally {
      raw.close();
    }
    if (process.platform !== "win32") {
      expect(fs.statSync(path.dirname(storePath)).mode & 0o777).toBe(0o700);
      expect(fs.statSync(storePath).mode & 0o777).toBe(0o600);
    }
    expect(clearNovaDatabaseQuarantine(databasePath, { env })).toBe(true);
    expect(clearNovaDatabaseQuarantine(databasePath, { env })).toBe(true);
    expect(readNovaDatabaseQuarantine(databasePath, { env })).toBeUndefined();
  });

  it("recovers an interrupted empty quarantine-store initialization", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-empty-store-");
    const env = { NOVA_STATE_DIR: stateDir };
    const databasePath = path.join(stateDir, "agent.sqlite");
    const storePath = quarantineStorePath(stateDir);
    fs.mkdirSync(path.dirname(storePath), { recursive: true });
    fs.writeFileSync(storePath, "", { mode: 0o600 });

    expect(readNovaDatabaseQuarantine(databasePath, { env })).toBeUndefined();
    expect(
      recordNovaDatabaseQuarantine({
        env,
        kind: "agent",
        path: databasePath,
        reason: "corrupt index",
      }),
    ).toBe(true);
    expect(readNovaDatabaseQuarantine(databasePath, { env })?.reason).toBe("corrupt index");
  });

  it.skipIf(process.platform === "win32")(
    "recovers a hot rollback journal before reading quarantine",
    () => {
      const stateDir = makeTempDir(tempDirs, "nova-database-verify-hot-journal-");
      const env = { NOVA_STATE_DIR: stateDir };
      const databasePath = path.join(stateDir, "agent.sqlite");
      const storePath = quarantineStorePath(stateDir);
      expect(
        recordNovaDatabaseQuarantine({
          env,
          kind: "agent",
          path: databasePath,
          reason: "committed reason",
        }),
      ).toBe(true);

      const crashed = spawnSync(
        process.execPath,
        [
          "--no-warnings",
          "--input-type=module",
          "-e",
          `
            import { DatabaseSync } from "node:sqlite";
            const database = new DatabaseSync(process.env.NOVA_QUARANTINE_TEST_PATH);
            database.exec("PRAGMA journal_mode = DELETE; PRAGMA synchronous = FULL; BEGIN IMMEDIATE;");
            database.prepare("UPDATE quarantined_databases SET reason = 'uncommitted reason'").run();
            process.kill(process.pid, "SIGKILL");
          `,
        ],
        { env: { ...process.env, NOVA_QUARANTINE_TEST_PATH: storePath } },
      );
      expect(crashed.signal).toBe("SIGKILL");
      expect(fs.existsSync(`${storePath}-journal`)).toBe(true);

      expect(readNovaDatabaseQuarantine(databasePath, { env })?.reason).toBe("committed reason");
    },
  );

  it("does not latch transient verifier errors", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-transient-");
    const env = { NOVA_STATE_DIR: stateDir };
    const agentPath = openNovaAgentDatabase({ agentId: "worker-1", env }).path;
    closeNovaAgentDatabasesForTest();
    closeNovaStateDatabaseForTest();
    const targets: NovaDatabaseVerifyTarget[] = [
      { kind: "agent", label: "Nova agent database worker-1", path: agentPath },
    ];

    applyNovaDatabaseVerificationResults({
      env,
      results: [{ path: agentPath, ok: false, error: "Error: database is busy", terminal: false }],
      targets,
    });

    expect(openNovaAgentDatabase({ agentId: "worker-1", env }).db.isOpen).toBe(true);
  });

  it("persists state failure quarantine across restart until doctor repair", () => {
    const stateDir = makeTempDir(tempDirs, "nova-database-verify-state-failure-");
    const env = { NOVA_STATE_DIR: stateDir };
    const statePath = openNovaStateDatabase({ env }).path;
    closeNovaStateDatabaseForTest();
    const targets: NovaDatabaseVerifyTarget[] = [
      { kind: "state", label: "Nova state database", path: statePath },
    ];

    applyNovaDatabaseVerificationResults({
      env,
      results: [{ path: statePath, ok: false, error: "corrupt index", terminal: true }],
      targets,
    });

    const { DatabaseSync } = requireNodeSqlite();
    const raw = new DatabaseSync(quarantineStorePath(stateDir), { readOnly: true });
    try {
      expect(
        raw.prepare("SELECT kind, reason FROM quarantined_databases WHERE path = ?").get(statePath),
      ).toEqual({ kind: "state", reason: "corrupt index" });
    } finally {
      raw.close();
    }
    expect(() => openNovaStateDatabase({ env })).toThrow(
      expect.objectContaining({
        name: "SqliteIntegrityError",
        message: expect.stringContaining("corrupt index"),
      }),
    );
    closeNovaStateDatabaseForTest();
    expect(() => openNovaStateDatabase({ env })).toThrow(
      expect.objectContaining({
        name: "SqliteIntegrityError",
        message: expect.stringContaining("corrupt index"),
      }),
    );
    expect(repairNovaStateDatabaseSchema({ env }).warnings).toEqual([]);
    expect(openNovaStateDatabase({ env }).db.isOpen).toBe(true);
  });
});
