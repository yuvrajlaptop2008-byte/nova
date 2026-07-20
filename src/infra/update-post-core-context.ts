import type { NovaConfig } from "../config/types.nova.js";

export const POST_CORE_UPDATE_SOURCE_CONFIG_PATH_ENV = "NOVA_UPDATE_POST_CORE_SOURCE_CONFIG_PATH";

export type PreUpdateConfigRestoreInput = {
  sourceConfig: NovaConfig;
  authoredConfig: NovaConfig;
};
