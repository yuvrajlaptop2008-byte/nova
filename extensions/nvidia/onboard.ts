// Nvidia setup module handles plugin onboarding behavior.
import {
  createDefaultModelsPresetAppliers,
  type NovaConfig,
} from "nova/plugin-sdk/provider-onboard";
import { buildSelectableNvidiaProvider, NVIDIA_DEFAULT_MODEL_ID } from "./provider-catalog.js";

export const NVIDIA_DEFAULT_MODEL_REF = NVIDIA_DEFAULT_MODEL_ID;

const nvidiaPresetAppliers = createDefaultModelsPresetAppliers({
  primaryModelRef: NVIDIA_DEFAULT_MODEL_REF,
  resolveParams: (_cfg: NovaConfig) => {
    const defaultProvider = buildSelectableNvidiaProvider();
    return {
      providerId: "nvidia",
      api: defaultProvider.api ?? "openai-completions",
      baseUrl: defaultProvider.baseUrl,
      defaultModels: defaultProvider.models ?? [],
      defaultModelId: NVIDIA_DEFAULT_MODEL_ID,
      aliases: [{ modelRef: NVIDIA_DEFAULT_MODEL_REF, alias: "NVIDIA" }],
    };
  },
});

export function applyNvidiaProviderConfig(cfg: NovaConfig): NovaConfig {
  return nvidiaPresetAppliers.applyProviderConfig(cfg);
}

export function applyNvidiaConfig(cfg: NovaConfig): NovaConfig {
  return nvidiaPresetAppliers.applyConfig(cfg);
}
