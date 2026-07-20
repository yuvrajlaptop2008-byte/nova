#!/data/data/com.termux/files/usr/bin/bash
# Nova OAuth Sync Widget
# Syncs Claude Code tokens to Nova over SSH
# Place in ~/.shortcuts/ on phone for Termux:Widget

termux-toast "Syncing Nova auth..."

# Run sync on the configured Nova host.
SERVER="${NOVA_SERVER:-nova-host}"
RESULT=$(ssh "$SERVER" '$HOME/nova/scripts/sync-claude-code-auth.sh' 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Extract expiry time from output
    EXPIRY=$(echo "$RESULT" | grep "Token expires:" | cut -d: -f2-)

    termux-vibrate -d 100
    termux-toast "Nova synced! Expires:${EXPIRY}"

    # Optional: restart nova service
    ssh "$SERVER" 'systemctl --user restart nova' 2>/dev/null
else
    termux-vibrate -d 300
    termux-toast "Sync failed: ${RESULT}"
fi
