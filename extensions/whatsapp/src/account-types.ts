// Whatsapp plugin module implements account types behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";

export type WhatsAppAccountConfig = NonNullable<
  NonNullable<NonNullable<NovaConfig["channels"]>["whatsapp"]>["accounts"]
>[string];
