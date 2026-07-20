import { parentPort, workerData } from "node:worker_threads";
import { requireNodeSqlite } from "../infra/node-sqlite.js";
import {
  assertSqliteIntegrity,
  isTerminalSqliteIntegrityError,
} from "../infra/sqlite-integrity.js";
import { NOVA_SQLITE_BUSY_TIMEOUT_MS } from "./nova-state-db.js";

export type NovaDatabaseVerifyTarget = {
  path: string;
  kind: "agent" | "state";
  label: string;
};

export type NovaDatabaseVerifyResult = {
  path: string;
  ok: boolean;
  error?: string;
  terminal?: boolean;
};

function isVerifyTarget(value: unknown): value is NovaDatabaseVerifyTarget {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const target = value as Record<string, unknown>;
  return (
    typeof target.path === "string" &&
    (target.kind === "agent" || target.kind === "state") &&
    typeof target.label === "string"
  );
}

/** Verify database files serially so large agent scans never compete for I/O. */
export function verifyNovaDatabases(
  targets: readonly NovaDatabaseVerifyTarget[],
): NovaDatabaseVerifyResult[] {
  const sqlite = requireNodeSqlite();
  return targets.map((target) => {
    let database: InstanceType<typeof sqlite.DatabaseSync> | undefined;
    try {
      database = new sqlite.DatabaseSync(target.path, { readOnly: true });
      database.exec(`PRAGMA busy_timeout = ${NOVA_SQLITE_BUSY_TIMEOUT_MS};`);
      assertSqliteIntegrity(database, target.label);
      return { path: target.path, ok: true };
    } catch (error) {
      const detail = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
      const terminal = error instanceof Error && isTerminalSqliteIntegrityError(error);
      return { path: target.path, ok: false, error: detail, terminal };
    } finally {
      database?.close();
    }
  });
}

if (parentPort) {
  const targets = Array.isArray(workerData) ? workerData.filter(isVerifyTarget) : [];
  parentPort.postMessage(verifyNovaDatabases(targets), []);
}
