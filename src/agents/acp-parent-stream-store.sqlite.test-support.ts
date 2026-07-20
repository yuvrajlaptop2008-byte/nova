import { executeSqliteQuerySync, getNodeSqliteKysely } from "../infra/kysely-sync.js";
import type { DB as NovaAgentKyselyDatabase } from "../state/nova-agent-db.generated.js";
import { openNovaAgentDatabase, type NovaAgentDatabaseOptions } from "../state/nova-agent-db.js";
import type { AcpParentStreamEvent } from "./acp-parent-stream-store.sqlite.js";

type AcpParentStreamDatabase = Pick<NovaAgentKyselyDatabase, "acp_parent_stream_events">;

export function listAcpParentStreamEventsForTest(
  options: NovaAgentDatabaseOptions & { sessionId: string; runId: string },
): AcpParentStreamEvent[] {
  const database = openNovaAgentDatabase(options);
  const db = getNodeSqliteKysely<AcpParentStreamDatabase>(database.db);
  return executeSqliteQuerySync(
    database.db,
    db
      .selectFrom("acp_parent_stream_events")
      .select("event_json")
      .where("session_id", "=", options.sessionId)
      .where("run_id", "=", options.runId)
      .orderBy("seq", "asc"),
  ).rows.map((row) => JSON.parse(row.event_json) as AcpParentStreamEvent);
}
