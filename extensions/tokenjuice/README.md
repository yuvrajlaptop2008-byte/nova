# @nova/tokenjuice

Official Tokenjuice output compaction plugin for Nova.

Tokenjuice compacts noisy `exec` and `bash` tool results after commands run, before the result is fed back into the active agent session. It does not rewrite commands, rerun commands, or change exit codes.

## Install

```bash
nova plugins install @nova/tokenjuice
```

Restart the Gateway after installing or updating the plugin.

## Enable

```bash
nova config set plugins.entries.tokenjuice.enabled true
```

Equivalent:

```bash
nova plugins enable tokenjuice
```

## Docs

- https://docs.nova.ai/tools/tokenjuice

## Package

- Plugin id: `tokenjuice`
- Package: `@nova/tokenjuice`
- Minimum Nova host: `2026.5.28`
