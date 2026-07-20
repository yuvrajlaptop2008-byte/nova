#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/nova-e2e-instance.sh
nova_e2e_eval_test_state_from_b64 "${NOVA_TEST_STATE_SCRIPT_B64:?missing NOVA_TEST_STATE_SCRIPT_B64}"
export NOVA_SKIP_CHANNELS=1
export NOVA_SKIP_GMAIL_WATCHER=1
export NOVA_SKIP_CRON=1
export NOVA_SKIP_CANVAS_HOST=1
export NOVA_SKIP_BROWSER_CONTROL_SERVER=1
export NOVA_SKIP_ACPX_RUNTIME=1
export NOVA_SKIP_ACPX_RUNTIME_PROBE=1
export NOVA_AGENT_HARNESS_FALLBACK=none

for profile_path in "$HOME/.profile" /home/appuser/.profile; do
  if [ -f "$profile_path" ] && [ -r "$profile_path" ]; then
    set +e +u
    # shellcheck disable=SC1090
    source "$profile_path"
    set -euo pipefail
    break
  fi
done
if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY was not available after sourcing ~/.profile." >&2
  exit 1
fi
export OPENAI_API_KEY
if [ -n "${OPENAI_BASE_URL:-}" ]; then
  export OPENAI_BASE_URL
fi

PORT="${PORT:?missing PORT}"
TOKEN="${NOVA_GATEWAY_TOKEN:?missing NOVA_GATEWAY_TOKEN}"
MODEL_REF="${NOVA_OPENAI_CHAT_TOOLS_MODEL:?missing NOVA_OPENAI_CHAT_TOOLS_MODEL}"
GATEWAY_LOG="/tmp/nova-openai-chat-tools-gateway.log"
CLIENT_LOG="/tmp/nova-openai-chat-tools-client.log"
gateway_pid=""

cleanup() {
  nova_e2e_stop_process "$gateway_pid"
}
trap cleanup EXIT

dump_debug_logs() {
  local status="$1"
  echo "OpenAI Chat Completions tools Docker E2E failed with exit code $status" >&2
  nova_e2e_dump_logs "$GATEWAY_LOG" "$CLIENT_LOG"
  if [ -f "$NOVA_CONFIG_PATH" ]; then
    echo "--- $NOVA_CONFIG_PATH keys ---" >&2
    node -e "const fs=require('fs'); const cfg=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); console.error(JSON.stringify({model:cfg.agents?.defaults?.model, tools:cfg.tools, provider:cfg.models?.providers?.openai && {api:cfg.models.providers.openai.api, baseUrl:cfg.models.providers.openai.baseUrl, agentRuntime:cfg.models.providers.openai.agentRuntime}}, null, 2));" "$NOVA_CONFIG_PATH" || true
  fi
}
trap 'status=$?; dump_debug_logs "$status"; exit "$status"' ERR

entry="$(nova_e2e_resolve_entrypoint)"
mkdir -p "$NOVA_STATE_DIR" "$NOVA_TEST_WORKSPACE_DIR"

node scripts/e2e/lib/openai-chat-tools/write-config.mjs

gateway_pid="$(nova_e2e_start_gateway "$entry" "$PORT" "$GATEWAY_LOG")"
for _ in $(seq 1 360); do
  if ! kill -0 "$gateway_pid" 2>/dev/null; then
    echo "gateway exited before listening" >&2
    exit 1
  fi
  if node "$entry" gateway health \
    --url "ws://127.0.0.1:$PORT" \
    --token "$TOKEN" \
    --timeout 120000 \
    --json >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done
node "$entry" gateway health \
  --url "ws://127.0.0.1:$PORT" \
  --token "$TOKEN" \
  --timeout 120000 \
  --json >/dev/null

PORT="$PORT" NOVA_GATEWAY_TOKEN="$TOKEN" MODEL_REF="$MODEL_REF" \
  node scripts/e2e/lib/openai-chat-tools/client.mjs >"$CLIENT_LOG" 2>&1

nova_e2e_print_log "$CLIENT_LOG"
echo "OpenAI Chat Completions tools Docker E2E passed"
