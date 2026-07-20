// Lobster API module exposes the plugin public contract.
export { definePluginEntry } from "nova/plugin-sdk/core";
export type {
  AnyAgentTool,
  NovaPluginApi,
  NovaPluginToolContext,
  NovaPluginToolFactory,
} from "nova/plugin-sdk/core";
export {
  applyWindowsSpawnProgramPolicy,
  materializeWindowsSpawnProgram,
  resolveWindowsSpawnProgramCandidate,
} from "nova/plugin-sdk/windows-spawn";
