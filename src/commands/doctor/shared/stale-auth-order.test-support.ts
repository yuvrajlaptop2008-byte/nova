import type { AuthProfileStore } from "../../../agents/auth-profiles/types.js";
import type { NovaConfig } from "../../../config/types.nova.js";
import "./stale-auth-order.js";

type TestApi = {
  repairStaleConfiguredAuthOrders(params: {
    cfg: NovaConfig;
    stores: readonly AuthProfileStore[];
    activeStores?: readonly AuthProfileStore[];
    runtimeProfileIds?: ReadonlySet<string>;
  }): { config: NovaConfig; changes: string[] };
};

function getTestApi(): TestApi {
  return (globalThis as Record<PropertyKey, unknown>)[
    Symbol.for("nova.staleAuthOrderTestApi")
  ] as TestApi;
}

export const repairStaleConfiguredAuthOrders: TestApi["repairStaleConfiguredAuthOrders"] = (
  params,
) => getTestApi().repairStaleConfiguredAuthOrders(params);
