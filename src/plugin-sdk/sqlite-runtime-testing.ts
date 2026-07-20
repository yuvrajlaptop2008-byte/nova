// Private local-only SQLite lifecycle helpers for first-party tests.

import {
  appendTranscriptEvent,
  type SessionTranscriptAccessScope,
  type TranscriptEvent,
} from "../config/sessions/session-accessor.js";

export type SqliteSessionTranscriptEventForTest = TranscriptEvent;

/** Appends a raw SQLite transcript event for first-party tests only. */
export async function appendSqliteSessionTranscriptEventForTest(
  params: SessionTranscriptAccessScope & { event: TranscriptEvent },
): Promise<void> {
  await appendTranscriptEvent(params, params.event);
}

export { formatSqliteSessionFileMarker } from "../config/sessions/sqlite-marker.js";
export {
  appendSqliteTrajectoryRuntimeEvents,
  loadSqliteTrajectoryRuntimeEvents,
  type SqliteTrajectoryRuntimeScope,
} from "../trajectory/runtime-store.sqlite.js";
export { type TrajectoryEvent as SqliteTrajectoryRuntimeEventForTest } from "../trajectory/types.js";
export { closeNovaAgentDatabasesForTest, openNovaAgentDatabase } from "../state/nova-agent-db.js";
export { closeNovaStateDatabaseForTest, openNovaStateDatabase } from "../state/nova-state-db.js";
