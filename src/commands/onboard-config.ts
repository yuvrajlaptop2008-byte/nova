/** Shared config mutations used by interactive and non-interactive onboarding. */
import { setConfigValueAtPath } from "../config/config-paths.js";
import type { NovaConfig } from "../config/types.nova.js";
import type { ToolProfileId } from "../config/types.tools.js";

/** Default tool profile selected during local onboarding. */
const ONBOARDING_DEFAULT_TOOLS_PROFILE: ToolProfileId = "coding";

/** Applies local gateway/workspace defaults without overwriting explicit user defaults. */
// Deliberately writes no session.dmScope: the schema default "main" (one rolling
// personal-agent session across channels) is the product default. Multi-user DM
// isolation is opt-in; `nova security audit` nudges it when traffic warrants.
export function applyLocalSetupWorkspaceConfig(
  baseConfig: NovaConfig,
  workspaceDir: string,
): NovaConfig {
  return {
    ...baseConfig,
    agents: {
      ...baseConfig.agents,
      defaults: {
        ...baseConfig.agents?.defaults,
        workspace: workspaceDir,
      },
    },
    gateway: {
      ...baseConfig.gateway,
      mode: "local",
    },
    tools: {
      ...baseConfig.tools,
      profile: baseConfig.tools?.profile ?? ONBOARDING_DEFAULT_TOOLS_PROFILE,
    },
  };
}

/** Marks default agents to skip bootstrap file creation. */
export function applySkipBootstrapConfig(cfg: NovaConfig): NovaConfig {
  const next = structuredClone(cfg);
  setConfigValueAtPath(
    next as Record<string, unknown>,
    ["agents", "defaults", "skipBootstrap"],
    true,
  );
  return next;
}
