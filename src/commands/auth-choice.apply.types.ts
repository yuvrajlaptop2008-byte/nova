// Shared types for applying auth-choice selections during onboarding and agent setup.
import type { NovaConfig } from "../config/types.nova.js";
import type { ProviderAuthResult } from "../plugins/types.js";
import type { RuntimeEnv } from "../runtime.js";
import type { WizardPrompter } from "../wizard/prompts.js";
import type { AuthChoice, OnboardOptions } from "./onboard-types.js";

export type ApplyAuthChoiceParams = {
  authChoice: AuthChoice;
  config: NovaConfig;
  env?: NodeJS.ProcessEnv;
  prompter: WizardPrompter;
  runtime: RuntimeEnv;
  agentDir?: string;
  setDefaultModel: boolean;
  preserveExistingDefaultModel?: boolean;
  agentId?: string;
  opts?: Partial<OnboardOptions>;
};

export type ApplyAuthChoiceResult = {
  config: NovaConfig;
  agentModelOverride?: string;
  retrySelection?: boolean;
};

export type PreparedAuthChoiceResult = ApplyAuthChoiceResult & {
  authProfiles: ProviderAuthResult["profiles"];
  persistAuthProfiles: (profiles?: ProviderAuthResult["profiles"]) => Promise<void>;
};
