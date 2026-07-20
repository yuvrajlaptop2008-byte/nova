// Matrix plugin module implements monitor route test support behavior.
export { registerSessionBindingAdapter, testing } from "nova/plugin-sdk/session-binding-runtime";
export { resolveAgentRoute } from "nova/plugin-sdk/routing";
export { createTestRegistry, setActivePluginRegistry } from "nova/plugin-sdk/plugin-test-runtime";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
