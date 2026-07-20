// Telegram API module exposes the plugin public contract.
import type { NovaConfig } from "./runtime-api.js";
import { inspectTelegramAccount } from "./src/account-inspect.js";

export function inspectTelegramReadOnlyAccount(cfg: NovaConfig, accountId?: string | null) {
  return inspectTelegramAccount({ cfg, accountId });
}
