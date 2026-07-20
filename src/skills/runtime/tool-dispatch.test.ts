// Skill tool dispatch tests cover policy-filtered tool surfaces.
import { describe, expect, it, vi } from "vitest";
import type { NovaConfig } from "../../config/types.nova.js";

type CreateNovaToolsArg = {
  beforeToolCallHookContext?: {
    skillCommand?: { skillFile?: string };
  };
  cronCreatorToolAllowlist?: Array<string | { name: string; pluginId?: string }>;
  nativeChannelId?: string;
};

const hoisted = vi.hoisted(() => {
  function makeTool(name: string) {
    return {
      name,
      description: `${name} tool`,
      parameters: { type: "object", properties: {} },
      execute: vi.fn(),
    };
  }
  return {
    createNovaToolsMock: vi.fn((_args: CreateNovaToolsArg) => [
      makeTool("read"),
      makeTool("cron"),
      makeTool("exec"),
    ]),
  };
});

vi.mock("../../agents/nova-tools.runtime.js", () => ({
  createNovaTools: (args: CreateNovaToolsArg) => hoisted.createNovaToolsMock(args),
}));

import { resolveSkillDispatchTools } from "./tool-dispatch.js";

describe("resolveSkillDispatchTools", () => {
  it("passes final filtered tool surface to cron jobs", () => {
    const tools = resolveSkillDispatchTools({
      message: {
        surface: "telegram",
        senderId: "user-1",
        nativeChannelId: "native-room-1",
      },
      cfg: {
        tools: { allow: ["read", "cron"] },
      } as NovaConfig,
      agentId: "main",
      sessionKey: "agent:main:telegram:group:restricted-room",
      workspaceDir: "/tmp/nova-skill-tool-dispatch-test",
      provider: "openai",
      model: "gpt-5.5",
    });

    const args = hoisted.createNovaToolsMock.mock.calls[0]?.[0];
    expect(tools.map((tool) => tool.name)).toEqual(["read", "cron"]);
    expect(args?.cronCreatorToolAllowlist).toEqual([{ name: "read" }, { name: "cron" }]);
    expect(args?.nativeChannelId).toBe("native-room-1");
  });

  it("carries command skill file identity into tool diagnostics", () => {
    resolveSkillDispatchTools({
      message: { surface: "telegram", senderId: "user-1" },
      cfg: {} as NovaConfig,
      agentId: "main",
      sessionKey: "agent:main:telegram:direct:user-1",
      workspaceDir: "/tmp/nova-skill-tool-dispatch-test",
      provider: "openai",
      model: "gpt-5.5",
      skillCommand: {
        name: "daily-brief",
        skillFile: "/workspace/skills/daily-brief/SKILL.md",
        skillName: "Daily Brief",
        skillSource: "workspace",
        toolName: "read",
      },
    });

    const args = hoisted.createNovaToolsMock.mock.calls.at(-1)?.[0];
    expect(args?.beforeToolCallHookContext?.skillCommand?.skillFile).toBe(
      "/workspace/skills/daily-brief/SKILL.md",
    );
  });
});
