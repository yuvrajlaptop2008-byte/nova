// Declares extension points for agent session type augmentation.
export type NovaAgentSessionSkillSourceAugmentation = never;

declare module "nova/plugin-sdk/agent-sessions" {
  interface Skill {
    // Nova relies on the source identifier returned by skill loaders.
    source: string;
  }
}
