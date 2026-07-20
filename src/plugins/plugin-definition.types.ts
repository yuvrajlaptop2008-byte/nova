import type { NovaPluginApi } from "./plugin-api.types.js";
import type { NovaPluginConfigSchema } from "./plugin-config-schema.types.js";
import type { PluginKind } from "./plugin-kind.types.js";
import type {
  NovaPluginReloadRegistration,
  NovaPluginSecurityAuditCollector,
} from "./plugin-registration.types.js";
import type { NovaPluginNodeHostCommand } from "./types.node-host.js";

/** Module-level plugin definition loaded from a native plugin entry file. */
export type NovaPluginDefinition = {
  id?: string;
  name?: string;
  description?: string;
  version?: string;
  /**
   * @deprecated Declare exclusive plugin kind in `nova.plugin.json` via
   * manifest `kind`. Runtime-exported `kind` is kept as a compatibility
   * fallback for older plugins and may require loading plugin runtime on
   * metadata-only command paths.
   */
  kind?: PluginKind | PluginKind[];
  configSchema?: NovaPluginConfigSchema;
  reload?: NovaPluginReloadRegistration;
  nodeHostCommands?: NovaPluginNodeHostCommand[];
  securityAuditCollectors?: NovaPluginSecurityAuditCollector[];
  register?: (api: NovaPluginApi) => void;
};

export type NovaPluginModule = NovaPluginDefinition | ((api: NovaPluginApi) => void);
