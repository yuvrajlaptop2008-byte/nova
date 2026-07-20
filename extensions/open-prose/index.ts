// Open Prose plugin entrypoint registers its Nova integration.
import { definePluginEntry, type NovaPluginApi } from "./runtime-api.js";

export default definePluginEntry({
  id: "open-prose",
  name: "OpenProse",
  description: "Plugin-shipped prose skills bundle",
  register(_api: NovaPluginApi) {
    // OpenProse is delivered via plugin-shipped skills.
  },
});
