// Feishu API module exposes the plugin public contract.
export type {
  ChannelMessageActionName,
  ChannelMeta,
  ChannelPlugin,
  ClawdbotConfig,
} from "../runtime-api.js";

export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-resolution";
export { createActionGate } from "nova/plugin-sdk/channel-actions";
export {
  buildProbeChannelStatusSummary,
  createDefaultChannelRuntimeState,
} from "nova/plugin-sdk/status-helpers";
export { PAIRING_APPROVED_MESSAGE } from "nova/plugin-sdk/channel-status";
