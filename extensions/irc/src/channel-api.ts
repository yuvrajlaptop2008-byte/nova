// Irc API module exposes the plugin public contract.
export { createAccountStatusSink } from "nova/plugin-sdk/channel-outbound";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export type { ChannelPlugin } from "nova/plugin-sdk/channel-core";
export { PAIRING_APPROVED_MESSAGE } from "nova/plugin-sdk/channel-status";
export { buildBaseChannelStatusSummary } from "nova/plugin-sdk/status-helpers";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
