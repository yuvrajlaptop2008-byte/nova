// Signal plugin module implements account types behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export type SignalAccountConfig = Omit<
  Exclude<NonNullable<NovaConfig["channels"]>["signal"], undefined>,
  "accounts"
>;
