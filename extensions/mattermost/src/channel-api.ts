// Mattermost API module exposes the plugin public contract.
export { createAccountStatusSink } from "nova/plugin-sdk/channel-outbound";
export type { ChannelPlugin } from "nova/plugin-sdk/core";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/core";
export { chunkTextForOutbound } from "nova/plugin-sdk/text-chunking";
