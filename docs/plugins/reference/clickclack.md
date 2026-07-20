---
summary: "Adds the Clickclack channel surface for sending and receiving Nova messages."
read_when:
  - You are installing, configuring, or auditing the clickclack plugin
title: "Clickclack plugin"
---

# Clickclack plugin

Adds the Clickclack channel surface for sending and receiving Nova messages.

## Distribution

- Package: `@nova/clickclack`
- Install route: npm; ClawHub: `clawhub:@nova/clickclack`

## Surface

channels: `clickclack`

The plugin can optionally create a lifecycle-synchronized ClickClack channel
for each Nova session. Managed discussion channels use a same-agent side
session for observation and relay, while the attached main session receives a
pull-only `discussion` tool. See [ClickClack session discussions](/channels/clickclack#session-discussions)
for configuration and session-tool visibility requirements.

## Related docs

- [clickclack](/channels/clickclack)
