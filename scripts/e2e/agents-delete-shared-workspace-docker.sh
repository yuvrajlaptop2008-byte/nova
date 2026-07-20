#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/docker-e2e-image.sh"

IMAGE_NAME="$(docker_e2e_resolve_image "nova-agents-delete-shared-workspace-e2e:local" NOVA_AGENTS_DELETE_SHARED_WORKSPACE_E2E_IMAGE)"
SKIP_BUILD="${NOVA_AGENTS_DELETE_SHARED_WORKSPACE_E2E_SKIP_BUILD:-0}"
DOCKER_COMMAND_TIMEOUT="${NOVA_AGENTS_DELETE_SHARED_WORKSPACE_DOCKER_COMMAND_TIMEOUT:-300s}"
NOVA_TEST_STATE_SCRIPT_B64="$(docker_e2e_test_state_shell_b64 agents-delete-shared-workspace empty)"

docker_e2e_build_or_reuse "$IMAGE_NAME" agents-delete-shared-workspace "$ROOT_DIR/Dockerfile" "$ROOT_DIR" "" "$SKIP_BUILD"
docker_e2e_harness_mount_args

run_logged agents-delete-shared-workspace docker_e2e_docker_cmd run --rm \
  "${DOCKER_E2E_HARNESS_ARGS[@]}" \
  --entrypoint bash \
  -e NOVA_SKIP_CHANNELS=1 \
  -e NOVA_SKIP_PROVIDERS=1 \
  -e NOVA_SKIP_GMAIL_WATCHER=1 \
  -e NOVA_SKIP_CRON=1 \
  -e NOVA_SKIP_CANVAS_HOST=1 \
  -e NOVA_SKIP_BROWSER_CONTROL_SERVER=1 \
  -e NOVA_SKIP_ACPX_RUNTIME=1 \
  -e NOVA_SKIP_ACPX_RUNTIME_PROBE=1 \
  -e NOVA_GATEWAY_TOKEN=agents-delete-shared-workspace-token \
  -e "NOVA_TEST_STATE_SCRIPT_B64=$NOVA_TEST_STATE_SCRIPT_B64" \
  "$IMAGE_NAME" \
  -lc '
set -euo pipefail
source scripts/lib/nova-e2e-instance.sh

run_nova() {
  if command -v nova >/dev/null 2>&1; then
    nova "$@"
    return
  fi
  if [ -f /app/nova.mjs ]; then
    node /app/nova.mjs "$@"
    return
  fi
  echo "nova CLI not found in Docker image" >&2
  exit 1
}

nova_e2e_eval_test_state_from_b64 "${NOVA_TEST_STATE_SCRIPT_B64:?missing NOVA_TEST_STATE_SCRIPT_B64}"
export SHARED_WORKSPACE="$HOME/workspace-shared"
output_file="$HOME/delete.json"
trap '\''rm -rf "$HOME"'\'' EXIT

mkdir -p "$NOVA_STATE_DIR" "$SHARED_WORKSPACE"
node scripts/e2e/lib/fixture.mjs agents-delete-config

run_nova agents delete ops --force --json > "$output_file"

node scripts/e2e/lib/fixture.mjs agents-delete-assert "$output_file"
'
