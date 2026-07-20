<p align="center">
  <img src="assets/nova-banner.svg" alt="Nova" width="420" />
</p>

# ⭐ Nova — Personal AI Assistant

Nova is a multi-channel AI gateway you run on your own devices. It is a standalone
project forked from Nova and fully disconnected from the upstream repository
and its GitHub organization.

This is a local, independent build. Issues and releases live only at
`https://github.com/yuvrajlaptop2008-byte/nova` (no upstream remote is configured).

## What it does

Nova answers you on the channels you already use, can speak and listen on
macOS/iOS/Android, and renders a live Canvas you control. The Gateway is the
control plane — the product is the assistant.

Supported channels include: WhatsApp, Telegram, Slack, Discord, Google Chat,
Signal, iMessage, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost,
Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, Zalo Personal,
WeChat, QQ, WebChat.

## Setup

Run `nova onboard` in your terminal (rename the binary as needed), or follow the
inherited setup docs in `docs/`. Works with npm, pnpm, or bun.

## License

MIT — see [LICENSE](LICENSE).

> Note: this README was rebranded from the original Nova project. Sections
> below may still reference upstream terminology; the code and repository are
> fully independent.

## Install (recommended)

Runtime: **Node 24.15+ (recommended), Node 22.22.3+, or Node 25.9+**.

```bash
# Cross-platform install (macOS / Linux / Windows via npm or pnpm):
npm install -g nova@latest        # or: pnpm add -g nova@latest
nova onboard --install-daemon
```

Nova Onboard installs the Gateway daemon (launchd/systemd user service) so it stays running.

## Quick start (TL;DR)

Runtime: **Node 24.15+ (recommended), Node 22.22.3+, or Node 25.9+**.

Full beginner guide (auth, pairing, channels): [Getting started](https://docs.nova.dev/start/getting-started)

Recommended daemon mode:

```bash
nova onboard --install-daemon
nova gateway status
```

Foreground/debug mode:

```bash
nova gateway stop
nova gateway --port 18789 --verbose
```

Send a test message or ask the assistant after either startup mode is running:

```bash
# Send a message
nova message send --target +1234567890 --message "Hello from Nova"

# Talk to the assistant (optionally deliver back to any connected channel: WhatsApp/Telegram/Slack/Discord/Google Chat/Signal/iMessage/IRC/Microsoft Teams/Matrix/Feishu/LINE/Mattermost/Nextcloud Talk/Nostr/Synology Chat/Tlon/Twitch/Zalo/Zalo Personal/WeChat/QQ/WebChat)
nova agent --message "Ship checklist" --thinking high
```

Upgrading? [Updating guide](https://docs.nova.dev/install/updating) (and run `nova doctor`).

Models config + CLI: [Models](https://docs.nova.dev/concepts/models). Auth profile rotation + fallbacks: [Model failover](https://docs.nova.dev/concepts/model-failover).

## Security defaults (DM access)

Nova connects to real messaging surfaces. Treat inbound DMs as **untrusted input**.

Full security guide: [Security](https://docs.nova.dev/gateway/security).
Before remote exposure, use the [Gateway exposure runbook](https://docs.nova.dev/gateway/security/exposure-runbook).

Default behavior on Telegram/WhatsApp/Signal/iMessage/Microsoft Teams/Discord/Google Chat/Slack:

- **DM pairing** (`dmPolicy="pairing"` / `channels.discord.dmPolicy="pairing"` / `channels.slack.dmPolicy="pairing"`; legacy: `channels.discord.dm.policy`, `channels.slack.dm.policy`): unknown senders receive a short pairing code and the bot does not process their message.
- Approve with: `nova pairing approve <channel> <code>` (then the sender is added to a local allowlist store).
- Public inbound DMs require an explicit opt-in: set `dmPolicy="open"` and include `"*"` in the channel allowlist (`allowFrom` / `channels.discord.allowFrom` / `channels.slack.allowFrom`; legacy: `channels.discord.dm.allowFrom`, `channels.slack.dm.allowFrom`).

Run `nova doctor` to surface risky/misconfigured DM policies.

## Highlights

- **[Local-first Gateway](https://docs.nova.dev/gateway)** — single control plane for sessions, channels, tools, and events.
- **[Multi-channel inbox](https://docs.nova.dev/channels)** — WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, Zalo Personal, WeChat, QQ, WebChat, macOS, iOS/Android.
- **[Multi-agent routing](https://docs.nova.dev/gateway/configuration)** — route inbound channels/accounts/peers to isolated agents (workspaces + per-agent sessions).
- **[Voice Wake](https://docs.nova.dev/nodes/voicewake) + [Talk Mode](https://docs.nova.dev/nodes/talk)** — wake words on macOS/iOS and continuous voice on Android (ElevenLabs + system TTS fallback).
- **[Live Canvas](https://docs.nova.dev/platforms/mac/canvas)** — agent-driven visual workspace with [A2UI](https://docs.nova.dev/platforms/mac/canvas#canvas-a2ui).
- **[First-class tools](https://docs.nova.dev/tools)** — browser, canvas, nodes, cron, sessions, and Discord/Slack actions.
- **[Companion apps](https://docs.nova.dev/platforms)** — Windows Hub, macOS menu bar app, and iOS/Android [nodes](https://docs.nova.dev/nodes).
- **[Onboarding](https://docs.nova.dev/start/wizard) + [skills](https://docs.nova.dev/tools/skills)** — onboarding-driven setup with bundled/managed/workspace skills.

## Security model (important)

- Default: tools run on the host for the `main` session, so the agent has full access when it is just you.
- Group/channel safety: set `agents.defaults.sandbox.mode: "non-main"` to run non-`main` sessions inside sandboxes. Docker is the default sandbox backend; SSH and OpenShell backends are also available.
- Typical sandbox default: allow `bash`, `process`, `read`, `write`, `edit`, `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`; deny `browser`, `canvas`, `nodes`, `cron`, `discord`, `gateway`.
- Before exposing anything remotely, read [Security](https://docs.nova.dev/gateway/security), [Gateway exposure runbook](https://docs.nova.dev/gateway/security/exposure-runbook), [Sandboxing](https://docs.nova.dev/gateway/sandboxing), and [Configuration](https://docs.nova.dev/gateway/configuration).

## Operator quick refs

- Chat commands: `/status`, `/new`, `/reset`, `/compact`, `/think <level>`, `/verbose on|off`, `/trace on|off`, `/usage off|tokens|full`, `/restart`, `/activation mention|always`
- Session tools: `sessions_list`, `sessions_history`, `sessions_send`
- Skills registry: [ClawHub](https://clawhub.ai)
- Architecture overview: [Architecture](https://docs.nova.dev/concepts/architecture)

## Docs by goal

- New here: [Getting started](https://docs.nova.dev/start/getting-started), [Onboarding](https://docs.nova.dev/start/wizard), [Updating](https://docs.nova.dev/install/updating)
- Channel setup: [Channels index](https://docs.nova.dev/channels), [WhatsApp](https://docs.nova.dev/channels/whatsapp), [Telegram](https://docs.nova.dev/channels/telegram), [Discord](https://docs.nova.dev/channels/discord), [Slack](https://docs.nova.dev/channels/slack)
- Apps + nodes: [Windows Hub](https://docs.nova.dev/platforms/windows), [macOS](https://docs.nova.dev/platforms/macos), [iOS](https://docs.nova.dev/platforms/ios), [Android](https://docs.nova.dev/platforms/android), [Nodes](https://docs.nova.dev/nodes)
- Config + security: [Configuration](https://docs.nova.dev/gateway/configuration), [Security](https://docs.nova.dev/gateway/security), [Exposure runbook](https://docs.nova.dev/gateway/security/exposure-runbook), [Sandboxing](https://docs.nova.dev/gateway/sandboxing)
- Remote + web: [Gateway](https://docs.nova.dev/gateway), [Remote access](https://docs.nova.dev/gateway/remote), [Tailscale](https://docs.nova.dev/gateway/tailscale), [Web surfaces](https://docs.nova.dev/web)
- Tools + automation: [Tools](https://docs.nova.dev/tools), [Skills](https://docs.nova.dev/tools/skills), [Cron jobs](https://docs.nova.dev/automation/cron-jobs), [Webhooks](https://docs.nova.dev/automation/webhook), [Gmail Pub/Sub](https://docs.nova.dev/automation/gmail-pubsub)
- Internals: [Architecture](https://docs.nova.dev/concepts/architecture), [Agent](https://docs.nova.dev/concepts/agent), [Session model](https://docs.nova.dev/concepts/session), [Gateway protocol](https://docs.nova.dev/reference/rpc)
- Troubleshooting: [Channel troubleshooting](https://docs.nova.dev/channels/troubleshooting), [Logging](https://docs.nova.dev/logging), [Docs home](https://docs.nova.dev)

## Apps (optional)

The Gateway alone delivers a great experience. All apps are optional and add extra features.

If you plan to build/run companion apps, follow the platform runbooks below.

### macOS (Nova.app) (optional)

- Menu bar control for the Gateway and health.
- Voice Wake + push-to-talk overlay.
- WebChat + debug tools.
- Remote gateway control over SSH.

Note: signed builds required for macOS permissions to stick across rebuilds (see [macOS Permissions](https://docs.nova.dev/platforms/mac/permissions)).

### iOS node (optional)

- Pairs as a node over the Gateway WebSocket (device pairing).
- Voice trigger forwarding + Canvas surface.
- Controlled via `nova nodes …`.

Runbook: [iOS connect](https://docs.nova.dev/platforms/ios).

### Android node (optional)

- Pairs as a WS node via device pairing (`nova devices ...`).
- Exposes Connect/Chat/Voice tabs plus Canvas, Camera, Screen capture, and Android device command families.
- Runbook: [Android connect](https://docs.nova.dev/platforms/android).

## From source (development)

Use `pnpm` for source checkouts. The repository is a pnpm workspace, and bundled
plugins load from `extensions/*` during development so their package-local
dependencies and your edits are used directly. Plain `npm install` at the repo
root is not a supported source setup.

For the dev loop:

```bash
git clone https://github.com/yuvrajlaptop2008-byte/nova.git
cd nova

pnpm install

# First run only (or after resetting local Nova config/workspace)
pnpm nova setup

# Optional: prebuild Control UI before first startup
pnpm ui:build

# Dev loop (auto-reload on source/config changes)
pnpm gateway:watch
```

If you need a built `dist/` from the checkout (for Node, packaging, or release validation), run:

```bash
pnpm build
pnpm ui:build
```

`pnpm nova setup` writes the local config/workspace needed for `pnpm gateway:watch`. It is safe to re-run, but you normally only need it on first setup or after resetting local state. `pnpm gateway:watch` hands the configured Gateway port from the installed service to a durable tmux pane; run `pnpm nova gateway start` when you want the installed service back. It does not rebuild `dist/control-ui`, so rerun `pnpm ui:build` after `ui/` changes or use `pnpm ui:dev` when iterating on the Control UI. If you want this checkout to run onboarding directly, use `pnpm nova onboard --install-daemon`.

Note: `pnpm nova ...` runs TypeScript directly (via `tsx`). `pnpm build` produces `dist/` for running via Node / the packaged `nova` binary, while `pnpm gateway:watch` rebuilds the runtime on demand during the dev loop.

## Development channels

- **stable**: tagged releases (`vYYYY.M.D` or `vYYYY.M.D-<patch>`), npm dist-tag `latest`.
- **beta**: prerelease tags (`vYYYY.M.D-beta.N`), npm dist-tag `beta` (macOS app may be missing).
- **dev**: moving head of `main`, npm dist-tag `dev` (when published).

Switch channels (git + npm): `nova update --channel stable|beta|dev`.
Details: [Development channels](https://docs.nova.dev/install/development-channels).

## Agent workspace + skills

- Workspace root: `~/.nova/workspace` (configurable via `agents.defaults.workspace`).
- Injected prompt files: `AGENTS.md`, `SOUL.md`, `TOOLS.md`.
- Skills: `~/.nova/workspace/skills/<skill>/SKILL.md`.

## Configuration

Minimal `~/.nova/nova.json` (model + defaults):

```json5
{
  agent: {
    model: "<provider>/<model-id>",
  },
}
```

[Full configuration reference (all keys + examples).](https://docs.nova.dev/gateway/configuration)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yuvrajlaptop2008-byte/nova&type=date&legend=top-left)](https://www.star-history.com/#yuvrajlaptop2008-byte/nova&type=date&legend=top-left)

## Molty

Nova is a personal AI assistant you run on your own devices.
by Peter Steinberger and the community.

- [nova.ai](https://nova.dev)
- [soul.md](https://soul.md)
- [steipete.me](https://steipete.me)
- [@nova](https://x.com/nova)

## Community

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines, maintainers, and how to submit PRs.
Use the [issue chooser](https://github.com/yuvrajlaptop2008-byte/nova/issues/new/choose) for bugs, docs bugs, and feature requests;
ask setup/support questions in [Discord](https://discord.gg/clawd); and report vulnerabilities through [SECURITY.md](SECURITY.md).
PRs should link the relevant issue when possible and follow the [PR template](.github/pull_request_template.md) with problem, impact, and evidence.
AI/vibe-coded PRs welcome! 🤖

## Acknowledgments

Nova is an independent, community-driven project. The gateway, channel plugins,
and agent runtime were built and maintained by the Nova project and its contributors.

This is a standalone project and is not affiliated with, nor derived from, any
upstream OpenClaw organization or repository.

---
