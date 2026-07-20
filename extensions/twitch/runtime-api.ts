// Private runtime barrel for the bundled Twitch extension.
// Keep this barrel thin and aligned with the local extension surface.

export type {
  ChannelAccountSnapshot,
  ChannelCapabilities,
  ChannelGatewayContext,
  ChannelLogSink,
  ChannelMessageActionAdapter,
  ChannelMessageActionContext,
  ChannelMeta,
  ChannelOutboundAdapter,
  ChannelOutboundContext,
  ChannelResolveKind,
  ChannelResolveResult,
  ChannelStatusAdapter,
} from "nova/plugin-sdk/channel-contract";
export type { ChannelPlugin } from "nova/plugin-sdk/channel-core";
export type { OutboundDeliveryResult } from "nova/plugin-sdk/channel-send-result";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export type { RuntimeEnv } from "nova/plugin-sdk/runtime";
export type { WizardPrompter } from "nova/plugin-sdk/setup";
