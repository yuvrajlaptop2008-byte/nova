// Discord type declarations define plugin contracts.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import type { CommandArgValues } from "nova/plugin-sdk/native-command-registry";

export type DiscordConfig = NonNullable<NovaConfig["channels"]>["discord"];

export type DiscordCommandArgs = {
  raw?: string;
  values?: CommandArgValues;
};
