// Nova agent database stores agent-scoped persisted runtime state.
import path from "node:path";
import type { DatabaseSync } from "node:sqlite";
import { clearNodeSqliteKyselyCacheForDatabase } from "../infra/kysely-sync.js";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import { isTerminalSqliteIntegrityError } from "../infra/sqlite-integrity.js";
import { createSqliteTerminalOpenLatch } from "../infra/sqlite-terminal-open-latch.js";
import {
  runSqliteImmediateTransactionSync,
  type SqliteTransactionOptions,
} from "../infra/sqlite-transaction.js";
import {
  configureSqliteConnectionPragmas,
  configureSqlitePreSchemaPragmas,
  registerSqliteCacheExitClose,
} from "../infra/sqlite-wal.js";
import { createSubsystemLogger } from "../logging/subsystem.js";
import { normalizeAgentId } from "../routing/session-key.js";
import type {
  NovaAgentDatabase,
  NovaAgentDatabaseOptions,
  NovaAgentDatabaseOwnerInspection,
} from "./nova-agent-db-contract.js";
import { ensureNovaAgentDatabasePermissions } from "./nova-agent-db-permissions.js";
import {
  registerNovaAgentDatabase,
  unregisterNovaAgentDatabase,
} from "./nova-agent-db-registry.js";
import {
  assertExistingAgentSchemaOwner,
  assertSupportedAgentSchemaVersion,
  readExistingAgentSchemaMeta,
} from "./nova-agent-db-schema-helpers.js";
import {
  assertAgentDatabaseIntegrityBeforeMutation,
  ensureNovaAgentSchema,
} from "./nova-agent-db-schema.js";
import { resolveNovaAgentSqlitePath } from "./nova-agent-db.paths.js";
import {
  clearNovaDatabaseQuarantine,
  readNovaDatabaseQuarantine,
} from "./nova-quarantine-store.js";
import {
  createNovaDatabaseVerificationError,
  NOVA_SQLITE_BUSY_TIMEOUT_MS,
  type NovaStateDatabaseOptions,
} from "./nova-state-db.js";

export {
  NOVA_AGENT_SCHEMA_VERSION,
  type NovaAgentDatabase,
  type NovaAgentDatabaseOptions,
  type NovaAgentDatabaseOwnerInspection,
  type NovaRegisteredAgentDatabase,
} from "./nova-agent-db-contract.js";
export {
  assertNovaAgentDatabaseForMaintenance,
  migrateNovaAgentDatabaseForMaintenance,
} from "./nova-agent-db-maintenance.js";
export { ensureNovaAgentDatabasePermissions } from "./nova-agent-db-permissions.js";
export { listNovaRegisteredAgentDatabases } from "./nova-agent-db-registry.js";
export { ensureNovaAgentDatabaseSchema } from "./nova-agent-db-schema.js";
export { resolveNovaAgentSqlitePath } from "./nova-agent-db.paths.js";

/**
 * Per-agent SQLite database lifecycle and shared-state registration.
 *
 * Each opened agent database is schema-owned by one normalized agent id, cached
 * per pathname, protected with private file modes, and registered in the shared
 * Nova state database for discovery and maintenance.
 */
const NOVA_AGENT_DB_SLOW_OPEN_MS = 1_000;
// Each WAL database consumes roughly three file descriptors, so the fixed cap
// satisfies the bounded-cache policy within a predictable FD budget, without config.
export const NOVA_AGENT_DB_OPEN_HANDLE_CAP = 64;
const agentDbLog = createSubsystemLogger("state/agent-db");
const cachedDatabases = new Map<string, NovaAgentDatabase>();
// External schema changes under a live process are unsupported: doctor migrations
// require restart, so successful owner/schema validation is process-stable.
const validatedAgentDatabasePaths = new Map<string, string>();
const terminalOpenLatch = createSqliteTerminalOpenLatch({
  closeByPath: closeNovaAgentDatabaseByPath,
});

/** Latch background verification damage so later opens fail without rescanning. */
export function recordNovaAgentDatabaseOpenFailure(pathname: string, error: Error): void {
  // Quarantine revokes this process's trust because doctor may replace the file.
  validatedAgentDatabasePaths.delete(path.resolve(pathname));
  terminalOpenLatch.record(pathname, error);
}

/**
 * Clear a terminal open failure after doctor rewrites the database file.
 * Returns false when the persisted quarantine row survived; callers must
 * surface that, or the next open re-quarantines the repaired file.
 */
export function clearNovaAgentDatabaseOpenFailure(
  pathname: string,
  options: NovaStateDatabaseOptions = {},
): boolean {
  const resolvedPath = path.resolve(pathname);
  const cleared = clearNovaDatabaseQuarantine(resolvedPath, { env: options.env });
  terminalOpenLatch.clear(resolvedPath);
  return cleared;
}

function logSlowAgentDatabaseOpen(params: {
  agentId: string;
  elapsedMs: number;
  path: string;
}): void {
  if (params.elapsedMs < NOVA_AGENT_DB_SLOW_OPEN_MS) {
    return;
  }
  agentDbLog.warn("slow Nova agent database open", {
    agentId: params.agentId,
    elapsedMs: params.elapsedMs,
    path: params.path,
    thresholdMs: NOVA_AGENT_DB_SLOW_OPEN_MS,
  });
}

/** Read a database's durable role and agent owner without mutating it. */
export function inspectNovaAgentDatabaseOwner(pathname: string): NovaAgentDatabaseOwnerInspection {
  const sqlite = requireNodeSqlite();
  let db: DatabaseSync | undefined;
  try {
    db = new sqlite.DatabaseSync(pathname, { readOnly: true });
    db.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
    assertSupportedAgentSchemaVersion(db, pathname);
    const existing = readExistingAgentSchemaMeta(db);
    if (!existing) {
      return { status: "unowned" };
    }
    if (existing.role !== "agent" || !existing.agentId) {
      return { status: "unreadable" };
    }
    return { status: "owned", agentId: normalizeAgentId(existing.agentId) };
  } catch {
    return { status: "unreadable" };
  } finally {
    db?.close();
  }
}

/** Open or return a cached per-agent database after schema and owner validation. */
export function openNovaAgentDatabase(options: NovaAgentDatabaseOptions): NovaAgentDatabase {
  const agentId = normalizeAgentId(options.agentId);
  const databaseOptions = { ...options, agentId };
  const pathname = resolveNovaAgentSqlitePath(databaseOptions);
  // A live cached handle is authoritative: the recorder closes handles when it
  // latches, so a cache hit implies the path is not quarantined in this process.
  const cached = cachedDatabases.get(pathname);
  if (cached?.db.isOpen) {
    if (cached.agentId !== agentId) {
      throw new Error(
        `Nova agent database ${pathname} is already open for agent ${cached.agentId}; requested agent ${agentId}.`,
      );
    }
    cachedDatabases.delete(pathname);
    cachedDatabases.set(pathname, cached);
    return cached;
  }
  // Latched paths are quarantined; every fresh open fails fast here until
  // doctor repairs the file and clears the latch plus the persisted row.
  const terminalFailure = terminalOpenLatch.get(pathname);
  if (terminalFailure) {
    throw terminalFailure;
  }
  let persistedFailure: Error | undefined;
  try {
    const quarantine = readNovaDatabaseQuarantine(pathname, { env: databaseOptions.env });
    if (quarantine) {
      persistedFailure = createNovaDatabaseVerificationError("agent", pathname, quarantine.reason);
    }
  } catch {
    // A broken quarantine store must not brick every agent open.
    // The process latch and daily verifier still cover known damage.
  }
  if (persistedFailure) {
    recordNovaAgentDatabaseOpenFailure(pathname, persistedFailure);
    throw persistedFailure;
  }
  if (cached) {
    // A closed handle can leave Kysely and WAL helpers cached; clear both before reopening.
    cached.walMaintenance.close();
    clearNodeSqliteKyselyCacheForDatabase(cached.db);
    cachedDatabases.delete(pathname);
  }
  const openStartedAt = Date.now();
  ensureNovaAgentDatabasePermissions(pathname, databaseOptions);
  // Free a slot before constructing the new handle: under real descriptor
  // pressure the 65th open would otherwise fail before eviction could run.
  evictLruAgentDatabaseHandles();
  const sqlite = requireNodeSqlite();
  const db = new sqlite.DatabaseSync(pathname);
  // Eviction churn must avoid schema/registry busy waits on the event loop while
  // reconcile workers hold write transactions on these same agent databases.
  const isValidatedReopen = validatedAgentDatabasePaths.get(pathname) === agentId;
  const walMaintenance = (() => {
    let maintenance: NovaAgentDatabase["walMaintenance"] | undefined;
    try {
      db.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
      if (!isValidatedReopen) {
        assertSupportedAgentSchemaVersion(db, pathname);
        assertExistingAgentSchemaOwner(readExistingAgentSchemaMeta(db), agentId, pathname);
      }
      // Integrity is not process-stable: the file can be damaged while evicted.
      // This guard is read-only (no busy waits), so every physical open pays it.
      assertAgentDatabaseIntegrityBeforeMutation(db, pathname);
      configureSqlitePreSchemaPragmas(db, {
        busyTimeoutMs: NOVA_SQLITE_BUSY_TIMEOUT_MS,
      });
      maintenance = configureSqliteConnectionPragmas(db, {
        busyTimeoutMs: NOVA_SQLITE_BUSY_TIMEOUT_MS,
        databaseLabel: `nova-agent:${agentId}`,
        databasePath: pathname,
        foreignKeys: true,
        synchronous: "NORMAL",
      });
      if (!isValidatedReopen) {
        ensureNovaAgentSchema(db, agentId, pathname);
      }
      return maintenance;
    } catch (err) {
      maintenance?.close();
      db.close();
      if (
        err instanceof Error &&
        (err.name === "SqliteSchemaVersionError" || isTerminalSqliteIntegrityError(err))
      ) {
        recordNovaAgentDatabaseOpenFailure(pathname, err);
      }
      throw err;
    }
  })();
  ensureNovaAgentDatabasePermissions(pathname, databaseOptions);
  const database = { agentId, db, path: pathname, walMaintenance };
  if (!isValidatedReopen) {
    try {
      registerNovaAgentDatabase({ agentId, path: pathname, env: options.env });
    } catch (error) {
      closeCachedNovaAgentDatabase(database);
      throw error;
    }
    validatedAgentDatabasePaths.set(pathname, agentId);
  }
  cachedDatabases.set(pathname, database);
  terminalOpenLatch.clear(pathname);
  // Safety net for processes that end without an orderly close: agent DBs have
  // no shutdown owner like the ACP/gateway state DB closes. Closing unregisters.
  unregisterExitClose ??= registerSqliteCacheExitClose(closeNovaAgentDatabases);
  logSlowAgentDatabaseOpen({
    agentId,
    elapsedMs: Date.now() - openStartedAt,
    path: pathname,
  });
  return database;
}

/** Run a synchronous immediate transaction against an agent database. */
const postCommitPublications = new WeakMap<NovaAgentDatabase, Array<() => void>>();

/** Queue a non-throwing runtime publication on the outer database commit edge. */
export function deferNovaAgentPostCommitPublication(
  database: NovaAgentDatabase,
  publish: () => void,
): boolean {
  const publications = postCommitPublications.get(database);
  if (!publications) {
    return false;
  }
  publications.push(publish);
  return true;
}

export function runNovaAgentWriteTransaction<T>(
  operation: (database: NovaAgentDatabase) => T,
  options: NovaAgentDatabaseOptions,
  transactionOptions: Pick<
    SqliteTransactionOptions,
    "busyTimeoutMs" | "operationLabel" | "slowTransactionHoldMs"
  > = {},
): T {
  const database = openNovaAgentDatabase(options);
  const enteredNestedTransaction = database.db.isTransaction;
  const publications: Array<() => void> | undefined = enteredNestedTransaction
    ? postCommitPublications.get(database)
    : [];
  const publicationStart = publications?.length ?? 0;
  if (!enteredNestedTransaction && publications) {
    postCommitPublications.set(database, publications);
  }
  let result: T;
  try {
    result = runSqliteImmediateTransactionSync(
      database.db,
      () => {
        const operationResult = operation(database);
        if (!enteredNestedTransaction) {
          // Permission failure must roll back with the write. Repairing after
          // COMMIT could make callers retry a transaction already durable in SQLite.
          ensureNovaAgentDatabasePermissions(database.path, options);
        }
        return operationResult;
      },
      {
        busyTimeoutMs: transactionOptions.busyTimeoutMs ?? NOVA_SQLITE_BUSY_TIMEOUT_MS,
        databaseLabel: database.path,
        ...transactionOptions,
        operationLabel: transactionOptions.operationLabel ?? "agent.write",
      },
    );
  } catch (error) {
    publications?.splice(publicationStart);
    throw error;
  } finally {
    if (!enteredNestedTransaction && publications) {
      postCommitPublications.delete(database);
    }
  }
  if (!enteredNestedTransaction) {
    for (const publish of publications ?? []) {
      publish();
    }
  }
  return result;
}

let unregisterExitClose: (() => void) | null = null;

function closeCachedNovaAgentDatabase(
  database: NovaAgentDatabase,
  options: { eviction?: boolean } = {},
): void {
  // Eviction must stay cheap: PASSIVE skips waiting on concurrent readers,
  // whose drained TRUNCATE checkpoints blocked the event loop for seconds.
  database.walMaintenance.close(options.eviction ? { checkpointMode: "PASSIVE" } : undefined);
  clearNodeSqliteKyselyCacheForDatabase(database.db);
  if (database.db.isOpen) {
    database.db.close();
  }
}

function evictLruAgentDatabaseHandles(): void {
  // Callers re-fetch handles from this cache at each operation entry and use
  // them within one synchronous section, so eviction can never close a handle
  // mid-use; a handle retained across an eviction-triggering open goes stale.
  while (cachedDatabases.size >= NOVA_AGENT_DB_OPEN_HANDLE_CAP) {
    let evicted = false;
    for (const [pathname, database] of cachedDatabases) {
      // A synchronous transaction owns its handle through COMMIT or ROLLBACK;
      // closing it here would violate the transaction commit-section contract.
      if (database.db.isTransaction) {
        continue;
      }
      // Registry rows are durable discovery metadata; only explicit disposal
      // unregisters them, while eviction closes this process-local handle.
      closeCachedNovaAgentDatabase(database, { eviction: true });
      cachedDatabases.delete(pathname);
      agentDbLog.debug("evicted Nova agent database handle", {
        agentId: database.agentId,
        openHandles: cachedDatabases.size,
        path: pathname,
      });
      evicted = true;
      break;
    }
    if (!evicted) {
      // Every handle is mid-transaction: sync commit sections bound concurrent
      // transactions at call-nesting depth, so this stays a pathological safety
      // valve; exceeding the cap beats failing an unrelated agent's open.
      agentDbLog.warn(
        "agent database handle cap exceeded; all cached handles are in transactions",
        {
          cap: NOVA_AGENT_DB_OPEN_HANDLE_CAP,
          openHandles: cachedDatabases.size,
        },
      );
      return;
    }
  }
}

/** Return whether the exact cached agent database pathname is still open. */
export function isNovaAgentDatabaseOpen(pathname: string): boolean {
  const database = cachedDatabases.get(path.resolve(pathname));
  return database?.db.isOpen === true;
}

/** Close one cached agent database identified by its exact resolved pathname. */
export function closeNovaAgentDatabaseByPath(pathname: string): boolean {
  // Cache keys are lexical resolved paths. Do not realpath aliases here: a
  // symlink swap must never redirect cleanup onto a different cached database.
  const resolvedPath = path.resolve(pathname);
  const database = cachedDatabases.get(resolvedPath);
  if (!database) {
    return false;
  }
  closeCachedNovaAgentDatabase(database);
  cachedDatabases.delete(resolvedPath);
  if (cachedDatabases.size === 0) {
    unregisterExitClose?.();
    unregisterExitClose = null;
  }
  return true;
}

/** Close and unregister one transient agent database by exact cached pathname. */
export function disposeNovaAgentDatabaseByPath(
  pathname: string,
  options: { env?: NodeJS.ProcessEnv } = {},
): boolean {
  // Require the cache's exact lexical owner. Following a symlink or accepting
  // an uncached path could unregister a database another process now owns.
  const resolvedPath = path.resolve(pathname);
  // Disposal can be followed by file deletion or recreation, so revalidate next open.
  validatedAgentDatabasePaths.delete(resolvedPath);
  const database = cachedDatabases.get(resolvedPath);
  if (!database || database.path !== resolvedPath) {
    return false;
  }
  try {
    unregisterNovaAgentDatabase({
      agentId: database.agentId,
      path: resolvedPath,
      ...(options.env ? { env: options.env } : {}),
    });
  } finally {
    // Secret-bearing transient DBs must close even when registry maintenance
    // fails; Windows otherwise cannot remove the file during caller cleanup.
    closeNovaAgentDatabaseByPath(resolvedPath);
  }
  return true;
}

/** Close all cached agent database handles. */
export function closeNovaAgentDatabases(): void {
  unregisterExitClose?.();
  unregisterExitClose = null;
  for (const database of cachedDatabases.values()) {
    closeCachedNovaAgentDatabase(database);
  }
  cachedDatabases.clear();
}

/** Close cached agent handles and clear terminal failure latches for test isolation. */
export function closeNovaAgentDatabasesForTest(): void {
  closeNovaAgentDatabases();
  validatedAgentDatabasePaths.clear();
  terminalOpenLatch.clearAll();
}
