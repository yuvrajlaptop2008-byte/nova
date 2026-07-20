// Qqbot API module exposes the plugin public contract.
export type { ChannelPlugin, NovaPluginApi, PluginRuntime } from "nova/plugin-sdk/core";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export type {
  NovaPluginService,
  NovaPluginServiceContext,
  PluginLogger,
} from "nova/plugin-sdk/core";
export type { ResolvedQQBotAccount, QQBotAccountConfig } from "./src/types.js";
export { getQQBotRuntime, setQQBotRuntime } from "./src/bridge/runtime.js";
