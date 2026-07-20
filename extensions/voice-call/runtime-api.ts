// Private runtime barrel for the bundled Voice Call extension.
// Keep this barrel thin and aligned with the local extension surface.

export { definePluginEntry } from "nova/plugin-sdk/plugin-entry";
export type { NovaPluginApi } from "nova/plugin-sdk/plugin-entry";
export type { GatewayRequestHandlerOptions } from "nova/plugin-sdk/gateway-runtime";
export {
  isRequestBodyLimitError,
  readRequestBodyWithLimit,
  requestBodyErrorToText,
} from "nova/plugin-sdk/webhook-request-guards";
export { fetchWithSsrFGuard, isBlockedHostnameOrIp } from "nova/plugin-sdk/ssrf-runtime";
export type { SessionEntry } from "nova/plugin-sdk/session-store-runtime";
export {
  TtsAutoSchema,
  TtsConfigSchema,
  TtsModeSchema,
  TtsProviderSchema,
} from "nova/plugin-sdk/tts-runtime";
export { sleep } from "nova/plugin-sdk/runtime-env";
