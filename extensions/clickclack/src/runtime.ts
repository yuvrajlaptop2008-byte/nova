/**
 * Runtime store for host-provided Nova services used by the ClickClack
 * bundled plugin.
 */
import { createPluginRuntimeStore } from "nova/plugin-sdk/runtime-store";
import type { PluginRuntime } from "nova/plugin-sdk/runtime-store";

const { setRuntime: setClickClackRuntime, getRuntime: getClickClackRuntime } =
  createPluginRuntimeStore<PluginRuntime>({
    pluginId: "clickclack",
    errorMessage: "ClickClack runtime not initialized",
  });

export { getClickClackRuntime, setClickClackRuntime };
