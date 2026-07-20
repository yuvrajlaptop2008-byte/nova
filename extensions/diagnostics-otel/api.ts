// Diagnostics Otel API module exposes the plugin public contract.
export {
  createChildDiagnosticTraceContext,
  createDiagnosticTraceContext,
  emitDiagnosticEvent,
  formatDiagnosticTraceparent,
  isValidDiagnosticSpanId,
  isValidDiagnosticTraceFlags,
  isValidDiagnosticTraceId,
  onDiagnosticEvent,
  parseDiagnosticTraceparent,
  type DiagnosticEventMetadata,
  type DiagnosticEventPayload,
  type DiagnosticEventPrivateData,
  type DiagnosticTraceContext,
} from "nova/plugin-sdk/diagnostic-runtime";
export { emptyPluginConfigSchema, type NovaPluginApi } from "nova/plugin-sdk/plugin-entry";
export type { NovaPluginService, NovaPluginServiceContext } from "nova/plugin-sdk/plugin-entry";
export { redactSensitiveText } from "nova/plugin-sdk/security-runtime";
