// Imessage plugin module implements account types behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export type IMessageAccountConfig = Omit<
  NonNullable<NonNullable<NovaConfig["channels"]>["imessage"]>,
  "accounts" | "defaultAccount"
>;
