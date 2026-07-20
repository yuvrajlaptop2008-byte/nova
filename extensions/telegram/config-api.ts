// Telegram API module exposes the plugin public contract.
export { buildChannelConfigSchema } from "nova/plugin-sdk/channel-config-schema";
export { TelegramConfigSchema } from "nova/plugin-sdk/bundled-channel-config-schema";
export {
  normalizeTelegramCommandDescription,
  normalizeTelegramCommandName,
  resolveTelegramCustomCommands,
} from "./src/command-config.js";
