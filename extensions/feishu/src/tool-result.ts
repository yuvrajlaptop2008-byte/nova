// Feishu plugin module implements tool result behavior.
import { formatErrorMessage } from "nova/plugin-sdk/error-runtime";
import { jsonResult } from "nova/plugin-sdk/tool-results";

export function unknownToolActionResult(action: unknown) {
  return jsonResult({ error: `Unknown action: ${String(action)}` });
}

export function toolExecutionErrorResult(error: unknown) {
  return jsonResult({ error: formatErrorMessage(error) });
}
