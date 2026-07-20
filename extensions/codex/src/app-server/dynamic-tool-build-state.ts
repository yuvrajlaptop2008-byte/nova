type NovaCodingToolsFactory =
  (typeof import("nova/plugin-sdk/agent-harness"))["createNovaCodingTools"];

/** Mutable dependency seam shared by dynamic-tool construction and its behavioral tests. */
export const dynamicToolBuildState: {
  novaCodingToolsFactory?: NovaCodingToolsFactory;
} = {};
