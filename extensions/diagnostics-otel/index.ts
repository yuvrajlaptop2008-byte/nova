// Diagnostics Otel plugin entrypoint registers its Nova integration.
import { definePluginEntry } from "nova/plugin-sdk/plugin-entry";
import { createDiagnosticsOtelService } from "./runtime-api.js";

export default definePluginEntry({
  id: "diagnostics-otel",
  name: "Diagnostics OpenTelemetry",
  description: "Export diagnostics events to OpenTelemetry",
  register(api) {
    api.registerService(createDiagnosticsOtelService());
  },
});
