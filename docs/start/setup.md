---
summary: "Advanced setup and development workflows for Nova"
read_when:
  - Setting up a new machine
  - You want "latest + greatest" without breaking your personal setup
title: "Setup"
---

<Note>
If you are setting up for the first time, start with [Getting Started](/start/getting-started).
For onboarding details, see [Onboarding (CLI)](/start/wizard).
</Note>

## TL;DR

Pick a setup workflow based on how often you want updates and whether you want to run the Gateway yourself:

- **Tailoring lives outside the repo:** keep your config and workspace in `~/.nova/nova.json` and `~/.nova/workspace/` so repo updates don't touch them.
- **Stable workflow (recommended for most):** install the macOS app and let it run the bundled Gateway.
- **Bleeding edge workflow (dev):** run the Gateway yourself via `pnpm gateway:watch`, then let the macOS app attach in Local mode.

## Prereqs (from source)

- Node 24.15+ recommended (Node 22 LTS, currently `22.22.3+`, still supported)
- `pnpm` required for source checkouts. Nova loads bundled plugins from the
  `extensions/*` pnpm workspace packages in dev mode, so root `npm install` does
  not prepare the full source tree.
- Docker (optional; only for containerized setup/e2e - see [Docker](/install/docker))

## Tailoring strategy (so updates do not hurt)

If you want "100% tailored to me" _and_ easy updates, keep your customization in:

- **Config:** `~/.nova/nova.json` (JSON/JSON5-ish)
- **Workspace:** `~/.nova/workspace` (skills, prompts, memories; make it a private git repo)

Bootstrap the config/workspace folders once, without running the full onboarding wizard:

```bash
nova setup --baseline
```

No global install yet? Run it from this repo instead:

```bash
pnpm nova setup --baseline
```

(Bare `nova setup`, without `--baseline`, is an alias for `nova onboard` and runs the full interactive wizard.)

## Run the Gateway from this repo

After `pnpm build`, you can run the packaged CLI directly:

```bash
node nova.mjs gateway --port 18789 --verbose
```

## Stable workflow (macOS app first)

1. Install + launch **Nova.app** (menu bar).
2. Complete the onboarding/permissions checklist (TCC prompts).
3. Ensure Gateway is **Local** and running (the app manages it).
4. Link surfaces (example: WhatsApp):

```bash
nova channels login
```

5. Sanity check:

```bash
nova health
```

If onboarding is not available in your build:

- Run `nova setup`, then `nova channels login`, then start the Gateway manually (`nova gateway`).

## Bleeding edge workflow (Gateway in a terminal)

Goal: work on the TypeScript Gateway, get hot reload, keep the macOS app UI attached.

### 0) (Optional) Run the macOS app from source too

If you also want the macOS app on the bleeding edge:

```bash
./scripts/restart-mac.sh
```

### 1) Start the dev Gateway

```bash
pnpm install
# First run only (or after resetting local Nova config/workspace)
pnpm nova setup
pnpm gateway:watch
```

`gateway:watch` starts or restarts the Gateway watch process in a named tmux
session (`nova-gateway-watch-main`) and auto-attaches from interactive
terminals. Non-interactive shells stay detached and print
`tmux attach -t nova-gateway-watch-main`; use
`NOVA_GATEWAY_WATCH_ATTACH=0 pnpm gateway:watch` to keep an interactive run
detached, or `pnpm gateway:watch:raw` for foreground watch mode. The watcher
stops the active profile's installed Gateway service before taking over its
configured/default port, preventing the service supervisor from replacing the
source process. The service stays installed; run `pnpm nova gateway start`
when you finish watching. The tmux pane remains available after startup failure
so another terminal or agent can attach or capture its logs. The watcher
reloads on relevant source, config, and bundled-plugin metadata changes. If the
watched Gateway exits during startup, `gateway:watch` runs
`nova doctor --fix --non-interactive` once and retries; set
`NOVA_GATEWAY_WATCH_AUTO_DOCTOR=0` to disable that dev-only repair pass.
`pnpm gateway:watch` does not rebuild `dist/control-ui`, so rerun `pnpm ui:build` after `ui/` changes or use `pnpm ui:dev` while developing the Control UI.

### 2) Point the macOS app at your running Gateway

In **Nova.app**:

- Connection Mode: **Local**
  The app will attach to the running gateway on the configured port.

### 3) Verify

- In-app Gateway status should read **"Using existing gateway …"**
- Or via CLI:

```bash
nova health
```

### Common footguns

- **Wrong port:** Gateway WS defaults to `ws://127.0.0.1:18789`; keep app + CLI on the same port.
- **Where state lives:**
  - Channel/provider state: `~/.nova/credentials/`
  - Model auth profiles: `~/.nova/agents/<agentId>/agent/auth-profiles.json`
  - Sessions and transcripts: `~/.nova/agents/<agentId>/agent/nova-agent.sqlite`
  - Legacy/archive session artifacts: `~/.nova/agents/<agentId>/sessions/`
  - Logs: `/tmp/nova/`

## Credential storage map

Use this when debugging auth or deciding what to back up:

- **WhatsApp**: `~/.nova/credentials/whatsapp/<accountId>/creds.json`
- **Telegram bot token**: config/env or `channels.telegram.tokenFile` (regular file only; symlinks rejected)
- **Discord bot token**: config/env or SecretRef (env/file/exec providers)
- **Slack tokens**: config/env (`channels.slack.*`)
- **Pairing allowlists**:
  - `~/.nova/credentials/<channel>-allowFrom.json` (default account)
  - `~/.nova/credentials/<channel>-<accountId>-allowFrom.json` (non-default accounts)
- **Model auth profiles**: `~/.nova/agents/<agentId>/agent/auth-profiles.json`
- **File-backed secrets payload (optional)**: `~/.nova/secrets.json`
- **Legacy OAuth import**: `~/.nova/credentials/oauth.json`
  More detail: [Security](/gateway/security#credential-storage-map).

## Updating (without wrecking your setup)

- Keep `~/.nova/workspace` and `~/.nova/` as "your stuff"; don't put personal prompts/config into the `nova` repo.
- Updating source: `git pull` + `pnpm install` + keep using `pnpm gateway:watch`.

## Linux (systemd user service)

Linux installs use a systemd **user** service. By default, systemd stops user
services on logout/idle, which kills the Gateway. Onboarding attempts to enable
lingering for you (may prompt for sudo). If it's still off, run:

```bash
sudo loginctl enable-linger $USER
```

For always-on or multi-user servers, consider a **system** service instead of a
user service (no lingering needed). See [Gateway runbook](/gateway) for the systemd notes.

## Related docs

- [Gateway runbook](/gateway) (flags, supervision, ports)
- [Gateway configuration](/gateway/configuration) (config schema + examples)
- [Discord](/channels/discord) and [Telegram](/channels/telegram) (reply tags + replyToMode settings)
- [Nova assistant setup](/start/nova)
- [macOS app](/platforms/macos) (gateway lifecycle)
