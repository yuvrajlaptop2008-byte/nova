// Whatsapp API module exposes the plugin public contract.
export { getChatChannelMeta, type ChannelPlugin } from "nova/plugin-sdk/core";
export { buildChannelConfigSchema, WhatsAppConfigSchema } from "../config-api.js";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export {
  formatWhatsAppConfigAllowFromEntries,
  resolveWhatsAppConfigAllowFrom,
  resolveWhatsAppConfigDefaultTo,
} from "./config-accessors.js";
export {
  createActionGate,
  jsonResult,
  readReactionParams,
  readStringParam,
  ToolAuthorizationError,
} from "nova/plugin-sdk/channel-actions";
export { normalizeE164 } from "nova/plugin-sdk/account-resolution";
export type { DmPolicy, GroupPolicy } from "nova/plugin-sdk/config-contracts";
import type { NovaConfig as RuntimeNovaConfig } from "nova/plugin-sdk/config-contracts";
import { loadWhatsAppChannelRuntime } from "./channel-runtime-loader.js";

export { type ChannelMessageActionName } from "nova/plugin-sdk/channel-contract";
export {
  resolveWhatsAppGroupRequireMention,
  resolveWhatsAppGroupToolPolicy,
} from "./group-policy.js";
export {
  resolveWhatsAppGroupIntroHint,
  resolveWhatsAppMentionStripRegexes,
} from "./group-intro.js";
export { createWhatsAppOutboundBase } from "./outbound-base.js";
export {
  isWhatsAppGroupJid,
  isWhatsAppUserTarget,
  looksLikeWhatsAppTargetId,
  normalizeWhatsAppAllowFromEntries,
  normalizeWhatsAppMessagingTarget,
  normalizeWhatsAppTarget,
} from "./normalize-target.js";
export { resolveWhatsAppOutboundTarget } from "./resolve-outbound-target.js";
export { resolveWhatsAppReactionLevel } from "./reaction-level.js";

export type NovaConfig = RuntimeNovaConfig;
export type { WhatsAppAccountConfig } from "./account-types.js";

type MonitorWebChannel = typeof import("./channel.runtime.js").monitorWebChannel;

export async function monitorWebChannel(
  ...args: Parameters<MonitorWebChannel>
): ReturnType<MonitorWebChannel> {
  const { monitorWebChannel: monitorWebChannelLocal } = await loadWhatsAppChannelRuntime();
  return await monitorWebChannelLocal(...args);
}
