// Whatsapp plugin module implements channel actions behavior.
import { createActionGate } from "nova/plugin-sdk/channel-actions";
import type { ChannelMessageActionName } from "nova/plugin-sdk/channel-contract";
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export { listWhatsAppAccountIds, resolveWhatsAppAccount } from "./accounts.js";
export { resolveWhatsAppReactionLevel } from "./reaction-level.js";
export { createActionGate, type ChannelMessageActionName, type NovaConfig };
