/**
 * Chutes onboarding config helpers for OAuth and API-key setup.
 */
import {
  applyAgentDefaultModelPrimary,
  applyProviderConfigWithModelCatalogPreset,
  type NovaConfig,
} from "nova/plugin-sdk/provider-onboard";
import {
  CHUTES_BASE_URL,
  CHUTES_DEFAULT_MODEL_REF,
  CHUTES_MODEL_CATALOG,
  buildChutesModelDefinition,
} from "./models.js";

export { CHUTES_DEFAULT_MODEL_REF };

/**
 * Apply Chutes provider configuration without changing the default model.
 * Registers all catalog models and convenience aliases.
 */
export function applyChutesProviderConfig(cfg: NovaConfig): NovaConfig {
  return applyProviderConfigWithModelCatalogPreset(cfg, {
    providerId: "chutes",
    api: "openai-completions",
    baseUrl: CHUTES_BASE_URL,
    catalogModels: CHUTES_MODEL_CATALOG.map(buildChutesModelDefinition),
    aliases: [
      ...CHUTES_MODEL_CATALOG.map((model) => `chutes/${model.id}`),
      {
        modelRef: "chutes-vision",
        alias: "chutes/moonshotai/Kimi-K2.5-TEE",
      },
      { modelRef: "chutes-pro", alias: "chutes/deepseek-ai/DeepSeek-V3.2-TEE" },
    ],
  });
}

/**
 * Apply Chutes provider configuration AND set Chutes as the default model.
 */
export function applyChutesConfig(cfg: NovaConfig): NovaConfig {
  const next = applyChutesProviderConfig(cfg);
  return {
    ...next,
    agents: {
      ...next.agents,
      defaults: {
        ...next.agents?.defaults,
        model: {
          primary: CHUTES_DEFAULT_MODEL_REF,
          fallbacks: ["chutes/deepseek-ai/DeepSeek-V3.2-TEE", "chutes/moonshotai/Kimi-K2.5-TEE"],
        },
        imageModel: {
          primary: "chutes/moonshotai/Kimi-K2.5-TEE",
          fallbacks: ["chutes/Qwen/Qwen3.5-397B-A17B-TEE"],
        },
      },
    },
  };
}

/** Applies Chutes provider config and sets the default model for API-key auth. */
export function applyChutesApiKeyConfig(cfg: NovaConfig): NovaConfig {
  return applyAgentDefaultModelPrimary(applyChutesProviderConfig(cfg), CHUTES_DEFAULT_MODEL_REF);
}
