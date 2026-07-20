// Host-owned SQLite leases serialize trusted work across processes.
import { randomUUID } from "node:crypto";
import type { DatabaseSync } from "node:sqlite";
import { computeBackoff, sleepWithAbort } from "../infra/backoff.js";
import {
  executeSqliteQuerySync,
  executeSqliteQueryTakeFirstSync,
  getNodeSqliteKysely,
} from "../infra/kysely-sync.js";
import { isSqliteLockError } from "../infra/sqlite-transaction.js";
import { MAX_TIMER_TIMEOUT_MS } from "../shared/number-coercion.js";
import type { DB as NovaAgentKyselyDatabase } from "./nova-agent-db.generated.js";
import { openNovaAgentDatabase, runNovaAgentWriteTransaction } from "./nova-agent-db.js";
import type { DB as NovaStateKyselyDatabase } from "./nova-state-db.generated.js";
import {
  openNovaStateDatabase,
  runNovaStateWriteTransaction,
  type NovaStateDatabaseOptions,
} from "./nova-state-db.js";

type LeaseDatabase = Pick<NovaStateKyselyDatabase, "state_leases">;
type AgentLeaseDatabase = Pick<NovaAgentKyselyDatabase, "state_leases">;
type LeaseKysely = ReturnType<typeof getNodeSqliteKysely<LeaseDatabase>>;

type NovaStateLeaseDatabase =
  | { scope: "shared"; options?: NovaStateDatabaseOptions }
  | { scope: "agent"; agentId: string };

type NovaStateLeaseOptions = {
  scope: string;
  key: string;
  database: NovaStateLeaseDatabase;
  leaseMs: number;
  waitMs: number;
  signal?: AbortSignal;
  /** Stable diagnostic noun used in errors. */
  leaseLabel?: string;
  /** Stable transaction label used by SQLite diagnostics. */
  operationLabel?: string;
};

export type NovaStateLeaseContext = {
  signal: AbortSignal;
  /** Verify that this exact owner holds a non-expired lease at this instant. */
  assertOwned(): void;
  /** Verify ownership using the caller's active write transaction. */
  assertOwnedInTransaction(database: DatabaseSync): void;
};

export type NovaStateLeaseErrorCode =
  | "NOVA_STATE_LEASE_INVALID_INPUT"
  | "NOVA_STATE_LEASE_TIMEOUT"
  | "NOVA_STATE_LEASE_ABORTED"
  | "NOVA_STATE_LEASE_LOST"
  | "NOVA_STATE_LEASE_STORAGE_FAILED";

export class NovaStateLeaseError extends Error {
  readonly code: NovaStateLeaseErrorCode;

  constructor(message: string, options: { code: NovaStateLeaseErrorCode; cause?: unknown }) {
    super(message, { cause: options.cause });
    this.name = "NovaStateLeaseError";
    this.code = options.code;
  }
}

const ACQUIRE_BACKOFF = {
  initialMs: 25,
  maxMs: 250,
  factor: 1.5,
  jitter: 0.25,
} as const;
const MIN_LEASE_MS = 1_000;
const LEASE_DB_BUSY_TIMEOUT_MS = 0;
const RELEASE_RETRY_TIMEOUT_MS = 2_000;

function leaseError(
  code: NovaStateLeaseErrorCode,
  message: string,
  cause?: unknown,
): NovaStateLeaseError {
  return new NovaStateLeaseError(message, {
    code,
    ...(cause === undefined ? {} : { cause }),
  });
}

function invalidInput(message: string): NovaStateLeaseError {
  return leaseError("NOVA_STATE_LEASE_INVALID_INPUT", message);
}

function validateDuration(value: number, label: string, minimum: number, maximum: number): number {
  if (!Number.isInteger(value) || value < minimum || value > maximum) {
    throw invalidInput(`${label} must be an integer between ${minimum} and ${maximum}`);
  }
  return value;
}

function validateNonEmptyString(value: unknown, label: string): string {
  if (typeof value !== "string" || !value.trim() || value.includes("\0")) {
    throw invalidInput(`${label} must be a non-empty string without NUL bytes`);
  }
  return value;
}

function validateOptions(options: NovaStateLeaseOptions) {
  if (typeof options !== "object" || options === null || Array.isArray(options)) {
    throw invalidInput("state lease options must be an object");
  }
  if (options.signal !== undefined && !(options.signal instanceof AbortSignal)) {
    throw invalidInput("state lease signal must be an AbortSignal");
  }
  const database = options.database;
  if (typeof database !== "object" || database === null || Array.isArray(database)) {
    throw invalidInput("state lease database must be an object");
  }
  if (database.scope !== "shared" && database.scope !== "agent") {
    throw invalidInput("state lease database scope must be shared or agent");
  }
  if (database.scope === "agent") {
    validateNonEmptyString(database.agentId, "state lease agent database agentId");
  }
  const leaseLabel =
    options.leaseLabel === undefined
      ? "state lease"
      : validateNonEmptyString(options.leaseLabel, "state lease label");
  const operationLabel =
    options.operationLabel === undefined
      ? "state.lease"
      : validateNonEmptyString(options.operationLabel, "state lease operationLabel");
  return {
    scope: validateNonEmptyString(options.scope, `${leaseLabel} scope`),
    key: validateNonEmptyString(options.key, `${leaseLabel} key`),
    database,
    leaseMs: validateDuration(
      options.leaseMs,
      `${leaseLabel} leaseMs`,
      MIN_LEASE_MS,
      MAX_TIMER_TIMEOUT_MS,
    ),
    waitMs: validateDuration(options.waitMs, `${leaseLabel} waitMs`, 0, MAX_TIMER_TIMEOUT_MS),
    signal: options.signal,
    leaseLabel,
    operationLabel,
  };
}

function readBusyTimeout(database: DatabaseSync): number {
  const row = database // sqlite-allow-raw -- Narrow connection primitive for bounded lease admission.
    .prepare("PRAGMA busy_timeout")
    .get() as { busy_timeout?: unknown; timeout?: unknown } | undefined;
  const value = row?.busy_timeout ?? row?.timeout;
  return typeof value === "bigint" ? Number(value) : Number(value ?? 0);
}

function withBusyTimeout<T>(database: DatabaseSync, busyTimeoutMs: number, run: () => T): T {
  const previousBusyTimeoutMs = readBusyTimeout(database);
  if (previousBusyTimeoutMs === busyTimeoutMs) {
    return run();
  }
  database.exec(`PRAGMA busy_timeout = ${busyTimeoutMs}`); // sqlite-allow-raw -- Bound synchronous lease admission to waitMs.
  try {
    return run();
  } finally {
    if (database.isOpen) {
      database.exec(`PRAGMA busy_timeout = ${previousBusyTimeoutMs}`); // sqlite-allow-raw -- Restore canonical connection policy.
    }
  }
}

function withLeaseWriteTransaction<T>(
  database: NovaStateLeaseDatabase,
  operationLabel: string,
  operation: (db: DatabaseSync, kysely: LeaseKysely) => T,
  busyTimeoutMs = LEASE_DB_BUSY_TIMEOUT_MS,
): T {
  if (database.scope === "shared") {
    const stateDatabase = openNovaStateDatabase(database.options);
    const run = () =>
      runNovaStateWriteTransaction(
        ({ db }) => operation(db, getNodeSqliteKysely<LeaseDatabase>(db)),
        database.options,
        { operationLabel, busyTimeoutMs },
      );
    return withBusyTimeout(stateDatabase.db, busyTimeoutMs, run);
  }
  const agentDatabase = openNovaAgentDatabase({ agentId: database.agentId });
  const run = () =>
    runNovaAgentWriteTransaction(
      ({ db }) => operation(db, getNodeSqliteKysely<AgentLeaseDatabase>(db)),
      { agentId: database.agentId },
      { operationLabel, busyTimeoutMs },
    );
  return withBusyTimeout(agentDatabase.db, busyTimeoutMs, run);
}

function withLeaseRead<T>(
  database: NovaStateLeaseDatabase,
  operation: (db: DatabaseSync, kysely: LeaseKysely) => T,
): T {
  const sqlite =
    database.scope === "shared"
      ? openNovaStateDatabase(database.options).db
      : openNovaAgentDatabase({ agentId: database.agentId }).db;
  return operation(sqlite, getNodeSqliteKysely<LeaseDatabase>(sqlite));
}

type LeaseIdentity = {
  scope: string;
  key: string;
  owner: string;
  leaseLabel: string;
};

function tryAcquire(
  params: LeaseIdentity & {
    database: NovaStateLeaseDatabase;
    operationLabel: string;
    leaseMs: number;
  },
): number | undefined {
  return withLeaseWriteTransaction(params.database, params.operationLabel, (db, kysely) => {
    // BEGIN IMMEDIATE may wait on SQLite. Sample only after admission so a
    // successful insert never commits an already-expired lease.
    const now = Date.now();
    executeSqliteQuerySync(
      db,
      kysely
        .deleteFrom("state_leases")
        .where("scope", "=", params.scope)
        .where("lease_key", "=", params.key)
        .where("expires_at", "<=", now),
    );
    const expiresAt = now + params.leaseMs;
    const inserted = executeSqliteQuerySync(
      db,
      kysely
        .insertInto("state_leases")
        .values({
          scope: params.scope,
          lease_key: params.key,
          owner: params.owner,
          expires_at: expiresAt,
          heartbeat_at: now,
          payload_json: null,
          created_at: now,
          updated_at: now,
        })
        .onConflict((conflict) => conflict.columns(["scope", "lease_key"]).doNothing()),
    );
    return inserted.numAffectedRows === 1n ? expiresAt : undefined;
  });
}

function renew(
  params: LeaseIdentity & {
    database: NovaStateLeaseDatabase;
    operationLabel: string;
    leaseMs: number;
  },
): number {
  return withLeaseWriteTransaction(params.database, params.operationLabel, (db, kysely) => {
    const now = Date.now();
    const expiresAt = now + params.leaseMs;
    const updated = executeSqliteQuerySync(
      db,
      kysely
        .updateTable("state_leases")
        .set({
          expires_at: expiresAt,
          heartbeat_at: now,
          updated_at: now,
        })
        .where("scope", "=", params.scope)
        .where("lease_key", "=", params.key)
        .where("owner", "=", params.owner)
        .where("expires_at", ">", now),
    );
    if (updated.numAffectedRows !== 1n) {
      throw leaseError(
        "NOVA_STATE_LEASE_LOST",
        `${params.leaseLabel} ${params.scope}/${params.key} was lost`,
      );
    }
    return expiresAt;
  });
}

function assertLeaseOwnedInDatabase(
  database: DatabaseSync,
  kysely: LeaseKysely,
  params: LeaseIdentity,
): void {
  const now = Date.now();
  const row = executeSqliteQueryTakeFirstSync(
    database,
    kysely
      .selectFrom("state_leases")
      .select("owner")
      .where("scope", "=", params.scope)
      .where("lease_key", "=", params.key)
      .where("owner", "=", params.owner)
      .where("expires_at", ">", now),
  );
  if (!row) {
    throw leaseError(
      "NOVA_STATE_LEASE_LOST",
      `${params.leaseLabel} ${params.scope}/${params.key} was lost`,
    );
  }
}

function verifyLeaseOwnership(
  params: LeaseIdentity & { database?: NovaStateLeaseDatabase; transaction?: DatabaseSync },
): void {
  try {
    if (params.transaction) {
      assertLeaseOwnedInDatabase(
        params.transaction,
        getNodeSqliteKysely<LeaseDatabase>(params.transaction),
        params,
      );
      return;
    }
    if (!params.database) {
      throw new Error("state lease ownership check requires a database");
    }
    withLeaseRead(params.database, (db, kysely) => assertLeaseOwnedInDatabase(db, kysely, params));
  } catch (error) {
    if (error instanceof NovaStateLeaseError) {
      throw error;
    }
    throw leaseError(
      "NOVA_STATE_LEASE_STORAGE_FAILED",
      `failed to verify ${params.leaseLabel} ${params.scope}/${params.key}`,
      error,
    );
  }
}

function release(
  params: LeaseIdentity & {
    database: NovaStateLeaseDatabase;
    operationLabel: string;
  },
): void {
  withLeaseWriteTransaction(params.database, params.operationLabel, (db, kysely) => {
    executeSqliteQuerySync(
      db,
      kysely
        .deleteFrom("state_leases")
        .where("scope", "=", params.scope)
        .where("lease_key", "=", params.key)
        .where("owner", "=", params.owner),
    );
  });
}

async function releaseBestEffort(params: Parameters<typeof release>[0]): Promise<void> {
  const deadline = performance.now() + RELEASE_RETRY_TIMEOUT_MS;
  let attempt = 0;
  while (true) {
    try {
      release(params);
      return;
    } catch (error) {
      if (!isSqliteLockError(error)) {
        return;
      }
      const now = performance.now();
      if (now >= deadline) {
        return;
      }
      attempt += 1;
      // Lease transactions never block the event loop. Cleanup instead gives
      // ordinary cross-process writers a bounded async window to finish.
      await sleepWithAbort(Math.min(deadline - now, computeBackoff(ACQUIRE_BACKOFF, attempt)));
    }
  }
}

function abortError(signal: AbortSignal, label: string, leaseLabel: string): NovaStateLeaseError {
  return leaseError(
    "NOVA_STATE_LEASE_ABORTED",
    `${leaseLabel} ${label} was aborted`,
    signal.reason,
  );
}

/** Run one trusted operation under a host-owned SQLite lease. */
export async function withNovaStateLease<T>(
  options: NovaStateLeaseOptions,
  run: (lease: NovaStateLeaseContext) => Promise<T>,
): Promise<T> {
  const validated = validateOptions(options);
  if (validated.signal?.aborted) {
    throw abortError(validated.signal, "acquisition", validated.leaseLabel);
  }
  const owner = randomUUID();
  // Acquisition budgets are elapsed-time contracts. Wall-clock changes still
  // affect persisted expiry timestamps, but must not lengthen or shorten waits.
  const deadline = performance.now() + validated.waitMs;
  let attempt = 0;
  let confirmedExpiresAt: number | undefined;
  while (confirmedExpiresAt === undefined) {
    if (validated.signal?.aborted) {
      throw abortError(validated.signal, "acquisition", validated.leaseLabel);
    }
    try {
      confirmedExpiresAt = tryAcquire({
        database: validated.database,
        operationLabel: validated.operationLabel,
        scope: validated.scope,
        key: validated.key,
        owner,
        leaseMs: validated.leaseMs,
        leaseLabel: validated.leaseLabel,
      });
    } catch (error) {
      if (error instanceof NovaStateLeaseError) {
        throw error;
      }
      if (!isSqliteLockError(error)) {
        throw leaseError(
          "NOVA_STATE_LEASE_STORAGE_FAILED",
          `failed to acquire ${validated.leaseLabel} ${validated.scope}/${validated.key}`,
          error,
        );
      }
    }
    const now = performance.now();
    if (confirmedExpiresAt !== undefined) {
      if (validated.signal?.aborted || (validated.waitMs > 0 && now >= deadline)) {
        await releaseBestEffort({
          database: validated.database,
          operationLabel: validated.operationLabel,
          scope: validated.scope,
          key: validated.key,
          owner,
          leaseLabel: validated.leaseLabel,
        });
        if (validated.signal?.aborted) {
          throw abortError(validated.signal, "acquisition", validated.leaseLabel);
        }
        throw leaseError(
          "NOVA_STATE_LEASE_TIMEOUT",
          `timed out waiting for ${validated.leaseLabel} ${validated.scope}/${validated.key}`,
        );
      }
      break;
    }
    if (now >= deadline) {
      throw leaseError(
        "NOVA_STATE_LEASE_TIMEOUT",
        `timed out waiting for ${validated.leaseLabel} ${validated.scope}/${validated.key}`,
      );
    }
    attempt += 1;
    const delayMs = Math.min(deadline - now, computeBackoff(ACQUIRE_BACKOFF, attempt));
    try {
      await sleepWithAbort(delayMs, validated.signal);
    } catch (error) {
      if (validated.signal?.aborted) {
        throw abortError(validated.signal, "acquisition", validated.leaseLabel);
      }
      throw error;
    }
  }

  const identity: LeaseIdentity = {
    scope: validated.scope,
    key: validated.key,
    owner,
    leaseLabel: validated.leaseLabel,
  };
  const leaseLost = new AbortController();
  const operationSignal = validated.signal
    ? AbortSignal.any([validated.signal, leaseLost.signal])
    : leaseLost.signal;
  const heartbeatMs = Math.max(250, Math.min(30_000, Math.floor(validated.leaseMs / 3)));
  let expiryTimer: ReturnType<typeof setTimeout> | undefined;
  const abortLost = (cause?: unknown) => {
    if (!leaseLost.signal.aborted) {
      leaseLost.abort(
        cause instanceof NovaStateLeaseError
          ? cause
          : leaseError(
              "NOVA_STATE_LEASE_LOST",
              `${validated.leaseLabel} ${validated.scope}/${validated.key} expired`,
              cause,
            ),
      );
    }
  };
  const scheduleExpiry = () => {
    if (expiryTimer) {
      clearTimeout(expiryTimer);
    }
    expiryTimer = setTimeout(
      () => abortLost(),
      Math.max(1, (confirmedExpiresAt ?? Date.now()) - Date.now()),
    );
    expiryTimer.unref?.();
  };
  scheduleExpiry();
  const heartbeat = setInterval(() => {
    try {
      confirmedExpiresAt = renew({
        ...identity,
        database: validated.database,
        operationLabel: validated.operationLabel,
        leaseMs: validated.leaseMs,
      });
      scheduleExpiry();
    } catch (error) {
      if (error instanceof NovaStateLeaseError && error.code === "NOVA_STATE_LEASE_LOST") {
        abortLost(error);
      } else if (confirmedExpiresAt !== undefined && Date.now() >= confirmedExpiresAt) {
        abortLost(error);
      }
    }
  }, heartbeatMs);
  heartbeat.unref?.();

  const assertOperationOwned = () => {
    if (leaseLost.signal.aborted) {
      throw leaseLost.signal.reason;
    }
    if (validated.signal?.aborted) {
      throw abortError(validated.signal, "operation", validated.leaseLabel);
    }
    verifyLeaseOwnership({ ...identity, database: validated.database });
  };
  const assertOperationOwnedInTransaction = (database: DatabaseSync) => {
    if (leaseLost.signal.aborted) {
      throw leaseLost.signal.reason;
    }
    if (validated.signal?.aborted) {
      throw abortError(validated.signal, "operation", validated.leaseLabel);
    }
    verifyLeaseOwnership({ ...identity, transaction: database });
  };

  try {
    let result: T;
    try {
      if (validated.signal?.aborted) {
        throw abortError(validated.signal, "operation", validated.leaseLabel);
      }
      // Acquisition and callback entry are separate scheduling points. A
      // suspended process must not enter after its persisted lease expires.
      assertOperationOwned();
      result = await run({
        signal: operationSignal,
        assertOwned: assertOperationOwned,
        assertOwnedInTransaction: assertOperationOwnedInTransaction,
      });
    } catch (error) {
      if (leaseLost.signal.aborted) {
        throw leaseLost.signal.reason;
      }
      if (validated.signal?.aborted) {
        throw abortError(validated.signal, "operation", validated.leaseLabel);
      }
      throw error;
    }
    if (leaseLost.signal.aborted) {
      throw leaseLost.signal.reason;
    }
    if (validated.signal?.aborted) {
      throw abortError(validated.signal, "operation", validated.leaseLabel);
    }
    verifyLeaseOwnership({ ...identity, database: validated.database });
    return result;
  } finally {
    clearInterval(heartbeat);
    if (expiryTimer) {
      clearTimeout(expiryTimer);
    }
    await releaseBestEffort({
      ...identity,
      database: validated.database,
      operationLabel: validated.operationLabel,
    });
  }
}
