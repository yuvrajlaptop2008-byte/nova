// Gateway model-pricing config helper.
// Resolves whether cost/pricing metadata should be available to Gateway surfaces.
import type { NovaConfig } from "../config/types.nova.js";

/** Returns whether gateway model pricing/cost metadata should be shown. */
export function isGatewayModelPricingEnabled(config: NovaConfig): boolean {
  return config.models?.pricing?.enabled !== false;
}
