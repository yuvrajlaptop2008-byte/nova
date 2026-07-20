import { NOVA_AGENT_SCHEMA_SQL } from "./nova-agent-schema.generated.js";

const BOARD_SCHEMA_START = "CREATE TABLE IF NOT EXISTS board_tabs (";
const BOARD_SCHEMA_END = "CREATE TABLE IF NOT EXISTS heartbeat_outcomes (";

function splitBoardSchema(sql: string): { board: string; withoutBoard: string } {
  const start = sql.indexOf(BOARD_SCHEMA_START);
  const end = sql.indexOf(BOARD_SCHEMA_END, start);
  if (start === -1 || end === -1) {
    throw new Error("Nova agent board schema markers are missing from the canonical schema.");
  }
  return {
    board: sql.slice(start, end),
    withoutBoard: `${sql.slice(0, start)}${sql.slice(end)}`,
  };
}

const boardSchema = splitBoardSchema(NOVA_AGENT_SCHEMA_SQL);

export const NOVA_AGENT_BOARD_SCHEMA_SQL = boardSchema.board;
export const NOVA_AGENT_SCHEMA_WITHOUT_BOARD_SQL = boardSchema.withoutBoard;
