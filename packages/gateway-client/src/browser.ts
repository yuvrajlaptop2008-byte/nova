// Browser-safe gateway client surface. Keep Node transport/TLS dependencies out
// of this entry so browser consumers share the wire engine without polyfills.
export * from "./device-auth.js";
export * from "./browser-device-auth.js";
export * from "./connect-auth.js";
export * from "./protocol-client.js";
export * from "./reconnect-policy.js";
export { DEFAULT_PREAUTH_HANDSHAKE_TIMEOUT_MS } from "./timeouts.js";
export * from "@nova/gateway-protocol/client-info";
export * from "@nova/gateway-protocol/connect-error-details";
export * from "@nova/gateway-protocol/gateway-error-details";
export * from "@nova/gateway-protocol/startup-unavailable";
export * from "@nova/gateway-protocol/version";
export type { ConnectParams, ErrorShape, EventFrame, HelloOk } from "@nova/gateway-protocol";
