// Telegram plugin module implements send behavior.
export { requireRuntimeConfig } from "nova/plugin-sdk/plugin-config-runtime";
export { resolveMarkdownTableMode } from "nova/plugin-sdk/markdown-table-runtime";
export type { NovaConfig } from "nova/plugin-sdk/config-contracts";
export type { PollInput, MediaKind } from "nova/plugin-sdk/media-runtime";
export {
  buildOutboundMediaLoadOptions,
  getImageMetadata,
  isGifMedia,
  kindFromMime,
  normalizePollInput,
  probeVideoDimensions,
} from "nova/plugin-sdk/media-runtime";
export { loadWebMedia } from "nova/plugin-sdk/web-media";
