// Verifies update_plan registration gates and base Nova tool inclusion policy.
import { afterEach, describe, expect, it } from "vitest";
import type { NovaConfig } from "../config/config.js";
import { setEmbeddedMode } from "../infra/embedded-mode.js";
import { isToolWrappedWithBeforeToolCallHook } from "./agent-tools.before-tool-call.js";
import { resolveCoreToolFactoryFamily } from "./core-tool-factory-descriptors.js";
import { createNovaTools } from "./nova-tools.js";
import {
  shouldIncludeAskUserToolForNovaTools,
  shouldIncludeUpdatePlanToolForNovaTools,
} from "./nova-tools.registration.js";
import { createUpdatePlanTool } from "./tools/update-plan-tool.js";

type UpdatePlanGatingParams = Parameters<typeof shouldIncludeUpdatePlanToolForNovaTools>[0];
type CreateNovaToolsOptions = NonNullable<Parameters<typeof createNovaTools>[0]>;

function expectUpdatePlanEnabled(params: UpdatePlanGatingParams, expected: boolean): void {
  expect(shouldIncludeUpdatePlanToolForNovaTools(params)).toBe(expected);
}

function toolNames(tools: ReturnType<typeof createNovaTools>): string[] {
  return tools.map((tool) => tool.name);
}

function createFastToolNames(options: CreateNovaToolsOptions): string[] {
  // Disable unrelated dynamic surfaces so registration assertions stay deterministic.
  return toolNames(
    createNovaTools({
      disableMessageTool: true,
      disablePluginTools: true,
      wrapBeforeToolCallHook: false,
      ...options,
    }),
  );
}

function expectToolNamed(
  tools: ReturnType<typeof createNovaTools>,
  name: string,
): ReturnType<typeof createNovaTools>[number] {
  const tool = tools.find((candidate) => candidate.name === name);
  if (!tool) {
    throw new Error(`Expected tool ${name} to be registered`);
  }
  return tool;
}

describe("nova-tools update_plan gating", () => {
  afterEach(() => {
    setEmbeddedMode(false);
  });

  it("keeps concrete Nova tool names in the factory descriptor catalog", () => {
    const emittedNames = createFastToolNames({
      agentSessionKey: "agent:main:main",
      config: {
        tools: { allow: ["update_plan"] },
        transcripts: { enabled: true },
      } as NovaConfig,
      cwd: "/repo",
      enableHeartbeatTool: true,
      taskSuggestionDeliveryMode: "gateway",
    });

    expect(emittedNames.filter((name) => resolveCoreToolFactoryFamily(name) !== "nova")).toEqual(
      [],
    );
  });

  it("enables update_plan by default", () => {
    expectUpdatePlanEnabled({ config: {} as NovaConfig }, true);
  });

  it("exposes update_plan from default tool construction for every embedded model", () => {
    const defaultTools = createFastToolNames({
      config: {} as NovaConfig,
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    });
    const emptyAllowlistParams = {
      config: {} as NovaConfig,
      pluginToolAllowlist: [],
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    };

    expect(defaultTools).toContain("update_plan");
    expect(defaultTools).not.toContain("ask_user");
    expect(shouldIncludeUpdatePlanToolForNovaTools(emptyAllowlistParams)).toBe(true);
  });

  it("keeps ask_user on primary sessions and excludes spawned worker sessions", () => {
    expect(shouldIncludeAskUserToolForNovaTools({})).toBe(false);
    expect(shouldIncludeAskUserToolForNovaTools({ agentSessionKey: "agent:main:main" })).toBe(true);
    expect(
      shouldIncludeAskUserToolForNovaTools({
        agentSessionKey: "agent:main:subagent:worker",
      }),
    ).toBe(false);
    expect(shouldIncludeAskUserToolForNovaTools({ agentSessionKey: "agent:main:acp:worker" })).toBe(
      false,
    );
    // ask_user must not depend on the TUI embedded-host flag; normal gateway
    // runs are the primary consumer.
    expect(
      createFastToolNames({
        config: {} as NovaConfig,
        runSessionKey: "agent:main:non-embedded",
      }),
    ).toContain("ask_user");
    setEmbeddedMode(true);

    expect(
      createFastToolNames({
        config: {} as NovaConfig,
        agentSessionKey: "agent:main:subagent:worker",
      }),
    ).not.toContain("ask_user");
    expect(
      createFastToolNames({
        config: {} as NovaConfig,
        runSessionKey: "agent:main:run",
      }),
    ).toContain("ask_user");
  });

  it("wraps constructed tools with before-tool-call hooks by default", () => {
    const tools = createNovaTools({
      config: {} as NovaConfig,
      disablePluginTools: true,
    });
    const unwrappedTools = createNovaTools({
      config: {} as NovaConfig,
      disablePluginTools: true,
      wrapBeforeToolCallHook: false,
    });

    expect(isToolWrappedWithBeforeToolCallHook(expectToolNamed(tools, "sessions_list"))).toBe(true);
    expect(
      isToolWrappedWithBeforeToolCallHook(expectToolNamed(unwrappedTools, "sessions_list")),
    ).toBe(false);
  });

  it("keeps message tool in embedded message-tool-only completions", () => {
    setEmbeddedMode(true);
    const tools = createNovaTools({
      config: {} as NovaConfig,
      disablePluginTools: true,
      wrapBeforeToolCallHook: false,
      sourceReplyDeliveryMode: "message_tool_only",
    });

    expect(toolNames(tools)).toContain("message");
  });

  it("exposes delegation only to regular unsandboxed gateway agents", () => {
    const regular = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:main:main",
    });
    const sandboxed = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:main:main",
      sandboxed: true,
    });
    const system = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:nova:main",
    });
    setEmbeddedMode(true);
    const embedded = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:main:main",
    });

    expect(regular).toContain("nova");
    expect(sandboxed).not.toContain("nova");
    expect(system).not.toContain("nova");
    expect(embedded).not.toContain("nova");
  });

  it("requires explicit transcripts enablement before registering the transcripts tool", () => {
    const defaultTools = createFastToolNames({
      config: {} as NovaConfig,
    });
    const enabledTools = createFastToolNames({
      config: { transcripts: { enabled: true } } as NovaConfig,
    });

    expect(defaultTools).not.toContain("transcripts");
    expect(enabledTools).toContain("transcripts");
  });

  it("registers task suggestions only for sessions with an actionable gateway sink", () => {
    const withoutSession = createFastToolNames({
      config: {} as NovaConfig,
      cwd: "/repo",
      taskSuggestionDeliveryMode: "gateway",
    });
    const withoutSink = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:main:main",
      cwd: "/repo",
    });
    const withSink = createFastToolNames({
      config: {} as NovaConfig,
      agentSessionKey: "agent:main:main",
      cwd: "/repo",
      taskSuggestionDeliveryMode: "gateway",
    });

    expect(withoutSession).not.toContain("spawn_task");
    expect(withoutSession).not.toContain("dismiss_task");
    expect(withoutSink).not.toContain("spawn_task");
    expect(withoutSink).not.toContain("dismiss_task");
    expect(withSink).toEqual(expect.arrayContaining(["spawn_task", "dismiss_task"]));
  });

  it("keeps explicitly allowed message tool in embedded completions", () => {
    setEmbeddedMode(true);
    const fromRuntimeAllowlist = createNovaTools({
      config: {} as NovaConfig,
      disablePluginTools: true,
      pluginToolAllowlist: ["message"],
      wrapBeforeToolCallHook: false,
    });
    const fromGlobalAlsoAllow = createNovaTools({
      config: { tools: { profile: "minimal", alsoAllow: ["message"] } } as NovaConfig,
      disablePluginTools: true,
      wrapBeforeToolCallHook: false,
    });
    const denied = createNovaTools({
      config: {} as NovaConfig,
      disablePluginTools: true,
      pluginToolAllowlist: ["message"],
      pluginToolDenylist: ["message"],
      wrapBeforeToolCallHook: false,
    });

    expect(toolNames(fromRuntimeAllowlist)).toContain("message");
    expect(toolNames(fromGlobalAlsoAllow)).toContain("message");
    expect(toolNames(denied)).not.toContain("message");
  });

  it("keeps subagent spawn available for trusted embedded gateway-bound runs", () => {
    setEmbeddedMode(true);
    const defaultTools = createFastToolNames({
      config: {} as NovaConfig,
    });
    const gatewayBoundTools = createFastToolNames({
      config: {} as NovaConfig,
      allowGatewaySubagentBinding: true,
    });

    expect(defaultTools).not.toContain("sessions_spawn");
    expect(defaultTools).not.toContain("sessions_send");
    expect(gatewayBoundTools).toContain("sessions_spawn");
    expect(gatewayBoundTools).not.toContain("sessions_send");
  });

  it("registers update_plan when explicitly enabled", () => {
    const config = {
      tools: {
        experimental: {
          planTool: true,
        },
      },
    } as NovaConfig;

    expectUpdatePlanEnabled({ config }, true);
    expect(createUpdatePlanTool().displaySummary).toBe("Track short work plan.");
  });

  it("registers update_plan when the runtime allowlist explicitly requests it", () => {
    const tools = createFastToolNames({
      config: {} as NovaConfig,
      pluginToolAllowlist: ["update_plan"],
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    });

    expect(tools).toContain("update_plan");
  });

  it("includes update_plan when a config allowlist group includes it", () => {
    const includeUpdatePlan = shouldIncludeUpdatePlanToolForNovaTools({
      config: { tools: { allow: ["group:agents"] } } as NovaConfig,
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    });

    expect(includeUpdatePlan).toBe(true);
  });

  it("includes update_plan when a runtime allowlist group includes it", () => {
    const includeUpdatePlan = shouldIncludeUpdatePlanToolForNovaTools({
      config: {} as NovaConfig,
      pluginToolAllowlist: ["group:agents"],
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    });

    expect(includeUpdatePlan).toBe(true);
  });

  it("leaves normal deny policy enforcement to the assembled tool set", () => {
    const tools = createFastToolNames({
      config: {} as NovaConfig,
      pluginToolAllowlist: ["group:agents"],
      pluginToolDenylist: ["update_plan"],
      modelProvider: "anthropic",
      modelId: "claude-sonnet-4-6",
    });

    expect(tools).not.toContain("update_plan");
  });

  it("lets explicit planTool false disable every model and override allowlists", () => {
    const cfg = {
      tools: {
        experimental: {
          planTool: false,
        },
      },
    } as NovaConfig;

    expectUpdatePlanEnabled({ config: cfg, modelProvider: "openai", modelId: "gpt-5.4" }, false);
    expectUpdatePlanEnabled(
      {
        config: cfg,
        modelProvider: "anthropic",
        modelId: "claude-sonnet-4-6",
        pluginToolAllowlist: ["update_plan"],
      },
      false,
    );
  });
});
