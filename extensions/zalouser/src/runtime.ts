// Zalouser plugin module implements runtime behavior.
import type { PluginRuntime } from "nova/plugin-sdk/core";
import { createPluginRuntimeStore } from "nova/plugin-sdk/runtime-store";

const { setRuntime: setZalouserRuntime, getRuntime: getZalouserRuntime } =
  createPluginRuntimeStore<PluginRuntime>({
    pluginId: "zalouser",
    errorMessage: "Zalouser runtime not initialized",
  });
export { getZalouserRuntime, setZalouserRuntime };
