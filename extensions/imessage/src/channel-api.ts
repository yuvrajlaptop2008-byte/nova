// Imessage API module exposes the plugin public contract.
import { formatTrimmedAllowFromEntries } from "nova/plugin-sdk/channel-config-helpers";
import { PAIRING_APPROVED_MESSAGE } from "nova/plugin-sdk/channel-status";
import { DEFAULT_ACCOUNT_ID, getChatChannelMeta, type ChannelPlugin } from "nova/plugin-sdk/core";
import { resolveChannelMediaMaxBytes } from "nova/plugin-sdk/media-runtime";
import { collectStatusIssuesFromLastError } from "nova/plugin-sdk/status-helpers";
import { normalizeIMessageMessagingTarget } from "./normalize.js";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";

export {
  collectStatusIssuesFromLastError,
  DEFAULT_ACCOUNT_ID,
  formatTrimmedAllowFromEntries,
  getChatChannelMeta,
  normalizeIMessageMessagingTarget,
  PAIRING_APPROVED_MESSAGE,
  resolveChannelMediaMaxBytes,
};

export type { ChannelPlugin };
