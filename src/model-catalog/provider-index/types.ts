// Provider-index types describe install hints, auth choices, and preview catalogs for discoverable providers.
import type { ModelCatalogProvider } from "@nova/model-catalog-core/model-catalog-types";

// Normalized provider-index schema. It describes providers discoverable before
// plugin install, including install hints, auth choices, and preview catalogs.
export type NovaProviderIndexPluginInstall = {
  clawhubSpec?: string;
  npmSpec?: string;
  defaultChoice?: "clawhub" | "npm";
  minHostVersion?: string;
  expectedIntegrity?: string;
};

export type NovaProviderIndexPlugin = {
  id: string;
  package?: string;
  source?: string;
  install?: NovaProviderIndexPluginInstall;
};

export type NovaProviderIndexProviderAuthChoice = {
  method: string;
  choiceId: string;
  choiceLabel: string;
  choiceHint?: string;
  assistantPriority?: number;
  assistantVisibility?: "visible" | "manual-only";
  groupId?: string;
  groupLabel?: string;
  groupHint?: string;
  optionKey?: string;
  cliFlag?: string;
  cliOption?: string;
  cliDescription?: string;
  onboardingScopes?: readonly ("text-inference" | "image-generation" | "music-generation")[];
};

export type NovaProviderIndexProvider = {
  id: string;
  name: string;
  plugin: NovaProviderIndexPlugin;
  docs?: string;
  categories?: readonly string[];
  authChoices?: readonly NovaProviderIndexProviderAuthChoice[];
  previewCatalog?: ModelCatalogProvider;
};

export type NovaProviderIndex = {
  version: number;
  providers: Readonly<Record<string, NovaProviderIndexProvider>>;
};
