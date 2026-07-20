// Discord plugin module implements audit behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { inspectDiscordAccount } from "./account-inspect.js";
import {
  auditDiscordChannelPermissionsWithFetcher,
  collectDiscordAuditChannelIdsForAccount,
  type DiscordChannelPermissionsAudit,
} from "./audit-core.js";
import { fetchChannelPermissionsDiscord } from "./send.js";

export function collectDiscordAuditChannelIds(params: {
  cfg: NovaConfig;
  accountId?: string | null;
}) {
  const account = inspectDiscordAccount({
    cfg: params.cfg,
    accountId: params.accountId,
  });
  return collectDiscordAuditChannelIdsForAccount(account.config);
}

export async function auditDiscordChannelPermissions(params: {
  cfg: NovaConfig;
  token: string;
  accountId?: string | null;
  channelIds: string[];
  timeoutMs: number;
}): Promise<DiscordChannelPermissionsAudit> {
  return await auditDiscordChannelPermissionsWithFetcher({
    ...params,
    fetchChannelPermissions: fetchChannelPermissionsDiscord,
  });
}
