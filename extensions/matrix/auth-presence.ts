// Matrix plugin module implements auth presence behavior.
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { createPluginStateSyncKeyedStore } from "nova/plugin-sdk/runtime-doctor";
import {
  MATRIX_CREDENTIALS_MAX_ENTRIES,
  MATRIX_CREDENTIALS_NAMESPACE,
  normalizeMatrixStoredCredentials,
  type MatrixCredentialStateRecord,
} from "./src/matrix/credentials-read.js";

type MatrixAuthPresenceParams =
  | {
      cfg: NovaConfig;
      env?: NodeJS.ProcessEnv;
    }
  | NovaConfig;

export function hasAnyMatrixAuth(
  params: MatrixAuthPresenceParams,
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  const resolvedEnv =
    params && typeof params === "object" && "cfg" in params ? (params.env ?? env) : env;
  try {
    const store = createPluginStateSyncKeyedStore<MatrixCredentialStateRecord>("matrix", {
      namespace: MATRIX_CREDENTIALS_NAMESPACE,
      maxEntries: MATRIX_CREDENTIALS_MAX_ENTRIES,
      overflowPolicy: "reject-new",
      env: resolvedEnv,
    });
    return store.entries().some((entry) => normalizeMatrixStoredCredentials(entry.value) !== null);
  } catch {
    return false;
  }
}
