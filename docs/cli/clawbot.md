---
summary: "CLI reference for `nova clawbot` (legacy alias namespace)"
read_when:
  - You maintain older scripts using `nova clawbot ...`
  - You need migration guidance to current commands
title: "Clawbot"
---

# `nova clawbot`

Legacy alias namespace kept for backward compatibility. It registers the same QR command as the top-level CLI, so `nova clawbot qr` accepts every [`nova qr`](/cli/qr) flag.

## Migration

Prefer the modern top-level command:

- `nova clawbot qr` -> `nova qr`

## Related

- [CLI reference](/cli)
