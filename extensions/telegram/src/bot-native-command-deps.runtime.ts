import { readChannelAllowFromStore } from "nova/plugin-sdk/conversation-runtime";
import { getPluginCommandSpecs } from "nova/plugin-sdk/plugin-runtime";
// Telegram plugin module implements bot native command deps behavior.
import type {
  ModelsAuthLoginFlowOptions,
  ModelsAuthLoginFlowResult,
} from "nova/plugin-sdk/provider-auth-login-flow-runtime";
import { dispatchReplyWithBufferedBlockDispatcher } from "nova/plugin-sdk/reply-dispatch-runtime";
import { getRuntimeConfig } from "nova/plugin-sdk/runtime-config-snapshot";
import { listSkillCommandsForAgents } from "nova/plugin-sdk/skill-commands-runtime";
import type { TelegramBotDeps } from "./bot-deps.js";
import { syncTelegramMenuCommands } from "./bot-native-command-menu.js";
import { loadTelegramSendModule } from "./send-runtime.js";

export type TelegramNativeCommandDeps = Pick<
  TelegramBotDeps,
  | "dispatchReplyWithBufferedBlockDispatcher"
  | "editMessageTelegram"
  | "getRuntimeConfig"
  | "listSkillCommandsForAgents"
  | "readChannelAllowFromStore"
  | "syncTelegramMenuCommands"
> & {
  getPluginCommandSpecs?: typeof getPluginCommandSpecs;
  runModelsAuthLoginFlow?: (opts: ModelsAuthLoginFlowOptions) => Promise<ModelsAuthLoginFlowResult>;
};

export const defaultTelegramNativeCommandDeps: TelegramNativeCommandDeps = {
  get getRuntimeConfig() {
    return getRuntimeConfig;
  },
  get readChannelAllowFromStore() {
    return readChannelAllowFromStore;
  },
  get dispatchReplyWithBufferedBlockDispatcher() {
    return dispatchReplyWithBufferedBlockDispatcher;
  },
  get listSkillCommandsForAgents() {
    return listSkillCommandsForAgents;
  },
  get syncTelegramMenuCommands() {
    return syncTelegramMenuCommands;
  },
  get getPluginCommandSpecs() {
    return getPluginCommandSpecs;
  },
  async runModelsAuthLoginFlow(opts) {
    const { runModelsAuthLoginFlow } =
      await import("nova/plugin-sdk/provider-auth-login-flow-runtime");
    return await runModelsAuthLoginFlow(opts);
  },
  async editMessageTelegram(...args) {
    const { editMessageTelegram } = await loadTelegramSendModule();
    return await editMessageTelegram(...args);
  },
};
