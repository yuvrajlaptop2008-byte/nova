// Nextcloud Talk API module exposes the plugin public contract.
export type { ChannelPlugin } from "nova/plugin-sdk/channel-plugin-common";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export { clearAccountEntryFields } from "nova/plugin-sdk/channel-plugin-common";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export { buildChannelConfigSchema } from "nova/plugin-sdk/channel-config-schema";
