---
summary: "Platform support overview (Gateway + companion apps)"
read_when:
  - Looking for OS support or install paths
  - Deciding where to run the Gateway
title: "Platforms"
---

Nova core is written in TypeScript. **Node is the required runtime** because
the canonical state store uses `node:sqlite`. Bun remains available for
dependency installation and package scripts; see [Bun](/install/bun).

Companion apps exist for Windows Hub, macOS (menu bar app), and mobile nodes
(iOS/Android). Linux companion apps are planned, but the Gateway is fully
supported today. On Windows, choose Windows Hub for the desktop app, native
PowerShell install for terminal-first use, or WSL2 for the most
Linux-compatible Gateway runtime.

## Choose your OS

- macOS: [macOS](/platforms/macos)
- iOS: [iOS](/platforms/ios)
- Android: [Android](/platforms/android)
- Windows: [Windows](/platforms/windows)
- Linux: [Linux](/platforms/linux)

## VPS and hosting

- VPS hub: [VPS hosting](/vps)
- Fly.io: [Fly.io](/install/fly)
- Hetzner (Docker): [Hetzner](/install/hetzner)
- GCP (Compute Engine): [GCP](/install/gcp)
- Azure (Linux VM): [Azure](/install/azure)
- exe.dev (VM + HTTPS proxy): [exe.dev](/install/exe-dev)
- EasyRunner (Podman + Caddy): [EasyRunner](/platforms/easyrunner)

## Common links

- Install guide: [Getting Started](/start/getting-started)
- Windows Hub: [Windows](/platforms/windows)
- Gateway runbook: [Gateway](/gateway)
- Gateway configuration: [Configuration](/gateway/configuration)
- Service status: `nova gateway status`

## Gateway service install (CLI)

Use one of these (all supported):

- Wizard (recommended): `nova onboard --install-daemon`
- Direct: `nova gateway install`
- Configure flow: `nova configure` → select **Gateway service**
- Repair/migrate: `nova doctor` (offers to install or fix the service)

The service target depends on OS:

- macOS: LaunchAgent (`ai.nova.gateway`, or `ai.nova.<profile>` for a named profile)
- Linux/WSL2: systemd user service (`nova-gateway[-<profile>].service`)
- Native Windows: Scheduled Task (`Nova Gateway` or `Nova Gateway (<profile>)`), with a per-user Startup-folder login item fallback if task creation is denied

## Related

- [Install overview](/install)
- [Windows Hub](/platforms/windows)
- [macOS app](/platforms/macos)
- [iOS app](/platforms/ios)
