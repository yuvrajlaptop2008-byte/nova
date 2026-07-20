// Reef plugin module registers headless CLI commands so agents can drive
// registration, pairing, and status without the interactive wizard.
import type { NovaPluginApi } from "nova/plugin-sdk/channel-plugin-common";

export function registerReefCliMetadata(api: NovaPluginApi) {
  api.registerCli(
    async ({ program }) => {
      const { registerReefCli } = await import("./cli.js");
      registerReefCli({ program });
    },
    {
      descriptors: [
        {
          name: "reef",
          description: "Register on a Reef relay and manage guarded claw-to-claw friendships",
          hasSubcommands: true,
        },
      ],
    },
  );
}
