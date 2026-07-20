#!/usr/bin/env bash
set -euo pipefail
trap "" PIPE
export TERM=xterm-256color
export NO_COLOR=1

source scripts/lib/nova-e2e-instance.sh

nova_e2e_eval_test_state_from_b64 "${NOVA_TEST_STATE_SCRIPT_B64:?missing NOVA_TEST_STATE_SCRIPT_B64}"
nova_e2e_install_trash_shim

export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
export npm_config_loglevel=error
export npm_config_fund=false
export npm_config_audit=false

dump_debug_logs() {
  local status="$1"
  echo "release plugin marketplace failed with exit code $status" >&2
  nova_e2e_dump_logs \
    /tmp/nova-release-plugin-marketplace-install.log \
    /tmp/nova-release-plugin-marketplace-onboard.log \
    /tmp/nova-release-plugin-marketplace-list.json \
    /tmp/nova-release-plugin-marketplace-install-plugin.log \
    /tmp/nova-release-plugin-marketplace-cli-v1.log \
    /tmp/nova-release-plugin-marketplace-update-dry-run.log \
    /tmp/nova-release-plugin-marketplace-update.log \
    /tmp/nova-release-plugin-marketplace-cli-v2.log \
    /tmp/nova-release-plugin-marketplace-uninstall.log \
    /tmp/nova-release-plugin-marketplace-cli-after-uninstall.log
}
trap 'status=$?; dump_debug_logs "$status"; exit "$status"' ERR

nova_e2e_install_package /tmp/nova-release-plugin-marketplace-install.log
command -v nova >/dev/null
nova_e2e_enable_nova_cli_timeout

nova onboard \
  --non-interactive \
  --accept-risk \
  --flow quickstart \
  --mode local \
  --auth-choice skip \
  --skip-daemon \
  --skip-ui \
  --skip-channels \
  --skip-skills \
  --skip-health >/tmp/nova-release-plugin-marketplace-onboard.log 2>&1

marketplace_root="$HOME/.claude/plugins/marketplaces/release-fixture-marketplace"
mkdir -p "$HOME/.claude/plugins" "$marketplace_root/.claude-plugin"
node scripts/e2e/lib/release-scenarios/write-cli-plugin.mjs \
  "$marketplace_root/plugins/release-marketplace-plugin" \
  release-marketplace-plugin \
  0.0.1 \
  release.marketplace.v1 \
  "Release Marketplace Plugin" \
  release-market \
  "release-marketplace-plugin:v1"
node scripts/e2e/lib/release-scenarios/write-cli-plugin.mjs \
  "$marketplace_root/plugins/release-marketplace-other" \
  release-marketplace-other \
  0.0.1 \
  release.marketplace.other \
  "Release Marketplace Other" \
  release-market-other \
  "release-marketplace-other:v1"
node scripts/e2e/lib/release-scenarios/write-marketplace.mjs \
  "$marketplace_root" \
  release-fixtures \
  release-marketplace-plugin \
  release-marketplace-other

nova plugins marketplace list release-fixtures --json >/tmp/nova-release-plugin-marketplace-list.json
node scripts/e2e/lib/release-scenarios/assertions.mjs assert-file-contains /tmp/nova-release-plugin-marketplace-list.json release-marketplace-plugin

nova plugins install release-marketplace-plugin@release-fixtures --force >/tmp/nova-release-plugin-marketplace-install-plugin.log 2>&1
nova release-market ping >/tmp/nova-release-plugin-marketplace-cli-v1.log 2>&1
node scripts/e2e/lib/release-scenarios/assertions.mjs assert-file-contains /tmp/nova-release-plugin-marketplace-cli-v1.log "release-marketplace-plugin:v1"

node scripts/e2e/lib/release-scenarios/write-cli-plugin.mjs \
  "$marketplace_root/plugins/release-marketplace-plugin" \
  release-marketplace-plugin \
  0.0.2 \
  release.marketplace.v2 \
  "Release Marketplace Plugin" \
  release-market \
  "release-marketplace-plugin:v2"
nova plugins update release-marketplace-plugin --dry-run >/tmp/nova-release-plugin-marketplace-update-dry-run.log 2>&1
nova plugins update release-marketplace-plugin >/tmp/nova-release-plugin-marketplace-update.log 2>&1
nova release-market ping >/tmp/nova-release-plugin-marketplace-cli-v2.log 2>&1
node scripts/e2e/lib/release-scenarios/assertions.mjs assert-file-contains /tmp/nova-release-plugin-marketplace-cli-v2.log "release-marketplace-plugin:v2"

nova plugins uninstall release-marketplace-plugin --force >/tmp/nova-release-plugin-marketplace-uninstall.log 2>&1
if nova release-market ping >/tmp/nova-release-plugin-marketplace-cli-after-uninstall.log 2>&1; then
  echo "release-market CLI should be gone after uninstall" >&2
  exit 1
fi
node scripts/e2e/lib/release-scenarios/assertions.mjs assert-plugin-uninstalled release-marketplace-plugin release-market

echo "Release plugin marketplace scenario passed."
