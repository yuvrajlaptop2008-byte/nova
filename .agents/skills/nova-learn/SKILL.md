---
name: nova-learn
description: "Use to capture how the user actually works, grow Nova's skills from real usage, and turn repeated patterns into reviewed skill proposals via skill_workshop."
metadata:
  emoji: "📈"
---

# Nova Learn — observe, remember, grow

Nova learns from how you use it. This skill is the loop: it watches real usage,
records it to a persistent journal, reflects on what matters, and turns the
high-value patterns into **reviewed** skill proposals (never auto-applied).

It is built on Nova's real machinery: the `skill_workshop` tool and the same
post-run experience review Nova already runs. This skill adds the missing piece —
a durable, confidence-weighted memory of _your_ usage so the agent improves in
your direction, the more you use it.

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
   returns), so what you do often rises to the top. Store lives at
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

## Rules

- Record evidence, not opinions. One line per signal; let weight emerge from repetition.
- Prefer revising an existing pending proposal over creating a near-duplicate.
- Keep each proposed skill tight (100-200 lines), with trigger conditions in its
  `description` and the exact commands/paths it supports.
- Never invent flags, commands, or APIs the sources don't establish.
- Respect the human-in-the-loop gate: proposals are reviewed, not auto-applied.
- If `skill_workshop` is unavailable, say so and stop — do not write skill files
  by another route.

## Compose with other skills

- `$nova-pr-maintainer`, `$gitcrawl`, `$discrawl` — gather evidence before proposing.
- `$nova-contributor` — route contributor-facing triage separately.
