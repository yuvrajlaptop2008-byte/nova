// Tavily helper module supports tavily tool config behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import type { NovaPluginToolContext } from "nova/plugin-sdk/plugin-entry";
import type { NovaPluginApi } from "nova/plugin-sdk/plugin-runtime";

export type TavilyToolConfigContext = Pick<
  NovaPluginToolContext,
  "config" | "runtimeConfig" | "getRuntimeConfig"
>;

export function resolveTavilyToolConfig(
  api: NovaPluginApi,
  ctx?: TavilyToolConfigContext,
): NovaConfig {
  return ctx?.getRuntimeConfig?.() ?? ctx?.runtimeConfig ?? ctx?.config ?? api.config;
}
