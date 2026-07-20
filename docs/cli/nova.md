---
summary: "CLI reference and security model for the inference-backed Nova setup and repair helper"
read_when:
  - You finished inference setup and want Nova to configure the rest
  - You need to inspect or repair Nova with the local setup agent
  - You are designing or enabling message-channel rescue mode
title: "Nova setup agent"
---

# `nova setup`

Nova ships with a built-in system agent — it speaks as "Nova" — for
local setup, repair, and configuration (formerly called Crestodian). It starts only after the effective default model completes a real turn.
Fresh installs establish inference first; malformed config stays on the
classic doctor path.

## When it starts

Running `nova` with no subcommand routes based on config state:

- Config missing, or exists with no authored settings (empty, or only `$schema`/`meta` keys): starts guided onboarding with live AI verification.
- Config exists but fails validation: starts classic onboarding, which reports the issues and directs you to `nova doctor`.
- Config exists and is valid: opens the normal agent TUI. A reachable
  configured Gateway whose default agent has a model goes directly to that UI
  without onboarding or Nova. Use `/nova` inside the TUI, or run
  `nova setup` directly, to reach Nova later.

Running `nova setup` first live-tests the configured default model. A passing turn starts Nova. An interactive failure opens guided inference setup and hands off to Nova after a candidate passes. One-shot, JSON, and other noninteractive requests fail with instructions to run `nova onboard` when inference is unavailable. `nova --help` and `nova --version` keep their normal fast paths.

Noninteractive bare `nova` (no TTY) exits with a short message instead of printing root help: it points to non-interactive onboarding on a fresh or invalid install, or to `nova agent --local ...` when config is valid.

`nova onboard --modern` remains a compatibility alias for Nova, but uses the same inference gate: working inference opens the chat, interactive failures start guided inference setup, and noninteractive failures exit with onboarding guidance. `nova onboard --classic` opens the full step-by-step wizard.

## What Nova shows

Interactive Nova opens the same TUI shell as `nova tui`, with an Nova chat backend. The startup greeting covers:

- config validity and the default agent
- the verified model Nova is using
- Gateway reachability from the first startup probe
- the next recommended debug action

It does not dump secrets or load plugin CLI commands just to start.

Use `status` for the detailed inventory: config path, docs/source paths, local CLI probes, key/token presence, agents, model, and Gateway details.

Nova uses the same reference discovery as regular agents: in a Git checkout it points at local `docs/` and the source tree; in an npm install it uses bundled docs and links to [https://github.com/nova/nova](https://github.com/nova/nova), with guidance to check source when docs are not enough.

## Examples

```bash
nova
nova setup
nova setup --json
nova setup --message "models"
nova setup --message "validate config"
nova setup --message "setup workspace ~/Projects/work" --yes
nova setup --message "set default model openai/gpt-5.6" --yes
nova onboard --modern
```

Inside the Nova TUI:

```text
status
health
doctor
validate config
setup
setup workspace ~/Projects/work
config set gateway.port 19001
config set-ref gateway.auth.token env NOVA_GATEWAY_TOKEN
gateway status
restart gateway
agents
create agent work workspace ~/Projects/work
models
configure model provider
set default model openai/gpt-5.6
channels
channel info slack
connect slack
open channel wizard for slack
plugins list
plugins search slack
plugin install clawhub:nova-codex-app-server
talk to work agent
talk to agent for ~/Projects/work
audit
quit
```

## Operations and approval

Nova uses typed operations instead of editing config ad hoc.

Read-only operations run immediately: show overview, list agents, list installed plugins, search ClawHub plugins, show model/backend status, run status/health checks, check Gateway reachability, run doctor without interactive fixes, validate config, show the audit-log path.

Starting guided channel setup (`connect telegram`) also runs immediately. Its wizard collects explicit answers and owns the resulting writes.

Persistent operations require conversational approval (or `--yes` for a direct command): write config, `config set`, `config set-ref`, setup/onboarding bootstrap, change the default model, start/stop/restart the Gateway, create agents, and install plugins.

Doctor repairs are unavailable inside Nova because they can rewrite the provider, authentication, or default-agent inference route powering the session. Exit Nova and run `nova doctor --fix` in a terminal. Read-only `doctor` remains available inside Nova.

New agents inherit the live-verified default inference route. The agent ids `nova` and `crestodian` are reserved for the system agent and cannot be created as normal agents. The retired id remains blocked so an old config cannot claim it.

`config set` and `config set-ref` can change any setting a user can change,
with a short human-only denylist: `$include`, `auth.*`, `env.*`, `models.*`,
and `secrets.*` stay refused because they carry credential material,
alternate-config inclusion, or the provider/catalog definitions that feed
inference routing. Inference routing itself is also protected: default model
routes (`agents.defaults` model/params/runtime fields) and the routing fields
of whichever agent backs the active default route are refused, as are agent
identity/topology fields (`id`, `agentDir`, `default`). Routing fields for
other agents remain writable behind approval. Gateway and channel auth remain
normal config surfaces. Use `set default model <provider/model>` for an
already configured route; it live-tests the route before saving it. To
configure or repair provider/auth access, exit Nova and run
`nova onboard`.

`plugins.entries.<id>.*` writes (enable/disable/config of installed plugins)
are allowed unless that plugin backs the active inference route. Plugin
install sources and load policy keep their trust boundary in the typed
plugin-install workflow. Plugin uninstall of the route-backing plugin is
refused for the same reason; exit Nova and run
`nova plugins uninstall <id>` from a terminal.

Approval is given in your own words: unambiguous replies ("yes", "sure", "go ahead", "not now") resolve from a closed deterministic list. When the configured route supports a separate completion call, other replies can be classified from only your message and the pending proposal — never by the conversation model itself, which cannot self-approve. Unclassified or ambiguous replies keep the proposal pending and the conversation asks again.

### Change history

The Ask Nova page can show recent applied system-agent operations, Doctor
migrations, Settings and CLI config writes, and manual edits to
`nova.json`. The config journal detects external edits while the Gateway
is watching, during an Nova-owned write, or at the next startup after an
offline edit.

History is stored in the `diagnostic_events` table of the shared
`~/.nova/state/nova.sqlite` database, under the `system-agent-audit`
and `config-audit` scopes. Each scope retains its latest 50,000 records.
Discovery and read-only operations are not included. Secrets never appear in
change history; config journal records contain changed paths rather than config
values, and value comparison uses protected fingerprints.

Channel setup can run as a hosted conversation until it reaches a secret. The
local Nova TUI does not accept sensitive wizard answers because terminal
chat input is visible. It offers `open channel wizard` immediately, carrying
the selected channel into the masked terminal wizard; you can also run
`nova channels add --channel <channel>` later.

### Switching to masked channel setup

The local chat can hand control to the masked channel wizard:

```text
open channel wizard for slack
channel info slack
```

`open channel wizard for <channel>` opens masked channel setup after the chat
TUI closes. Use `channel info <channel>` first for the channel label, setup
state, prerequisites summary, and docs link.

Nova never changes provider/auth access from inside its own session: the
session already depends on that inference route. For model-provider setup or
repair, `configure model provider` returns exit/onboarding guidance without
starting a wizard or writing config. Exit Nova and run `nova
onboard`; onboarding stages the credentials and saves only a route that
completes a real live turn. Start Nova again after onboarding succeeds.

## Setup bootstrap

`setup` configures the remaining workspace and Gateway state after guided onboarding has already established inference. It writes only through typed config operations and asks for approval first.

```text
setup
setup workspace ~/Projects/work
```

`setup` preserves the verified effective model. It does not configure or
replace inference.

If inference is missing or its live check fails, leave Nova and run `nova onboard`. Guided onboarding detects configured models, API keys, and authenticated local CLIs, asks each candidate for a real reply, and persists only a passing route. Nova starts immediately after that boundary and can then configure the workspace, Gateway, channels, agents, plugins, and other optional features.

The macOS app skips this ladder entirely when it reaches a configured Gateway
whose default agent already has a configured model; it opens the normal agent
UI.
For a fresh or incomplete Gateway, the app drives the inference ladder through
the `nova.setup.detect` and `nova.setup.activate` Gateway methods:
detect lists every candidate backend it finds, activate live-tests one
candidate (a real "reply with OK" completion), and only persists the model,
credential, and provider/runtime state needed for that route after the test passes. Workspace and Gateway defaults remain for Nova. A failing candidate
never changes config; the app automatically walks down the ladder and finally
offers a manual key/token step populated from the Gateway's active
text-inference provider plugins. The selected provider owns its starter model
and config, and the credential is verified the same way before it is saved.

Codex supervision and other optional plugin features stay outside this
inference activation transaction. Configure them only after inference is
working and Nova has started; existing plugin policy and explicit
supervision opt-outs remain untouched during inference setup.

## AI conversation

Interactive Nova's free-form conversation runs through the same agent loop as regular Nova agents, restricted to one ring-zero Nova authority tool, `nova`, that wraps the typed operations. Read actions run freely, mutations require your conversational approval for that exact operation (see Operations and approval), and every applied write is audited and re-validated. The agent session persists, so Nova has real multi-turn memory. If the verified inference route later stops working, return to `nova onboard` and repair it before continuing.

The host does not parse natural-language requests into operations. Free-form
messages — including command-looking text and questions such as "why did my
gateway stop?" — go to the AI, which can map the request to a typed operation
through the `nova` tool.

When a mutation is pending, only unambiguous approval or decline phrases from a
closed list are resolved without inference. Ambiguous consent goes to a
separate configured completion call and otherwise fails closed. Structured
wizard fields and exact host navigation are UI controls, not natural-language
operation parsing. One secret-hygiene exception is especially important: an
exact `config set` on a sensitive path (tokens, keys, passwords) never reaches
a model. The host creates a redacted proposal, and the value is masked in the
AI-visible history. Prefer `config set-ref <path> env <ENV_VAR>` for secrets.

Message-channel rescue mode never uses the model-assisted planner. Remote rescue stays deterministic so a broken or compromised normal agent path cannot be used as a config editor.

### CLI harness trust model

Embedded runtimes and the Codex app-server harness enforce the ring-zero
restriction directly: the run carries an Nova tool allow-list with only
the `nova` tool. For Codex, Nova also disables environments, native
execution, multi-agent, goal, app/plugin, skill/MCP, web-search, and
`request_user_input` surfaces for that run. Codex still injects its inert native `update_plan`
utility; it can update the model's temporary checklist but cannot write files
or Nova configuration. CLI harnesses do not consume Nova's allow-list,
so Nova admits only backends whose own tool-selection contract can prove
the same restriction:

- Selectable backends, including Claude Code, launch with an empty native-tool
  selection and one MCP tool, `nova`. Claude's generated MCP config is
  applied with `--strict-mcp-config`, so no other MCP servers are loaded.
- Backends that declare no native tools receive the same dedicated Nova
  MCP server.
- Always-on or unknown native-tool backends fail closed before inference; they
  cannot host an Nova session.

Only Nova sessions get the nova MCP server; normal agent runs
never see this tool. Selectable/no-native CLI backends and API-key models
therefore enforce the literal single-tool loop. Codex app-server models enforce
a single Nova authority tool plus the inert native planning utility. In all
three cases, setup writes remain confined to Nova's audited approval
contract.

Gemini CLI remains available for normal agents, but it cannot enforce the
tool-free probe required by the inference gate, so it cannot host Nova.

## Switching to an agent

Use a natural-language selector to leave Nova and open the normal TUI:

```text
talk to agent
talk to work agent
switch to main agent
```

`nova tui`, `nova chat`, and `nova terminal` open the normal agent TUI directly; they do not start Nova. After switching into the normal TUI, `/nova` returns to Nova, optionally with a follow-up request:

```text
/nova
/nova restart gateway
```

## Message rescue mode

Message rescue mode is the message-channel entrypoint for Nova: use it when your normal agent is dead but a trusted channel (for example WhatsApp) still receives commands.

This is a deterministic emergency command handler, not the conversational
Nova agent. It does not bootstrap a fresh setup or relax the inference
gate for Nova chat.

Supported command: `/nova <request>`. Rescue accepts the exact typed command grammar only — natural language is rejected with a hint, never guessed into an operation, and no model is ever consulted.

```text
You, in a trusted owner DM: /nova status
Nova: Nova rescue mode. Gateway reachable: no. Config valid: no.
You: /nova restart gateway
Nova: Plan: restart the Gateway. Reply /nova yes to apply.
You: /nova yes
Nova: Applied. Audit entry written.
```

Agent creation can also be queued locally or via rescue:

```text
create agent work workspace ~/Projects/work model openai/gpt-5.6-sol
/nova create agent work workspace ~/Projects/work
```

Agent creation may name only the current live-verified default model. Omit the
model to inherit that route.

Remote rescue is an admin surface and must be treated like remote config repair, not normal chat.

Security contract for remote rescue:

- Disabled when sandboxing is active for the agent/session; Nova refuses remote rescue and points to local CLI repair.
- Default effective state is `auto`: allow remote rescue only in trusted YOLO operation, where the runtime already has unsandboxed local authority (`tools.exec.security` resolves to `full` and `tools.exec.ask` resolves to `off`, with sandbox mode `off`).
- Requires an explicit owner identity; no wildcard sender rules, open group policy, unauthenticated webhooks, or anonymous channels.
- Owner DMs only by default; group/channel rescue needs explicit opt-in.
- Plugin search and list are read-only. Plugin install is always local-only (blocked in rescue, even when otherwise enabled) because it downloads executable code. Plugin uninstall is refused in both local Nova and rescue; run `nova plugins uninstall <id>` from a terminal.
- Remote rescue cannot open the local TUI or switch into an interactive agent session; use local `nova` for agent handoff.
- Persistent writes still require approval, even in rescue mode.
- Pending approvals are one-use. Any newer rescue command for the same account, channel, and sender revokes the older plan; failed execution also consumes approval, so resend the command to retry.
- Every applied rescue operation is audited. Message-channel rescue records channel, account, sender, and source-address metadata; config-mutating operations also record config hashes before and after.
- Secrets are never echoed. SecretRef inspection reports availability, not values.
- If the Gateway is alive, rescue prefers Gateway typed operations; if it is dead, rescue uses only the minimal local repair surface that does not depend on the normal agent loop.

Config shape:

```jsonc
{
  "systemAgent": {
    "rescue": {
      "enabled": "auto",
      "ownerDmOnly": true,
      "pendingTtlMinutes": 15,
    },
  },
}
```

- `enabled`: `"auto"` (default) allows rescue only when the effective runtime is YOLO and sandboxing is off; `false` never allows message-channel rescue; `true` explicitly allows rescue when owner/channel checks pass (still subject to the sandboxing denial).
- `ownerDmOnly`: restrict rescue to owner direct messages. Default `true`.
- `pendingTtlMinutes`: how long a pending rescue write stays open for `/nova yes` approval before expiring. Default `15`.

`nova doctor --fix` migrates the legacy `crestodian` config block to
`systemAgent`. Runtime reads only the canonical block.

Remote rescue is covered by the Docker lane:

```bash
pnpm test:docker:system-agent-rescue
```

An opt-in live channel command-surface smoke checks `/nova status` plus a persistent approval roundtrip through the rescue handler:

```bash
pnpm test:live:system-agent-rescue-channel
```

Inference-gated packaged one-shot setup is covered by:

```bash
pnpm test:docker:system-agent-first-run
```

That packaged-CLI lane starts with an empty state dir and proves Nova
fails closed without inference. It then tests and activates fake Claude through
the packaged activation module. Only afterward does a fuzzy request reach the
planner and resolve to typed setup, followed by one-shot commands that create an
additional agent, configure Discord through a plugin enablement plus token
SecretRef, validate config, and check the audit log. This lane is supporting
gate/operation evidence; it does not exercise interactive onboarding or the
Nova agent/tool/approval conversation. The QA Lab scenario below redirects
to the same Docker lane:

```bash
pnpm nova qa suite --scenario system-agent-ring-zero-setup
```

## Related

- [CLI reference](/cli)
- [Doctor](/cli/doctor)
- [TUI](/cli/tui)
- [Sandbox](/cli/sandbox)
- [Security](/cli/security)
