// Provider-index loader normalizes bundled installable-provider metadata and falls back to an empty index.
import { normalizeNovaProviderIndex } from "./normalize.js";
import { NOVA_PROVIDER_INDEX } from "./nova-provider-index.js";
import type { NovaProviderIndex } from "./types.js";

// Load the bundled provider index through the normalizer. Invalid generated or
// caller-supplied data falls back to an empty v1 index instead of leaking shape.
export function loadNovaProviderIndex(source: unknown = NOVA_PROVIDER_INDEX): NovaProviderIndex {
  return normalizeNovaProviderIndex(source) ?? { version: 1, providers: {} };
}
