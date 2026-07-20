---
summary: "Host Nova on a DigitalOcean Droplet"
read_when:
  - Setting up Nova on DigitalOcean
  - Looking for a simple paid VPS for Nova
title: "DigitalOcean"
---

Run a persistent Nova Gateway on a DigitalOcean Droplet (~$6/month for the 1 GB Basic plan).

DigitalOcean is a straightforward paid VPS path. For cheaper or free options:

- [Hetzner](/install/hetzner) -- more cores/RAM per dollar.
- [Oracle Cloud](/install/oracle) -- Always Free ARM tier (up to 4 OCPU, 24 GB RAM), but signup can be finicky and it is ARM-only.

## Prerequisites

- DigitalOcean account ([signup](https://cloud.digitalocean.com/registrations/new))
- SSH key pair (or willingness to use password auth)
- About 20 minutes

## Setup

<Steps>
  <Step title="Create a Droplet">
    <Warning>
    Use a clean base image (Ubuntu 24.04 LTS). Avoid third-party Marketplace 1-click images unless you have reviewed their startup scripts and firewall defaults.
    </Warning>

    1. Log into [DigitalOcean](https://cloud.digitalocean.com/).
    2. Click **Create > Droplets**.
    3. Choose:
       - **Region:** Closest to you
       - **Image:** Ubuntu 24.04 LTS
       - **Size:** Basic, Regular, 1 vCPU / 1 GB RAM / 25 GB SSD
       - **Authentication:** SSH key (recommended) or password
    4. Click **Create Droplet** and note the IP address.

  </Step>

  <Step title="Connect and install">
    ```bash
    ssh root@YOUR_DROPLET_IP

    apt update && apt upgrade -y

    # Install Node.js 24
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt install -y nodejs

    # Install Nova
    curl -fsSL https://nova.ai/install.sh | bash

    # Create the non-root user that will own Nova state and services.
    adduser nova
    usermod -aG sudo nova
    loginctl enable-linger nova

    su - nova
    nova --version
    ```

    Use the root shell only for system bootstrap. Run Nova commands as the non-root `nova` user so state lives under `/home/nova/.nova/` and the Gateway installs as that user's systemd `--user` service.

  </Step>

  <Step title="Run onboarding">
    ```bash
    nova onboard --install-daemon
    ```

    The wizard walks you through model auth, channel setup, gateway token generation, and daemon installation (systemd user service).

  </Step>

  <Step title="Add swap (recommended for 1 GB Droplets)">
    ```bash
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    ```
  </Step>

  <Step title="Verify the gateway">
    ```bash
    nova status
    systemctl --user status nova-gateway.service
    journalctl --user -u nova-gateway.service -f
    ```
  </Step>

  <Step title="Access the Control UI">
    The gateway binds to loopback by default. Pick one of these options.

    **Option A: SSH tunnel (simplest)**

    ```bash
    # From your local machine
    ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP
    ```

    Then open `http://localhost:18789`.

    **Option B: Tailscale Serve**

    ```bash
    curl -fsSL https://tailscale.com/install.sh | sudo sh
    sudo tailscale up
    nova config set gateway.tailscale.mode serve
    nova gateway restart
    ```

    Then open `https://<magicdns>/` from any device on your tailnet.

    Tailscale Serve authenticates Control UI and WebSocket traffic via tailnet identity headers, which assumes the gateway host itself is trusted. HTTP API endpoints still follow the gateway's normal auth mode (token/password) regardless. To require explicit shared-secret credentials over Serve, set `gateway.auth.allowTailscale: false` and use `gateway.auth.mode: "token"` or `"password"`.

    **Option C: Tailnet bind (no Serve)**

    ```bash
    nova config set gateway.bind tailnet
    nova gateway restart
    ```

    Then open `http://<tailscale-ip>:18789` (token required).

  </Step>
</Steps>

## Persistence and backups

Nova state lives under:

- `~/.nova/` -- `nova.json`, channel/provider credentials, per-agent `auth-profiles.json`, and session data.
- `~/.nova/workspace/` -- the agent workspace (SOUL.md, memory, artifacts).

These survive Droplet reboots. To take a portable snapshot:

```bash
nova backup create
```

DigitalOcean snapshots back up the whole Droplet; `nova backup create` is portable across hosts.

## 1 GB RAM tips

The $6 Droplet only has 1 GB RAM. To keep things smooth:

- Make sure the swap step above is in `/etc/fstab` so it survives reboots.
- Prefer API-based models (Claude, GPT) over local ones -- local LLM inference does not fit in 1 GB.
- Set `agents.defaults.model.primary` to a smaller model if you hit OOMs on large prompts.
- Monitor with `free -h` and `htop`.

## Troubleshooting

**Gateway will not start** -- Run `nova doctor --non-interactive` and check logs with `journalctl --user -u nova-gateway.service -n 50`.

**Port already in use** -- Run `lsof -i :18789` to find the process, then stop it.

**Out of memory** -- Verify swap is active with `free -h`. If still hitting OOM, switch to API-based models (Claude, GPT) rather than local models, or upgrade to a 2 GB Droplet.

## Next steps

- [Channels](/channels) -- connect Telegram, WhatsApp, Discord, and more
- [Gateway configuration](/gateway/configuration) -- all config options
- [Updating](/install/updating) -- keep Nova up to date

## Related

- [Install overview](/install)
- [Fly.io](/install/fly)
- [Hetzner](/install/hetzner)
- [VPS hosting](/vps)
