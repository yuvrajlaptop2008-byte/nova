// Duckduckgo helper module supports config behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { normalizeLowercaseStringOrEmpty } from "nova/plugin-sdk/string-coerce-runtime";

const DEFAULT_DDG_SAFE_SEARCH = "moderate";

export type DdgSafeSearch = "strict" | "moderate" | "off";

type DdgPluginConfig = {
  webSearch?: {
    region?: string;
    safeSearch?: string;
  };
};

function resolveDdgWebSearchConfig(config?: NovaConfig): DdgPluginConfig["webSearch"] | undefined {
  const pluginConfig = config?.plugins?.entries?.duckduckgo?.config as DdgPluginConfig | undefined;
  const webSearch = pluginConfig?.webSearch;
  if (webSearch && typeof webSearch === "object" && !Array.isArray(webSearch)) {
    return webSearch;
  }
  return undefined;
}

export function resolveDdgRegion(config?: NovaConfig): string | undefined {
  const region = resolveDdgWebSearchConfig(config)?.region;
  if (typeof region !== "string") {
    return undefined;
  }
  const trimmed = region.trim();
  return trimmed || undefined;
}

export function resolveDdgSafeSearch(config?: NovaConfig): DdgSafeSearch {
  const safeSearch = resolveDdgWebSearchConfig(config)?.safeSearch;
  const normalized = normalizeLowercaseStringOrEmpty(safeSearch);
  if (normalized === "strict" || normalized === "off") {
    return normalized;
  }
  return DEFAULT_DDG_SAFE_SEARCH;
}
