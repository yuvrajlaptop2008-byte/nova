// Discord API module exposes the plugin public contract.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { inspectDiscordAccount } from "./src/account-inspect.js";

export function inspectDiscordReadOnlyAccount(cfg: NovaConfig, accountId?: string | null) {
  return inspectDiscordAccount({ cfg, accountId });
}
