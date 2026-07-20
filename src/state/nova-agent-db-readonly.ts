import fs from "node:fs";
import type { DatabaseSync } from "node:sqlite";
import { clearNodeSqliteKyselyCacheForDatabase } from "../infra/kysely-sync.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import { normalizeAgentId } from "../routing/session-key.js";
import type { NovaAgentDatabaseOptions } from "./nova-agent-db-contract.js";
import {
  assertExistingAgentSchemaOwner,
  assertSupportedAgentSchemaVersion,
  readExistingAgentSchemaMeta,
} from "./nova-agent-db-schema-helpers.js";
import { resolveNovaAgentSqlitePath } from "./nova-agent-db.paths.js";
import { NOVA_SQLITE_BUSY_TIMEOUT_MS } from "./nova-state-db.js";

type NovaAgentReadOnlyDatabase = {
  agentId: string;
  db: DatabaseSync;
  path: string;
};

type NovaAgentDatabaseReadOnlyResult<T> =
  | { found: true; value: T }
  | { found: false; reason: "database-missing" | "schema-missing" | "table-missing" };

function isMissingTableError(error: unknown): boolean {
  return (
    error instanceof Error &&
    (error as NodeJS.ErrnoException).code === "ERR_SQLITE_ERROR" &&
    /\bno such table:/iu.test(error.message)
  );
}

/** Read agent state without creating, registering, migrating, or joining its writable lifecycle. */
export function withNovaAgentDatabaseReadOnly<T>(
  operation: (database: NovaAgentReadOnlyDatabase) => T,
  options: NovaAgentDatabaseOptions,
): NovaAgentDatabaseReadOnlyResult<T> {
  const agentId = normalizeAgentId(options.agentId);
  const pathname = resolveNovaAgentSqlitePath({ ...options, agentId });
  if (!fs.existsSync(pathname)) {
    return { found: false, reason: "database-missing" };
  }
  const sqlite = requireNodeSqlite();
  const db = new sqlite.DatabaseSync(pathname, { readOnly: true });
  try {
    db.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
    assertSupportedAgentSchemaVersion(db, pathname);
    const schemaMeta = readExistingAgentSchemaMeta(db);
    if (!schemaMeta) {
      return { found: false, reason: "schema-missing" };
    }
    assertExistingAgentSchemaOwner(schemaMeta, agentId, pathname);
    try {
      return { found: true, value: operation({ agentId, db, path: pathname }) };
    } catch (error) {
      if (isMissingTableError(error)) {
        return { found: false, reason: "table-missing" };
      }
      throw error;
    }
  } finally {
    clearNodeSqliteKyselyCacheForDatabase(db);
    db.close();
  }
}
