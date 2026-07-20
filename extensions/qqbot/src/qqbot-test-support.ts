// Qqbot plugin module implements qqbot test support behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export function makeQqbotSecretRefConfig(): NovaConfig {
  return {
    channels: {
      qqbot: {
        appId: "123456",
        clientSecret: {
          source: "env",
          provider: "default",
          id: "QQBOT_CLIENT_SECRET",
        },
      },
    },
  } as NovaConfig;
}

export function makeQqbotDefaultAccountConfig(): NovaConfig {
  return {
    channels: {
      qqbot: {
        defaultAccount: "bot2",
        accounts: {
          bot2: { appId: "123456" },
        },
      },
    },
  } as NovaConfig;
}
