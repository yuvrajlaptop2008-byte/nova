// Gateway reload settings resolver.
// Normalizes reload mode and debounce config for watcher/reload handlers.
import type { GatewayReloadMode } from "../config/types.gateway.js";
import type { NovaConfig } from "../config/types.nova.js";

type GatewayReloadSettings = {
  mode: GatewayReloadMode;
  debounceMs: number;
};

const DEFAULT_RELOAD_SETTINGS: GatewayReloadSettings = {
  mode: "hybrid",
  debounceMs: 300,
};

/** Resolves gateway reload mode/debounce from config with bounded defaults. */
export function resolveGatewayReloadSettings(cfg: NovaConfig): GatewayReloadSettings {
  const rawMode = cfg.gateway?.reload?.mode;
  const mode =
    rawMode === "off" || rawMode === "restart" || rawMode === "hot" || rawMode === "hybrid"
      ? rawMode
      : DEFAULT_RELOAD_SETTINGS.mode;
  return { mode, debounceMs: DEFAULT_RELOAD_SETTINGS.debounceMs };
}
