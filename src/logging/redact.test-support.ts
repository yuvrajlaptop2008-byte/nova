import type { NovaConfig } from "../config/types.nova.js";
import { fullContextToolPayloadRedactionState } from "./redact-internal-state.js";

type LoggingConfig = NovaConfig["logging"];

export function withFullContextToolPayloadRedaction(loggingConfig: LoggingConfig): LoggingConfig {
  return fullContextToolPayloadRedactionState.mark(loggingConfig);
}
