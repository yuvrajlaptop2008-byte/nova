---
summary: "Run the Nova Gateway on EasyRunner with Podman and Caddy"
read_when:
  - Deploying Nova on EasyRunner
  - Running the Gateway behind EasyRunner's Caddy proxy
  - Choosing persistent volumes and auth for a hosted Gateway
title: "EasyRunner"
---

EasyRunner hosts the Nova Gateway as a small containerized app behind its
Caddy proxy. This guide assumes an EasyRunner host that runs Podman-compatible
Compose apps and terminates HTTPS through Caddy.

## Before you begin

- An EasyRunner server with a domain routed to it.
- The official Nova image (`ghcr.io/nova/nova`) or your own build.
- A persistent config volume for `/home/node/.nova`.
- A persistent workspace volume for `/home/node/.nova/workspace`.
- A strong Gateway token or password.

Keep device auth enabled when possible. If your reverse proxy cannot carry
device identity correctly, fix trusted-proxy settings first (see
[Trusted proxy auth](/gateway/trusted-proxy-auth)); use dangerous auth
bypasses only on a fully private, operator-controlled network.

## Compose app

Create an EasyRunner app with a Compose file shaped like this:

```yaml
services:
  nova:
    image: ghcr.io/nova/nova:latest
    restart: unless-stopped
    environment:
      NOVA_GATEWAY_TOKEN: ${NOVA_GATEWAY_TOKEN}
      NOVA_HOME: /home/node
      NOVA_STATE_DIR: /home/node/.nova
      NOVA_CONFIG_PATH: /home/node/.nova/nova.json
      NOVA_WORKSPACE_DIR: /home/node/.nova/workspace
    volumes:
      - nova-config:/home/node/.nova
      - nova-workspace:/home/node/.nova/workspace
    labels:
      caddy: nova.example.com
      caddy.reverse_proxy: "{{upstreams 1455}}"
    command: ["node", "nova.mjs", "gateway", "--bind", "lan", "--port", "1455"]

volumes:
  nova-config:
  nova-workspace:
```

Replace `nova.example.com` with your Gateway hostname. Store
`NOVA_GATEWAY_TOKEN` in EasyRunner's secret/environment manager instead of
committing it to the app definition. The image binds to loopback by default,
so the explicit `--bind lan --port 1455` in `command` is required for Caddy to
reach the container.

## Configure Nova

Inside the persistent config volume, keep the Gateway reachable only through
the proxy and require auth:

```json5
{
  gateway: {
    bind: "lan",
    port: 1455,
    auth: {
      token: "${NOVA_GATEWAY_TOKEN}",
    },
  },
}
```

If Caddy terminates TLS for the Gateway, configure trusted-proxy settings for
the exact proxy path rather than disabling auth checks globally. See
[Trusted proxy auth](/gateway/trusted-proxy-auth).

## Verify

From your workstation:

```bash
nova gateway probe --url https://nova.example.com --token <token>
nova gateway status --url https://nova.example.com --token <token>
```

From the EasyRunner host, `GET /healthz` (liveness) and `GET /readyz`
(readiness) need no auth and back the image's built-in container health
check. Also check the app logs for a listening Gateway and no startup
SecretRef, plugin, or channel auth failures.

## Updates and backups

- Pull or build the new Nova image, then redeploy the EasyRunner app.
- Back up the `nova-config` volume before updates. It holds
  `nova.json`, `agents/<agentId>/agent/auth-profiles.json`, and installed
  plugin package state.
- Back up `nova-workspace` if agents write durable project data there.
- Run `nova doctor` after major updates to catch config migrations and
  service warnings.

## Troubleshooting

- `gateway probe` cannot connect: confirm the Caddy hostname points at the app
  and that the container listens on `0.0.0.0:1455`.
- Auth fails: rotate the token in EasyRunner secrets and the local client
  command together.
- Files are root-owned after restore: the image runs as `node` (uid 1000);
  repair the mounted volumes so that user can write
  `/home/node/.nova` and `/home/node/.nova/workspace`.
- Browser or channel plugins fail: check whether the required external
  binaries, network egress, and mounted credentials are available inside the
  container.
