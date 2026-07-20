/** Detects whether a daemon was launched by Nova's container-aware service wrapper. */
import { normalizeOptionalString } from "@nova/normalization-core/string-coerce";

/** Resolves the daemon container hint exposed by managed service environments. */
export function resolveDaemonContainerContext(
  env: Record<string, string | undefined> = process.env,
): string | null {
  return (
    normalizeOptionalString(env.NOVA_CONTAINER_HINT) ||
    normalizeOptionalString(env.NOVA_CONTAINER) ||
    null
  );
}
