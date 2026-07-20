// Public model-catalog facade. Keep exports here curated so callers use the
// normalized planning APIs instead of reaching into provider-index internals.
export { loadNovaProviderIndex } from "./provider-index/index.js";
export {
  planManifestModelCatalogRows,
  planManifestModelCatalogSuppressions,
} from "./manifest-planner.js";
export { planProviderIndexModelCatalogRows } from "./provider-index-planner.js";
export type { ManifestModelCatalogSuppressionEntry } from "./manifest-planner.js";
export type { NovaProviderIndexProvider } from "./provider-index/index.js";
