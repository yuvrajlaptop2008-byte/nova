// Whatsapp plugin module implements group gating behavior.
export {
  implicitMentionKindWhen,
  resolveInboundMentionDecision,
} from "nova/plugin-sdk/channel-mention-gating";
export { hasControlCommand } from "nova/plugin-sdk/command-detection";
export { createChannelHistoryWindow } from "nova/plugin-sdk/reply-history";
export { parseActivationCommand } from "nova/plugin-sdk/group-activation";
export { normalizeE164 } from "../../text-runtime.js";
