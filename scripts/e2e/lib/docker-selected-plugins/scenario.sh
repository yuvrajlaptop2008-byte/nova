#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/nova-docker-selected-plugins
export NOVA_STATE_DIR="$HOME/.nova"
export NOVA_CONFIG_PATH="$NOVA_STATE_DIR/nova.json"
export NOVA_DISABLE_BUNDLED_SOURCE_OVERLAYS=1

mkdir -p "$NOVA_STATE_DIR"
node --input-type=module <<'NODE'
import fs from "node:fs";

const entries = Object.fromEntries(
  ["clickclack", "slack", "msteams"].map((id) => [id, { enabled: true }]),
);
fs.writeFileSync(
  process.env.NOVA_CONFIG_PATH,
  `${JSON.stringify({ plugins: { entries } }, null, 2)}\n`,
  { mode: 0o600 },
);
NODE

for plugin_id in clickclack slack msteams clawrouter; do
  node /app/nova.mjs plugins inspect "$plugin_id" --runtime --json \
    >"/tmp/nova-${plugin_id}-inspect.json"
done

node /nova-e2e/assertions.mjs
