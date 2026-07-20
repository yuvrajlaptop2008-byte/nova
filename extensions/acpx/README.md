# @nova/acpx

Official ACP runtime backend for Nova.

ACPx lets Nova run external coding harnesses through the Agent Client Protocol while Nova still owns sessions, channels, delivery, permissions, and Gateway state.

## Install

```bash
nova plugins install @nova/acpx
```

Restart the Gateway after installing or updating the plugin.

## What it provides

- ACP-backed agent runtime sessions.
- Plugin-owned session and transport management.
- MCP bridge helpers for Nova tools and plugin tools.
- Static runtime assets used by the ACP process bridge.

## Configure

Use the ACP docs for harness-specific setup, permission modes, and model/runtime selection:

- https://docs.nova.ai/tools/acp-agents-setup
- https://docs.nova.ai/tools/acp-agents

## Package

- Plugin id: `acpx`
- Package: `@nova/acpx`
- Minimum Nova host: `2026.4.25`
