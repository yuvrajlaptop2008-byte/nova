/** Resolves whether the metadata-only audit ledger records new events. */
import type { NovaConfig } from "../config/types.nova.js";

export type AuditMessageMode = "off" | "direct" | "all";

/**
 * The ledger is on by default: an audit trail enabled only after an incident
 * cannot explain the incident. `audit.enabled: false` stops new event inserts after
 * restart; audit queries still serve retained rows until they expire.
 */
export function isAuditLedgerEnabled(cfg: NovaConfig | undefined): boolean {
  return cfg?.audit?.enabled !== false;
}

/** Message metadata remains an explicit opt-in inside the default-on ledger. */
export function resolveAuditMessageMode(cfg: NovaConfig | undefined): AuditMessageMode {
  return cfg?.audit?.messages ?? "off";
}
