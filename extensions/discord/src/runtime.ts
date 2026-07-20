// Discord plugin module implements runtime behavior.
import type { PluginRuntime } from "nova/plugin-sdk/channel-core";
import { createPluginRuntimeStore } from "nova/plugin-sdk/runtime-store";

type DiscordChannelRuntime = {
  messageActions?: typeof import("./channel-actions.js").discordMessageActions;
  sendMessageDiscord?: typeof import("./send.js").sendMessageDiscord;
};

type DiscordRuntime = PluginRuntime & {
  channel: PluginRuntime["channel"] & {
    discord?: DiscordChannelRuntime;
  };
};

const {
  setRuntime: setDiscordRuntime,
  tryGetRuntime: getOptionalDiscordRuntime,
  getRuntime: getDiscordRuntime,
} = createPluginRuntimeStore<DiscordRuntime>({
  pluginId: "discord",
  errorMessage: "Discord runtime not initialized",
});
export { getDiscordRuntime, getOptionalDiscordRuntime, setDiscordRuntime };
