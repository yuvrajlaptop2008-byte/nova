import type { PluginJsonValue } from "./host-hook-json.js";

export type NovaPluginGatewayEventScope = "operator.read" | "operator.write" | "operator.admin";

export type NovaPluginGatewayEvents = {
  emit: (
    event: string,
    payload: PluginJsonValue,
    opts: { scope: NovaPluginGatewayEventScope },
  ) => void;
};
