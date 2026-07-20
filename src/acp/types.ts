/** ACP protocol helpers and Nova agent identity metadata. */
export { normalizeAcpProvenanceMode } from "@nova/acp-core/types";
import { VERSION } from "../version.js";

/** ACP agent identity advertised during protocol initialization. */
export const ACP_AGENT_INFO = {
  name: "openclaw-acp",
  title: "Nova ACP Gateway",
  version: VERSION,
};
