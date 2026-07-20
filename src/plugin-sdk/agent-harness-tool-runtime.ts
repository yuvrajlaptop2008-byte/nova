/**
 * Focused runtime SDK subpath for native harness tool-surface routing.
 *
 * Keep tool-search and code-mode dependencies out of the lightweight harness
 * lifecycle facade used during plugin startup.
 */
import {
  createAgentHarnessToolSurfaceRuntime as createCoreAgentHarnessToolSurfaceRuntime,
  type AgentHarnessToolSurfaceRuntime as CoreAgentHarnessToolSurfaceRuntime,
} from "../agents/harness/tool-surface-bridge.js";

type NovaCodingToolsOptions = NonNullable<
  Parameters<typeof import("./agent-harness.js").createNovaCodingTools>[0]
>;

export type AgentHarnessToolSurfaceRuntime = Omit<
  CoreAgentHarnessToolSurfaceRuntime,
  "toolSearchCatalogExecutor" | "toolSearchCatalogRef"
> & {
  toolSearchCatalogExecutor: NovaCodingToolsOptions["toolSearchCatalogExecutor"];
  toolSearchCatalogRef: NovaCodingToolsOptions["toolSearchCatalogRef"];
};

export type AgentHarnessToolSurfaceRuntimeParams = Omit<
  Parameters<typeof createCoreAgentHarnessToolSurfaceRuntime>[0],
  "executeTool"
> & {
  executeTool: NonNullable<NovaCodingToolsOptions["toolSearchCatalogExecutor"]>;
};

export function createAgentHarnessToolSurfaceRuntime(
  params: AgentHarnessToolSurfaceRuntimeParams,
): AgentHarnessToolSurfaceRuntime {
  return createCoreAgentHarnessToolSurfaceRuntime(params);
}
