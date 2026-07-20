// Diagnostics Prometheus API module exposes the plugin public contract.
export type {
  DiagnosticEventMetadata,
  DiagnosticEventPayload,
} from "nova/plugin-sdk/diagnostic-runtime";
export { isInternalDiagnosticEventMetadata } from "nova/plugin-sdk/diagnostic-runtime";
export {
  emptyPluginConfigSchema,
  type NovaPluginApi,
  type NovaPluginHttpRouteHandler,
  type NovaPluginService,
  type NovaPluginServiceContext,
} from "nova/plugin-sdk/plugin-entry";
export { redactSensitiveText } from "nova/plugin-sdk/security-runtime";
