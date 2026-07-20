import { NovaTerminalPanel } from "./terminal-panel.ts";

// Guarded define so shared registries can retain this module across reloads.
if (!customElements.get("nova-terminal-panel")) {
  customElements.define("nova-terminal-panel", NovaTerminalPanel);
}
