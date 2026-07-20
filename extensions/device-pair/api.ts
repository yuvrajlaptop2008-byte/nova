// Device Pair API module exposes the plugin public contract.
export {
  approveDevicePairing,
  clearDeviceBootstrapTokens,
  issueDeviceBootstrapToken,
  PAIRING_SETUP_BOOTSTRAP_PROFILE,
  listDevicePairing,
  revokeDeviceBootstrapToken,
  type DeviceBootstrapProfile,
} from "nova/plugin-sdk/device-bootstrap";
export { definePluginEntry, type NovaPluginApi } from "nova/plugin-sdk/plugin-entry";
export {
  resolveGatewayBindUrl,
  resolveGatewayPort,
  resolveTailnetHostWithRunner,
  resolveTailscaleServeGatewayUrlsWithRunner,
} from "nova/plugin-sdk/core";
export { resolveAdvertisedLanHost } from "nova/plugin-sdk/gateway-runtime";
export { resolvePreferredNovaTmpDir, runPluginCommandWithTimeout } from "nova/plugin-sdk/sandbox";
export { renderQrPngBase64, renderQrPngDataUrl, writeQrPngTempFile } from "./qr-image.js";
