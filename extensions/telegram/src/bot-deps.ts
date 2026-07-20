// Telegram plugin module implements bot deps behavior.
import { recordChannelActivity } from "nova/plugin-sdk/channel-activity-runtime";
import { buildChannelInboundEventContext } from "nova/plugin-sdk/channel-inbound";
import {
  createChannelMessageReplyPipeline,
  deliverInboundReplyWithMessageSendContext,
} from "nova/plugin-sdk/channel-outbound";
import { readChannelAllowFromStore } from "nova/plugin-sdk/conversation-runtime";
import {
  recordInboundSession,
  upsertChannelPairingRequest,
} from "nova/plugin-sdk/conversation-runtime";
import { buildModelsProviderData } from "nova/plugin-sdk/models-provider-runtime";
import { dispatchReplyWithBufferedBlockDispatcher } from "nova/plugin-sdk/reply-dispatch-runtime";
import { resolveInboundLastRouteSessionKey } from "nova/plugin-sdk/routing";
import { getRuntimeConfig } from "nova/plugin-sdk/runtime-config-snapshot";
import { resolvePinnedMainDmOwnerFromAllowlist } from "nova/plugin-sdk/security-runtime";
import {
  getSessionEntry,
  listSessionEntries,
  readSessionUpdatedAt,
  readAmbientTranscriptWatermark,
  resolveAmbientTranscriptWatermarkKey,
  resolveStorePath,
} from "nova/plugin-sdk/session-store-runtime";
import { listSkillCommandsForAgents } from "nova/plugin-sdk/skill-commands-runtime";
import { enqueueSystemEvent } from "nova/plugin-sdk/system-event-runtime";
import { loadWebMedia } from "nova/plugin-sdk/web-media";
import { syncTelegramMenuCommands } from "./bot-native-command-menu.js";
import { deliverReplies, emitInternalMessageSentHook } from "./bot/delivery.js";
import { createTelegramDraftStream } from "./draft-stream.js";
import {
  resolveTelegramApproval,
  resolveTelegramLegacyApproval,
} from "./exec-approval-resolver.js";
import { recordOutboundMessageForPromptContext } from "./outbound-message-context.js";
import { editMessageTelegram } from "./send.js";
import { wasSentByBot } from "./sent-message-cache.js";

export type TelegramBotDeps = {
  getRuntimeConfig: typeof getRuntimeConfig;
  resolveStorePath: typeof resolveStorePath;
  getSessionEntry?: typeof getSessionEntry;
  listSessionEntries?: typeof listSessionEntries;
  readSessionUpdatedAt?: typeof readSessionUpdatedAt;
  readAmbientTranscriptWatermark?: typeof readAmbientTranscriptWatermark;
  resolveAmbientTranscriptWatermarkKey?: typeof resolveAmbientTranscriptWatermarkKey;
  recordInboundSession?: typeof recordInboundSession;
  recordChannelActivity?: typeof recordChannelActivity;
  resolveInboundLastRouteSessionKey?: typeof resolveInboundLastRouteSessionKey;
  resolvePinnedMainDmOwnerFromAllowlist?: typeof resolvePinnedMainDmOwnerFromAllowlist;
  buildChannelInboundEventContext?: typeof buildChannelInboundEventContext;
  readChannelAllowFromStore: typeof readChannelAllowFromStore;
  upsertChannelPairingRequest: typeof upsertChannelPairingRequest;
  enqueueSystemEvent: typeof enqueueSystemEvent;
  dispatchReplyWithBufferedBlockDispatcher: typeof dispatchReplyWithBufferedBlockDispatcher;
  loadWebMedia?: typeof loadWebMedia;
  buildModelsProviderData: typeof buildModelsProviderData;
  listSkillCommandsForAgents: typeof listSkillCommandsForAgents;
  syncTelegramMenuCommands?: typeof syncTelegramMenuCommands;
  wasSentByBot: typeof wasSentByBot;
  resolveApproval?: typeof resolveTelegramApproval;
  resolveLegacyApproval?: typeof resolveTelegramLegacyApproval;
  createTelegramDraftStream?: typeof createTelegramDraftStream;
  deliverReplies?: typeof deliverReplies;
  deliverInboundReplyWithMessageSendContext?: typeof deliverInboundReplyWithMessageSendContext;
  emitInternalMessageSentHook?: typeof emitInternalMessageSentHook;
  editMessageTelegram?: typeof editMessageTelegram;
  recordOutboundMessageForPromptContext?: typeof recordOutboundMessageForPromptContext;
  createChannelMessageReplyPipeline?: typeof createChannelMessageReplyPipeline;
};

export const defaultTelegramBotDeps: TelegramBotDeps = {
  get getRuntimeConfig() {
    return getRuntimeConfig;
  },
  get resolveStorePath() {
    return resolveStorePath;
  },
  get getSessionEntry() {
    return getSessionEntry;
  },
  get listSessionEntries() {
    return listSessionEntries;
  },
  get readChannelAllowFromStore() {
    return readChannelAllowFromStore;
  },
  get readSessionUpdatedAt() {
    return readSessionUpdatedAt;
  },
  get readAmbientTranscriptWatermark() {
    return readAmbientTranscriptWatermark;
  },
  get resolveAmbientTranscriptWatermarkKey() {
    return resolveAmbientTranscriptWatermarkKey;
  },
  get recordInboundSession() {
    return recordInboundSession;
  },
  get recordChannelActivity() {
    return recordChannelActivity;
  },
  get resolveInboundLastRouteSessionKey() {
    return resolveInboundLastRouteSessionKey;
  },
  get resolvePinnedMainDmOwnerFromAllowlist() {
    return resolvePinnedMainDmOwnerFromAllowlist;
  },
  get buildChannelInboundEventContext() {
    return buildChannelInboundEventContext;
  },
  get upsertChannelPairingRequest() {
    return upsertChannelPairingRequest;
  },
  get enqueueSystemEvent() {
    return enqueueSystemEvent;
  },
  get dispatchReplyWithBufferedBlockDispatcher() {
    return dispatchReplyWithBufferedBlockDispatcher;
  },
  get loadWebMedia() {
    return loadWebMedia;
  },
  get buildModelsProviderData() {
    return buildModelsProviderData;
  },
  get listSkillCommandsForAgents() {
    return listSkillCommandsForAgents;
  },
  get syncTelegramMenuCommands() {
    return syncTelegramMenuCommands;
  },
  get wasSentByBot() {
    return wasSentByBot;
  },
  get resolveApproval() {
    return resolveTelegramApproval;
  },
  get resolveLegacyApproval() {
    return resolveTelegramLegacyApproval;
  },
  get createTelegramDraftStream() {
    return createTelegramDraftStream;
  },
  get deliverReplies() {
    return deliverReplies;
  },
  get deliverInboundReplyWithMessageSendContext() {
    return deliverInboundReplyWithMessageSendContext;
  },
  get emitInternalMessageSentHook() {
    return emitInternalMessageSentHook;
  },
  get editMessageTelegram() {
    return editMessageTelegram;
  },
  get recordOutboundMessageForPromptContext() {
    return recordOutboundMessageForPromptContext;
  },
  get createChannelMessageReplyPipeline() {
    return createChannelMessageReplyPipeline;
  },
};
