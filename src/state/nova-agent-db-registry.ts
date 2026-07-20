import { existsSync, lstatSync, statSync } from "node:fs";
import path from "node:path";
import {
  clearNodeSqliteKyselyCacheForDatabase,
  executeSqliteQuerySync,
  getNodeSqliteKysely,
} from "../infra/kysely-sync.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import { resolveSqliteDatabaseFilePaths } from "../infra/sqlite-files.js";
import { readSqliteUserVersion } from "../infra/sqlite-user-version.js";
import { normalizeAgentId } from "../routing/session-key.js";
import {
  NOVA_AGENT_SCHEMA_VERSION,
  type NovaRegisteredAgentDatabase,
} from "./nova-agent-db-contract.js";
import type { DB as NovaStateKyselyDatabase } from "./nova-state-db.generated.js";
import {
  detectNovaStateDatabaseSchemaMigrations,
  NOVA_SQLITE_BUSY_TIMEOUT_MS,
  NOVA_STATE_SCHEMA_VERSION,
  runNovaStateWriteTransaction,
  type NovaStateDatabaseOptions,
} from "./nova-state-db.js";
import { resolveNovaStateSqlitePath } from "./nova-state-db.paths.js";

type NovaAgentRegistryDatabase = Pick<NovaStateKyselyDatabase, "agent_databases">;

export function registerNovaAgentDatabase(params: {
  agentId: string;
  path: string;
  env?: NodeJS.ProcessEnv;
}): void {
  let sizeBytes: number | null = null;
  try {
    sizeBytes = statSync(params.path).size;
  } catch {
    sizeBytes = null;
  }
  const lastSeenAt = Date.now();
  runNovaStateWriteTransaction(
    (database) => {
      const db = getNodeSqliteKysely<NovaAgentRegistryDatabase>(database.db);
      executeSqliteQuerySync(
        database.db,
        db
          .insertInto("agent_databases")
          .values({
            agent_id: params.agentId,
            path: params.path,
            schema_version: NOVA_AGENT_SCHEMA_VERSION,
            last_seen_at: lastSeenAt,
            size_bytes: sizeBytes,
          })
          .onConflict((conflict) =>
            conflict.columns(["agent_id", "path"]).doUpdateSet({
              schema_version: NOVA_AGENT_SCHEMA_VERSION,
              last_seen_at: lastSeenAt,
              size_bytes: sizeBytes,
            }),
          ),
      );
    },
    { env: params.env },
  );
}

export function unregisterNovaAgentDatabase(params: {
  agentId: string;
  path: string;
  env?: NodeJS.ProcessEnv;
}): void {
  runNovaStateWriteTransaction(
    (database) => {
      const db = getNodeSqliteKysely<NovaAgentRegistryDatabase>(database.db);
      executeSqliteQuerySync(
        database.db,
        db
          .deleteFrom("agent_databases")
          .where("agent_id", "=", params.agentId)
          .where("path", "=", params.path),
      );
    },
    { env: params.env },
  );
}

function hasUnavailableMissingSqlitePath(pathname: string): boolean {
  for (const candidate of resolveSqliteDatabaseFilePaths(pathname)) {
    try {
      lstatSync(candidate);
      return true;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
        return true;
      }
    }
  }

  let ancestor = path.dirname(pathname);
  while (true) {
    try {
      const stat = lstatSync(ancestor);
      if (!stat.isSymbolicLink()) {
        return !stat.isDirectory();
      }
      try {
        return !statSync(ancestor).isDirectory();
      } catch {
        return true;
      }
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
        return true;
      }
    }
    const parent = path.dirname(ancestor);
    if (parent === ancestor) {
      return false;
    }
    ancestor = parent;
  }
}

/** List agent databases recorded in the shared Nova state registry. */
export function listNovaRegisteredAgentDatabases(
  options: NovaStateDatabaseOptions = {},
): NovaRegisteredAgentDatabase[] {
  const pathname = path.resolve(
    options.path ?? resolveNovaStateSqlitePath(options.env ?? process.env),
  );
  if (!existsSync(pathname)) {
    if (hasUnavailableMissingSqlitePath(pathname)) {
      throw new Error(`Nova state database ${pathname} is unavailable.`);
    }
    return [];
  }
  if (detectNovaStateDatabaseSchemaMigrations(options).length > 0) {
    throw new Error(
      `Nova state database ${pathname} has a legacy agent database registry schema; run nova doctor --fix to migrate it.`,
    );
  }

  const sqlite = requireNodeSqlite();
  const database = new sqlite.DatabaseSync(pathname, { readOnly: true });
  try {
    database.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
    if (readSqliteUserVersion(database) > NOVA_STATE_SCHEMA_VERSION) {
      throw new Error(`Nova state database ${pathname} uses a newer schema than this Nova build.`);
    }
    const registryTable = database
      .prepare("SELECT type FROM sqlite_master WHERE name = 'agent_databases'")
      .get() as { type?: unknown } | undefined;
    if (!registryTable) {
      return [];
    }
    if (registryTable.type !== "table") {
      throw new Error(`Nova state database ${pathname} has an invalid agent registry.`);
    }
    const db = getNodeSqliteKysely<NovaAgentRegistryDatabase>(database);
    const rows = executeSqliteQuerySync(
      database,
      db
        .selectFrom("agent_databases")
        .selectAll()
        .orderBy("agent_id", "asc")
        .orderBy("path", "asc"),
    ).rows;
    return rows.map((row) => ({
      agentId: normalizeAgentId(row.agent_id),
      path: row.path,
      schemaVersion: row.schema_version,
      lastSeenAt: row.last_seen_at,
      sizeBytes: row.size_bytes,
    }));
  } finally {
    clearNodeSqliteKyselyCacheForDatabase(database);
    database.close();
  }
}
