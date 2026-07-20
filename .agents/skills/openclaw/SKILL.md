---
name: openclaw
description: "Use when the user asks for OpenClaw-style multi-channel AI assistant behavior, gateway/agent patterns, channel plugins, exec approval, or wants Nova to mimic a capable self-hosted assistant gateway."
metadata:
  emoji: "🦞"
---

# OpenClaw — capability patterns (carried into Nova)

OpenClaw was a self-hosted, multi-channel AI assistant gateway: one agent core
that talks to users across many chat platforms, runs local commands under
approval, and extends itself with plugins and skills. Nova inherits that shape.
This skill is a **knowledge + pattern** reference so you can deliver OpenClaw-style
behavior on Nova without re-deriving it.

It documents capabilities and the Nova surface that implements each one. No
upstream code or text is copied — this is a synthesized mapping.

## Core capabilities → Nova surface

- **Multi-channel gateway**: one runtime, many channels (Telegram, Discord,
  Slack, iMessage, WhatsApp, Google Chat, MS Teams, web UI). In Nova:
  `extensions/*` (e.g. `extensions/telegram`, `extensions/discord`) and the
  channel plugin SDK in `src/plugin-sdk/`.
- **Channel plugins**: each channel is a bundled plugin with inbound parsing,
  outbound rendering, and approval flows. In Nova: `src/plugins/`, `src/plugin-sdk/`.
- **Exec approval**: the agent can request to run a local command; the user
  approves/denies via an interactive prompt or a paired device. In Nova:
  `src/infra/exec-approvals*.ts`, `src/infra/exec-authorization*.ts`.
- **Provider-agnostic LLM**: plug any OpenAI-compatible or first-party provider;
  route by model; stream; handle tool calls. In Nova: `src/llm/`,
  `src/model-catalog/`, `src/plugins/*-provider*`.
- **Skills & Skill Workshop**: reusable, reviewed instruction bundles the agent
  can propose from experience. In Nova: `src/skills/workshop/`, `.agents/skills/`,
  the `skill_workshop` tool, and the `nova-learn` skill for the learning loop.
- **Memory**: durable, per-user context the agent recalls across sessions. In
  Nova: `memory-core`, `active-memory`, `src/state/`.
- **Self-hosted, own-device**: runs locally; config under `~/.nova`; no cloud
  lock-in. In Nova: `src/config/`, `scripts/install.sh` (`nova` install command).
- **Automation**: scheduled tasks, cron, polling, reminders. In Nova:
  `src/tasks/`, `.github` workflows for CI.

## How to deliver OpenClaw-style results on Nova

1. Identify the channel the user is on and the channel plugin that serves it.
2. Use the channel plugin SDK for inbound/outbound instead of hand-rolling HTTP.
3. For any local action, route through exec approval — never run without the
   user's gate.
4. Prefer provider-agnostic calls so the user can swap models freely.
5. When a workflow repeats, capture it with `nova-learn` → `skill_workshop`
   proposal rather than answering the same way forever.

## Guardrails

- Respect the human-in-the-loop gate for exec and for applying skills.
- Never claim an upstream OpenClaw identity; Nova is independent.
- Keep provider keys in the secrets store; never echo them.

## Compose with other skills

- `$nova-learn` — turn repeated OpenClaw-style requests into Nova skills.
- `$nova-pr-maintainer`, `$gitcrawl` — upstream/issue evidence when relevant.
