// Diffs API module exposes the plugin public contract.
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export {
  definePluginEntry,
  type AnyAgentTool,
  type NovaPluginApi,
  type NovaPluginConfigSchema,
  type NovaPluginToolContext,
  type PluginLogger,
} from "nova/plugin-sdk/plugin-entry";
export { resolvePreferredNovaTmpDir } from "nova/plugin-sdk/temp-path";
