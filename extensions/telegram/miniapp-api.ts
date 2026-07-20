// Telegram Mini App registerFull entrypoint.
import type { NovaPluginApi } from "nova/plugin-sdk/plugin-entry";
import { registerTelegramMiniAppCommand } from "./src/miniapp/command.js";
import { registerTelegramMiniAppRoutes } from "./src/miniapp/routes.js";

export function registerTelegramMiniApp(api: NovaPluginApi): void {
  registerTelegramMiniAppRoutes(api);
  registerTelegramMiniAppCommand(api);
}
