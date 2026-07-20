import { AgentSelect } from "./agent-select.ts";

if (!customElements.get("nova-agent-select")) {
  customElements.define("nova-agent-select", AgentSelect);
}
