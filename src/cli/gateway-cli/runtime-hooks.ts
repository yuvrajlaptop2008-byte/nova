import type { NovaConfig } from "../../config/types.nova.js";

export type GatewayRunRuntimeHooks = {
  releaseManagedProxy?: () => Promise<void> | void;
  refreshManagedProxy?: (config: NovaConfig["proxy"]) => Promise<void> | void;
};

let activeGatewayRunRuntimeHooks: GatewayRunRuntimeHooks = {};

export function getGatewayRunRuntimeHooks(): GatewayRunRuntimeHooks {
  return activeGatewayRunRuntimeHooks;
}

export function installGatewayRunRuntimeHooks(hooks: GatewayRunRuntimeHooks): () => void {
  const previous = activeGatewayRunRuntimeHooks;
  activeGatewayRunRuntimeHooks = hooks;
  return () => {
    if (activeGatewayRunRuntimeHooks === hooks) {
      activeGatewayRunRuntimeHooks = previous;
    }
  };
}
