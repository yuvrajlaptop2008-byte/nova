// Slack API module exposes the plugin public contract.
export {
  buildComputedAccountStatusSnapshot,
  PAIRING_APPROVED_MESSAGE,
  projectCredentialSnapshotFields,
  resolveConfiguredFromRequiredCredentialStatuses,
} from "nova/plugin-sdk/channel-status";
export { buildChannelConfigSchema, SlackConfigSchema } from "../config-api.js";
export type { ChannelMessageActionContext } from "nova/plugin-sdk/channel-contract";
export { DEFAULT_ACCOUNT_ID } from "nova/plugin-sdk/account-id";
export type {
  ChannelPlugin,
  NovaPluginApi,
  PluginRuntime,
} from "nova/plugin-sdk/channel-plugin-common";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export type { SlackAccountConfig } from "nova/plugin-sdk/config-contracts";
export {
  emptyPluginConfigSchema,
  formatPairingApproveHint,
} from "nova/plugin-sdk/channel-plugin-common";
export { loadOutboundMediaFromUrl } from "nova/plugin-sdk/outbound-media";
export { looksLikeSlackTargetId, normalizeSlackMessagingTarget } from "./target-parsing.js";
export { getChatChannelMeta } from "./channel-api.js";
export {
  createActionGate,
  imageResultFromFile,
  jsonResult,
  readNumberParam,
  readPositiveIntegerParam,
  readReactionParams,
  readStringParam,
  withNormalizedTimestamp,
} from "nova/plugin-sdk/channel-actions";
