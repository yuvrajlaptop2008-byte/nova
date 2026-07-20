// Memory Core plugin module implements public artifacts behavior.
import {
  listMemoryHostPublicArtifacts,
  type MemoryPluginPublicArtifact,
} from "nova/plugin-sdk/memory-host-core";
import type { NovaConfig } from "../api.js";

export async function listMemoryCorePublicArtifacts(params: {
  cfg: NovaConfig;
}): Promise<MemoryPluginPublicArtifact[]> {
  return await listMemoryHostPublicArtifacts(params);
}
