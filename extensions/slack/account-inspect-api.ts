// Slack API module exposes the plugin public contract.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { inspectSlackAccount } from "./src/account-inspect.js";

export function inspectSlackReadOnlyAccount(cfg: NovaConfig, accountId?: string | null) {
  return inspectSlackAccount({ cfg, accountId });
}
