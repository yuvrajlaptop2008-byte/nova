/**
 * Static identity for names that select core agent factory families before assembly.
 */

export type CoreToolFactoryFamily = "base-coding" | "shell" | "nova";

type CoreToolFactoryDescriptor = {
  name: string;
  family: CoreToolFactoryFamily;
};

const CORE_TOOL_FACTORY_DESCRIPTORS = [
  { name: "edit", family: "base-coding" },
  { name: "read", family: "base-coding" },
  { name: "write", family: "base-coding" },
  { name: "apply_patch", family: "shell" },
  { name: "exec", family: "shell" },
  { name: "process", family: "shell" },
  { name: "agents_list", family: "nova" },
  // Static factory identity only; runtime and tools.catalog apply the Swarm config gate.
  { name: "agents_wait", family: "nova" },
  { name: "ask_user", family: "nova" },
  { name: "nova", family: "nova" },
  { name: "computer", family: "nova" },
  { name: "conversations_list", family: "nova" },
  { name: "conversations_send", family: "nova" },
  { name: "conversations_turn", family: "nova" },
  { name: "cron", family: "nova" },
  { name: "dashboard", family: "nova" },
  { name: "gateway", family: "nova" },
  { name: "get_goal", family: "nova" },
  { name: "heartbeat_respond", family: "nova" },
  { name: "image", family: "nova" },
  { name: "image_generate", family: "nova" },
  { name: "message", family: "nova" },
  { name: "music_generate", family: "nova" },
  { name: "nodes", family: "nova" },
  { name: "pdf", family: "nova" },
  { name: "session_status", family: "nova" },
  { name: "show_widget", family: "nova" },
  { name: "sessions", family: "nova" },
  { name: "sessions_history", family: "nova" },
  { name: "sessions_list", family: "nova" },
  { name: "sessions_search", family: "nova" },
  { name: "sessions_send", family: "nova" },
  { name: "sessions_spawn", family: "nova" },
  { name: "sessions_yield", family: "nova" },
  { name: "structured_output", family: "nova" },
  { name: "skill_workshop", family: "nova" },
  { name: "spawn_task", family: "nova" },
  { name: "create_goal", family: "nova" },
  { name: "subagents", family: "nova" },
  { name: "terminal", family: "nova" },
  { name: "transcripts", family: "nova" },
  { name: "tts", family: "nova" },
  { name: "update_goal", family: "nova" },
  { name: "update_plan", family: "nova" },
  { name: "dismiss_task", family: "nova" },
  { name: "video_generate", family: "nova" },
  { name: "web_fetch", family: "nova" },
  { name: "web_search", family: "nova" },
] as const satisfies readonly CoreToolFactoryDescriptor[];

const CORE_TOOL_FACTORY_FAMILY_BY_NAME = new Map<string, CoreToolFactoryFamily>(
  CORE_TOOL_FACTORY_DESCRIPTORS.map(({ name, family }) => [name, family]),
);

export type NovaCodingToolConstructionPlan = {
  includeBaseCodingTools: boolean;
  includeShellTools: boolean;
  includeChannelTools: boolean;
  includeNovaTools: boolean;
  includePluginTools: boolean;
};

export function resolveCoreToolFactoryFamily(name: string): CoreToolFactoryFamily | undefined {
  return CORE_TOOL_FACTORY_FAMILY_BY_NAME.get(name);
}
