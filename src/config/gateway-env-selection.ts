import { collectConfigRuntimeEnvVars } from "./env-vars.js";
import type { NovaConfig } from "./types.js";

export const GATEWAY_CONFIG_SELECTION_ENV_KEYS: ReadonlySet<string> = new Set([
  "ANDROID_DATA",
  "HOME",
  "HOMEDRIVE",
  "HOMEPATH",
  "NOVA_AGENT_DIR",
  "NOVA_CONFIG_PATH",
  "NOVA_HOME",
  "NOVA_INCLUDE_ROOTS",
  "NOVA_NIX_MODE",
  "NOVA_OAUTH_DIR",
  "NOVA_PACKAGE_DIR",
  "NOVA_PROFILE",
  "NOVA_STATE_DIR",
  "NOVA_TEST_FAST",
  "NOVA_WORKSPACE_DIR",
  "PI_CODING_AGENT_DIR",
  "PREFIX",
  "USERPROFILE",
]);

/** Rejects config.env changes that would retarget a running Gateway process. */
export function assertGatewayConfigEnvSelectionUnchanged(
  previousConfig: NovaConfig,
  nextConfig: NovaConfig,
): void {
  const normalize = (config: NovaConfig) =>
    new Map(
      Object.entries(collectConfigRuntimeEnvVars(config)).map(([key, value]) => [
        key.toUpperCase(),
        value,
      ]),
    );
  const previous = normalize(previousConfig);
  const next = normalize(nextConfig);
  for (const key of GATEWAY_CONFIG_SELECTION_ENV_KEYS) {
    if (previous.get(key) !== next.get(key)) {
      throw new Error(
        `Config env cannot change process-stable Gateway selector ${key} during reload. Restart with the target environment instead.`,
      );
    }
  }
}
