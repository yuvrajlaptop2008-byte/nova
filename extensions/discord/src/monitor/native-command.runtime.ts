// Discord plugin module implements native command behavior.
import { resolveDirectStatusReplyForSession } from "nova/plugin-sdk/command-status-runtime";
import * as pluginRuntime from "nova/plugin-sdk/plugin-runtime";
import { dispatchReplyWithDispatcher } from "nova/plugin-sdk/reply-dispatch-runtime";
import { getSessionEntry } from "nova/plugin-sdk/session-store-runtime";
import { resolveDiscordNativeInteractionRouteState } from "./native-command-route.js";

export const nativeCommandRuntime = {
  matchPluginCommand: pluginRuntime.matchPluginCommand,
  executePluginCommand: pluginRuntime.executePluginCommand,
  dispatchReplyWithDispatcher,
  resolveDirectStatusReplyForSession,
  resolveDiscordNativeInteractionRouteState,
  getSessionEntry,
};
