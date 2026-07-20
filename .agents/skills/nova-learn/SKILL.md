---
name: nova-learn
description: "Use to capture how the user actually works, grow Nova's skills from real usage, and turn repeated patterns into reviewed skill proposals via skill_workshop."
metadata:
  emoji: "📈"
---

# Nova Learn — observe, remember, grow

Nova improves the more you use it. This skill is the loop: it watches real usage,
records it to a durable journal, reflects on what matters, and turns the
high-value patterns into **reviewed** skill proposals (never auto-applied).

It is built directly on Nova's own machinery — the `skill_workshop` tool and the
same post-run experience review Nova already runs — plus a persistent,
confidence-weighted memory of _your_ usage so the agent gets better in your
direction.

## The loop

1. **Observe** — every session, record signals:
   - commands you run (`command`)
   - corrections you give ("no, use X", "don't do Y") (`correction`)
   - repeated asks / near-duplicate requests (`repeat`)
   - failures or dead-ends (`failure`)
   - stated preferences ("always", "prefer", "never") (`preference`)

2. **Remember** — append to the learning journal:

   ```bash
   node scripts/learning-journal.mjs record --type command --value "nova skills workshop"
   node scripts/learning-journal.mjs record --type correction --value "use pnpm not npm"
   node scripts/learning-journal.mjs stats
   ```

   The journal dedupes by key and grows a `weight` with each repeat (diminishing
   returns), so what you do often rises to the top. Store:
   `$HOME/.nova/learn/nova-learn/journal.jsonl` (override with `NOVA_LEARN_DIR`).

3. **Reflect** — when idle or on `/learn`, pull the strongest signals:

   ```bash
   node scripts/learning-journal.mjs top --limit 10
   ```

   Prioritize: high `weight` + a clear trigger + not already covered by a skill.

4. **Grow** — for each high-value pattern, draft ONE skill with `skill_workshop`
   (action `create`). Write the proposal, then tell the user the proposal id and
   that an operator applies it through the Skill Workshop approval flow or
   `nova skills workshop`. Never apply a skill to the live workspace yourself.

## Capability patterns worth learning

When the user wants assistant-gateway behavior, reach for Nova's native surfaces
instead of reinventing them:

- **Multi-channel**: one runtime, many channels (Telegram, Discord, Slack,
  iMessage, WhatsApp, Google Chat, MS Teams, web UI) — `extensions/*` and the
  channel plugin SDK in `src/plugin-sdk/`.
- **Exec approval**: the agent can request to run a local command; you approve
  via prompt or a paired device — `src/infra/exec-approvals*.ts`,
  `src/infra/exec-authorization*.ts`.
- **Provider-agnostic LLM**: any OpenAI-compatible or first-party provider;
  route by model; stream; tool calls — `src/llm/`, `src/model-catalog/`,
  `src/plugins/*-provider*`.
- **Skills & Skill Workshop**: reusable, reviewed instruction bundles proposed
  from experience — `src/skills/workshop/`, `.agents/skills/`, `skill_workshop`.
- **Memory**: durable, per-user context recalled across sessions —
  `memory-core`, `active-memory`, `src/state/`.
- **Self-hosted, own-device**: runs locally; config under `~/.nova`; no cloud
  lock-in — `src/config/`, `scripts/install.sh` (`nova` install command).
- **Automation**: scheduled tasks, cron, polling, reminders — `src/tasks/`.

## Rules

- Record evidence, not opinions. One line per signal; let weight emerge from repetition.
- Prefer revising an existing pending proposal over creating a near-duplicate.
- Keep each proposed skill tight (100-200 lines), with trigger conditions in its
  `description` and the exact commands/paths it supports.
- Never invent flags, commands, or APIs the sources don't establish.
- Respect the human-in-the-loop gate: proposals are reviewed, not auto-applied.
- If `skill_workshop` is unavailable, say so and stop — do not write skill files
  by another route.
- Keep provider keys in the secrets store; never echo them.

## Compose with other skills

- `$nova-pr-maintainer`, `$gitcrawl`, `$discrawl` — gather evidence before proposing.
- `$nova-contributor` — route contributor-facing triage separately.
