// Video provider registry stores video generation provider factories by id.
import type { NovaConfig } from "../config/types.js";
import * as capabilityProviderRuntime from "../plugins/capability-provider-runtime.js";
import {
  buildCapabilityProviderMaps,
  normalizeCapabilityProviderId,
} from "../plugins/provider-registry-shared.js";
import type { VideoGenerationProviderPlugin } from "../plugins/types.js";

// Video-generation providers come from plugin capability registration. Canonical
// ids drive listing; aliases only affect lookup.
const BUILTIN_VIDEO_GENERATION_PROVIDERS: readonly VideoGenerationProviderPlugin[] = [];
function resolvePluginVideoGenerationProviders(cfg?: NovaConfig): VideoGenerationProviderPlugin[] {
  return capabilityProviderRuntime.resolvePluginCapabilityProviders({
    key: "videoGenerationProviders",
    cfg,
  });
}

function buildProviderMaps(cfg?: NovaConfig): {
  canonical: Map<string, VideoGenerationProviderPlugin>;
  aliases: Map<string, VideoGenerationProviderPlugin>;
} {
  return buildCapabilityProviderMaps(
    [...BUILTIN_VIDEO_GENERATION_PROVIDERS, ...resolvePluginVideoGenerationProviders(cfg)],
    normalizeCapabilityProviderId,
  );
}

export function listVideoGenerationProviders(cfg?: NovaConfig): VideoGenerationProviderPlugin[] {
  return [...buildProviderMaps(cfg).canonical.values()];
}

export function getVideoGenerationProvider(
  providerId: string | undefined,
  cfg?: NovaConfig,
): VideoGenerationProviderPlugin | undefined {
  const normalized = normalizeCapabilityProviderId(providerId);
  if (!normalized) {
    return undefined;
  }
  return buildProviderMaps(cfg).aliases.get(normalized);
}
