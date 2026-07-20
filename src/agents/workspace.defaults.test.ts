// Workspace default tests cover environment-variable precedence for the
// built-in agent workspace location.
import path from "node:path";
import { describe, expect, it } from "vitest";
import { withEnv } from "../test-utils/env.js";
import { resolveDefaultAgentWorkspaceDir } from "./workspace.js";

describe("DEFAULT_AGENT_WORKSPACE_DIR", () => {
  it("uses NOVA_HOME when resolving the default workspace dir", () => {
    const home = path.join(path.sep, "srv", "nova-home");

    const resolved = withEnv(
      {
        NOVA_WORKSPACE_DIR: undefined,
        NOVA_PROFILE: undefined,
        NOVA_HOME: home,
        HOME: path.join(path.sep, "home", "other"),
      },
      () => resolveDefaultAgentWorkspaceDir(),
    );

    expect(resolved).toBe(path.join(path.resolve(home), ".nova", "workspace"));
  });

  it("uses NOVA_WORKSPACE_DIR before NOVA_HOME", () => {
    const workspaceDir = path.join(path.sep, "srv", "nova-workspace");

    const resolved = withEnv(
      {
        NOVA_WORKSPACE_DIR: workspaceDir,
        NOVA_HOME: path.join(path.sep, "srv", "nova-home"),
      },
      () => resolveDefaultAgentWorkspaceDir(),
    );

    expect(resolved).toBe(path.resolve(workspaceDir));
  });
});
