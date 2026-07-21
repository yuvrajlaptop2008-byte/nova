---
title: "Nova Systems Reference"
description: "Comprehensive overview of Nova's architecture, channels, providers, skills, tools, and configuration systems."
---

# Nova Systems Reference

This page documents Nova's core architectural components — the systems that enable personal AI agents to run on your own devices and interact across any chat platform.

## Heritage

Nova was created by fusing [OpenClaw](https://openclaw.ai) (the open-source multi-channel AI agent harness) with Hermes Agent (the extensible agent framework). OpenClaw pioneered the channel-gateway pattern for personal AI assistants. Nova inherits that foundation and evolves it.

Key OpenClaw capabilities now part of Nova:

- Multi-channel gateway that relays messages across Telegram, Discord, WhatsApp, iMessage, Slack, Matrix, Microsoft Teams, Signal, Zalo, and more
- Provider-agnostic LLM integration with pluggable model routing
- Skill-based extensibility system (workshop, proposal, approval workflow)
- Durable memory core with familiarity counters (pet mechanics)
- Exec approval system for safe tool execution

## Core Architecture

### Gateway & Channels

The gateway is Nova's central relay. It manages:

- **Channel connections**: Each chat platform (Telegram, Discord, etc.) runs as an isolated subprocess with its own lifecycle
- **Message routing**: Inbound messages flow through the gateway to agents; agent responses route back to originating channels
- **Pairing flow**: Secure one-time setup via QR/scannable codes or terminal pairing commands

**Channels available**:

- `telegram` — Bot API with threaded topics support
- `discord` — Bot gateway with slash commands
- `whatsapp` — Multi-device pairing via WhatsApp Web
- `slack` — Bot tokens with channel/user mapping
- `matrix` — Homeserver integration
- `imessage` — macOS native messaging (Darwin only)
- `teams` — Microsoft Teams connector
- `signal` — Signal CLI integration
- `zalo` — Zalo messenger support
- `google-chat` — Google Chat bot integration

### Providers

Nova integrates with 60+ LLM providers through a unified interface:

- **OpenRouter** — Unified API for 100+ models
- **Anthropic** — Claude models with thinking budgets
- **OpenAI** — GPT-4, o-series, embeddings
- **Groq** — Fast inference for open models
- **Ollama** — Local model serving
- **Vertex AI** — Google Cloud models
- **Bedrock** — AWS model access
- **And more**: DeepSeek, Mistral, Gemini, etc.

Each provider supports streaming, tool calling, image understanding (where applicable), and configurable timeouts.

### Skills

Skills are Nova's extension mechanism. Every capability (from calendar integration to code review) lives in a skill under `.agents/skills/`.

Skills include:

- **System skills**: `nova-config`, `nova-doctor`, `nova-learn`
- **Productivity**: Calendar, email (Gmail, Outlook), Drive, Notion, Airtable
- **Development**: Git, GitHub, code review, PR workflow
- **Research**: ArXiv, Polymarket, blog monitoring
- **Media**: YouTube transcripts, audio generation, GIF search

The **Skill Workshop** enables:

- `/learn` command to capture usage patterns
- Experience review after runs (idle trigger)
- Human-in-the-loop skill proposals via `skill_workshop`

### Tools

Core agent tools include:

- `shell` — Command execution with approval required for destructive ops
- `read_file`/`write_file`/`patch` — Filesystem access
- `browser` — Headless Chromium for web interaction
- `web_search` — Search aggregation across providers
- `search_files` — Codebase search (ripgrep-backed)
- `vision_analyze` — Image understanding
- `memory` — Durable fact storage across sessions

### Memory System

Nova persists knowledge across conversations:

- **Facts**: Durable entries stored in `memory.md` (injected each turn)
- **User profile**: Preferences, identity, constraints (`USER.md`)
- **Session history**: Transcripts and context available via search
- **Familiarity counters**: Track user interaction patterns

### Plugins

Plugins extend Nova with new channels, tools, or providers:

- Channel plugins: Add new messengers
- Tool plugins: Add capability APIs
- Provider plugins: Add model endpoints

Plugins install via:

```
nova plugins install <plugin-id>
```

## Configuration

### Quick Setup

```bash
# Install
curl -fsSL https://nova.run/install.sh | bash

# Pair a channel ( example: Telegram)
nova channel telegram connect

# Configure a provider
nova provider openai key
```

### Key Paths

- `~/.nova/config` — Configuration files
- `~/.nova/db` — Channel databases, gateway state
- `~/.nova/plugins` — Installed plugins
- `~/.nova/transcripts` — Session history
- `~/nova-state` or `~/.nova/workspace` — Agent workspace (configurable)

## Security Model

- **Exec approval**: Destructive filesystem and shell operations require explicit approval
- **AllowFrom**: Channel-level access control
- **Skill signing**: Proposed skills undergo review before installation
- **No cloud sync by default**: State stays local unless you configure remote memory

## Development

Nova is built with:

- TypeScript (Node.js 18+, Bun unsupported)
- Tauri for desktop apps
- Vite for UI bundling
- Vitest for testing

Build commands:

```bash
pnpm install     # Install dependencies
pnpm check       # Type check + lint
pnpm test        # Run test suite
pnpm build       # Build all outputs
```

## Comparison with OpenClaw

| Feature         | OpenClaw             | Nova                             |
| --------------- | -------------------- | -------------------------------- |
| Multi-channel   | ✅                   | ✅ (enhanced)                    |
| Self-learning   | ✅ (basic)           | ✅ (enhanced via skill workshop) |
| Skill proposals | ✅                   | ✅ (merged with Hermes workflow) |
| Provider count  | ~30                  | 60+                              |
| Plugin SDK      | Basic                | Mature version-aware SDK         |
| Memory system   | Lobster-dex counters | Full fact/durable memory         |
| Desktop apps    | Yes                  | Yes (rebranded)                  |
| Branding        | Lobster              | Star                             |

Nova represents the synthesis of both projects' best ideas into a single coherent platform.
