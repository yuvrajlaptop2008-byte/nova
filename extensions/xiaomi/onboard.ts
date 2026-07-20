// Xiaomi setup module handles plugin onboarding behavior.
import {
  createDefaultModelsPresetAppliers,
  type NovaConfig,
} from "nova/plugin-sdk/provider-onboard";
import {
  buildXiaomiProvider,
  buildXiaomiTokenPlanProvider,
  resolveXiaomiTokenPlanBaseUrl,
  XIAOMI_DEFAULT_MODEL_ID,
  XIAOMI_PROVIDER_ID,
  XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_ID,
  XIAOMI_TOKEN_PLAN_PROVIDER_ID,
  type XiaomiTokenPlanRegion,
} from "./provider-catalog.js";

export const XIAOMI_DEFAULT_MODEL_REF = `${XIAOMI_PROVIDER_ID}/${XIAOMI_DEFAULT_MODEL_ID}`;
export const XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_REF = `${XIAOMI_TOKEN_PLAN_PROVIDER_ID}/${XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_ID}`;

const xiaomiPresetAppliers = createDefaultModelsPresetAppliers({
  primaryModelRef: XIAOMI_DEFAULT_MODEL_REF,
  resolveParams: (_cfg: NovaConfig) => {
    const defaultProvider = buildXiaomiProvider();
    return {
      providerId: XIAOMI_PROVIDER_ID,
      api: defaultProvider.api ?? "openai-completions",
      baseUrl: defaultProvider.baseUrl,
      defaultModels: defaultProvider.models ?? [],
      defaultModelId: XIAOMI_DEFAULT_MODEL_ID,
      aliases: [{ modelRef: XIAOMI_DEFAULT_MODEL_REF, alias: "Xiaomi" }],
    };
  },
});

const xiaomiTokenPlanPresetAppliers = createDefaultModelsPresetAppliers({
  primaryModelRef: XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_REF,
  resolveParams: (_cfg: NovaConfig) => {
    const defaultProvider = buildXiaomiTokenPlanProvider();
    return {
      providerId: XIAOMI_TOKEN_PLAN_PROVIDER_ID,
      api: defaultProvider.api ?? "openai-completions",
      baseUrl: defaultProvider.baseUrl,
      defaultModels: defaultProvider.models ?? [],
      defaultModelId: XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_ID,
      aliases: (() => {
        const defaultModel = defaultProvider.models?.find(
          (m) => m.id === XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_ID,
        );
        return [
          {
            modelRef: XIAOMI_TOKEN_PLAN_DEFAULT_MODEL_REF,
            alias: defaultModel?.name ?? "MiMo V2.5 Pro",
          },
        ];
      })(),
    };
  },
});

function withProviderBaseUrl(cfg: NovaConfig, providerId: string, baseUrl: string): NovaConfig {
  const providers: Record<string, unknown> = {
    ...cfg.models?.providers,
    [providerId]: {
      ...cfg.models?.providers?.[providerId],
      baseUrl,
    },
  };
  return {
    ...cfg,
    models: {
      ...cfg.models,
      providers,
    },
  } as NovaConfig;
}

export function applyXiaomiProviderConfig(cfg: NovaConfig): NovaConfig {
  return xiaomiPresetAppliers.applyProviderConfig(cfg);
}

export function applyXiaomiConfig(cfg: NovaConfig): NovaConfig {
  return xiaomiPresetAppliers.applyConfig(cfg);
}

export function applyXiaomiTokenPlanConfig(
  cfg: NovaConfig,
  region: XiaomiTokenPlanRegion,
): NovaConfig {
  return withProviderBaseUrl(
    xiaomiTokenPlanPresetAppliers.applyConfig(cfg),
    XIAOMI_TOKEN_PLAN_PROVIDER_ID,
    resolveXiaomiTokenPlanBaseUrl(region),
  );
}
