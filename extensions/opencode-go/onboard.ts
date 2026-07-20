// Opencode Go setup module handles plugin onboarding behavior.
import { applyAgentDefaultModelPrimary, type NovaConfig } from "nova/plugin-sdk/provider-onboard";

export const OPENCODE_GO_DEFAULT_MODEL_REF = "opencode-go/kimi-k2.6";

export function applyOpencodeGoProviderConfig(cfg: NovaConfig): NovaConfig {
  return cfg;
}

export function applyOpencodeGoConfig(cfg: NovaConfig): NovaConfig {
  return applyAgentDefaultModelPrimary(
    applyOpencodeGoProviderConfig(cfg),
    OPENCODE_GO_DEFAULT_MODEL_REF,
  );
}
