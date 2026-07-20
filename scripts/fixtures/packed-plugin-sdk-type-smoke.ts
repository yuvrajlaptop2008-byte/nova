// Packed Plugin Sdk Type Smoke script supports Nova repository automation.
type PublicPluginSdkModules = [
  typeof import("nova/plugin-sdk/core"),
  typeof import("nova/plugin-sdk/channel-entry-contract"),
  typeof import("nova/plugin-sdk/config-contracts"),
  typeof import("nova/plugin-sdk/plugin-entry"),
  typeof import("nova/plugin-sdk/runtime-env"),
];

const resolvedModules = null as unknown as PublicPluginSdkModules;

void resolvedModules;
