/** Process env key that marks child commands as launched by the Nova CLI. */
export const NOVA_CLI_ENV_VAR = "NOVA_CLI";

/** Stable marker value used for Nova-launched subprocess detection. */
const NOVA_CLI_ENV_VALUE = "1";

/** Returns a cloned env object with the Nova CLI marker set. */
export function markNovaExecEnv<T extends Record<string, string | undefined>>(
  /** Source environment to clone before adding the subprocess marker. */
  env: T,
): T {
  return {
    ...env,
    [NOVA_CLI_ENV_VAR]: NOVA_CLI_ENV_VALUE,
  };
}

/** Mutates an existing process env object so current-process children inherit the marker. */
export function ensureNovaExecMarkerOnProcess(
  /** Process env object to mutate; defaults to the current process environment. */
  env: NodeJS.ProcessEnv = process.env,
): NodeJS.ProcessEnv {
  env[NOVA_CLI_ENV_VAR] = NOVA_CLI_ENV_VALUE;
  return env;
}
