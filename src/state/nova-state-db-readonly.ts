import path from "node:path";
import type { DatabaseSync } from "node:sqlite";
import { clearNodeSqliteKyselyCacheForDatabase } from "../infra/kysely-sync.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import {
  createNewerSqliteSchemaVersionError,
  readSqliteUserVersion,
} from "../infra/sqlite-user-version.js";
import {
  NOVA_SQLITE_BUSY_TIMEOUT_MS,
  NOVA_STATE_SCHEMA_VERSION,
  type NovaStateDatabaseOptions,
} from "./nova-state-db.js";
import { resolveNovaStateSqlitePath } from "./nova-state-db.paths.js";

type NovaStateReadOnlyDatabase = {
  db: DatabaseSync;
  path: string;
};

function assertSupportedSchemaVersion(db: DatabaseSync, pathname: string): void {
  const userVersion = readSqliteUserVersion(db);
  if (userVersion > NOVA_STATE_SCHEMA_VERSION) {
    throw createNewerSqliteSchemaVersionError(
      "Nova state database",
      pathname,
      userVersion,
      NOVA_STATE_SCHEMA_VERSION,
    );
  }
}

/**
 * Read shared state without joining the writable lifecycle.
 *
 * CLI metadata reads can overlap a live Gateway. Keep them off schema repair,
 * journal-mode setup, checkpoints, and permission mutation owned by writers.
 */
export function withNovaStateDatabaseReadOnly<T>(
  operation: (database: NovaStateReadOnlyDatabase) => T,
  options: NovaStateDatabaseOptions = {},
): T {
  const pathname = path.resolve(
    options.path ?? resolveNovaStateSqlitePath(options.env ?? process.env),
  );
  const sqlite = requireNodeSqlite();
  const db = new sqlite.DatabaseSync(pathname, { readOnly: true });
  try {
    db.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
    assertSupportedSchemaVersion(db, pathname);
    return operation({ db, path: pathname });
  } finally {
    clearNodeSqliteKyselyCacheForDatabase(db);
    db.close();
  }
}
