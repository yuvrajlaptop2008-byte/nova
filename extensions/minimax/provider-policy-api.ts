// MiniMax policy module exposes static provider policy before runtime registration.
import type { ProviderDefaultThinkingPolicyContext } from "nova/plugin-sdk/core";
import { resolveMinimaxThinkingProfile } from "./thinking.js";

export function resolveThinkingProfile(context: ProviderDefaultThinkingPolicyContext) {
  return resolveMinimaxThinkingProfile(context.modelId);
}
