import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export function resolveZalouserDmSessionScope(config: NovaConfig) {
  const configured = config.session?.dmScope;
  return configured === "main" || !configured ? "per-channel-peer" : configured;
}
