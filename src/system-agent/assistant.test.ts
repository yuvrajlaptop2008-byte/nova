// Nova assistant tests cover plan parsing and inference prompt construction.
import { describe, expect, it } from "vitest";
import {
  buildSystemAgentAssistantUserPrompt,
  parseSystemAgentAssistantPlanText,
} from "./assistant.js";
import type { SystemAgentOverview } from "./overview.js";

function overview(overrides: Partial<SystemAgentOverview["tools"]> = {}): SystemAgentOverview {
  return {
    config: {
      path: "/tmp/nova.json",
      exists: false,
      valid: false,
      issues: [],
      hash: null,
    },
    agents: [],
    defaultAgentId: "default",
    tools: {
      codex: { command: "codex", found: false },
      claude: { command: "claude", found: false },
      gemini: { command: "gemini", found: false },
      apiKeys: { openai: false, anthropic: false },
      ...overrides,
    },
    gateway: {
      url: "ws://127.0.0.1:14567",
      source: "local loopback",
      reachable: false,
    },
    references: {
      docsUrl: "https://docs.nova.ai",
      sourceUrl: "https://github.com/nova/nova",
    },
  };
}

describe("Nova assistant", () => {
  it("parses the first compact JSON command", () => {
    expect(
      parseSystemAgentAssistantPlanText(
        'thinking... {"reply":"Aye aye.","command":"restart gateway"}',
      ),
    ).toEqual({
      reply: "Aye aye.",
      command: "restart gateway",
    });
  });

  it("rejects non-JSON and empty plans but accepts chat-only replies", () => {
    expect(parseSystemAgentAssistantPlanText("I would edit config directly.")).toBeNull();
    expect(parseSystemAgentAssistantPlanText("{}")).toBeNull();
    expect(parseSystemAgentAssistantPlanText('{"reply":"just chatting"}')).toEqual({
      reply: "just chatting",
    });
  });

  it("includes only operational summary context in planner prompts", () => {
    const prompt = buildSystemAgentAssistantUserPrompt({
      input: "fix my setup",
      overview: {
        ...overview({
          codex: { command: "codex", found: true, version: "codex 1.0.0" },
          apiKeys: { openai: true, anthropic: false },
        }),
        config: {
          path: "/tmp/nova.json",
          exists: true,
          valid: true,
          issues: [],
          hash: "hash",
        },
        agents: [
          {
            id: "main",
            name: "Main",
            isDefault: true,
            model: "openai/gpt-5.5",
            workspace: "/tmp/main",
          },
        ],
        defaultAgentId: "main",
        defaultModel: "openai/gpt-5.5",
        references: {
          docsPath: "/tmp/nova/docs",
          docsUrl: "https://docs.nova.ai",
          sourcePath: "/tmp/nova",
          sourceUrl: "https://github.com/nova/nova",
        },
      },
    });

    expect(prompt).toContain("User request: fix my setup");
    expect(prompt).toContain("Default model: openai/gpt-5.5");
    expect(prompt).toContain("id=main, name=Main, workspace=/tmp/main");
    expect(prompt).toContain("OpenAI API key: found");
    expect(prompt).toContain("Nova docs: /tmp/nova/docs");
    expect(prompt).toContain("Nova source: /tmp/nova");
  });

  it("keeps truncated conversation history valid at a UTF-16 boundary", () => {
    const prefix = "a".repeat(499);
    const prompt = buildSystemAgentAssistantUserPrompt({
      input: "continue",
      overview: overview(),
      history: [{ role: "user", text: `${prefix}🎉tail` }],
    });

    expect(prompt.slice(0, prompt.indexOf("User request:"))).toBe(
      `Conversation so far:\nUser: ${prefix}…\n\n`,
    );
  });
});
