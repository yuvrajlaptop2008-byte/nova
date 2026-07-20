---
summary: "Manage sandbox runtimes and inspect effective sandbox policy"
title: Sandbox CLI
read_when: "You are managing sandbox runtimes or debugging sandbox/tool-policy behavior."
status: active
---

Manage sandbox runtimes for isolated agent execution: Docker containers, SSH targets, or OpenShell backends.

## Commands

### `nova sandbox list`

List sandbox runtimes with status, backend, config match, age, idle time, and associated session/agent.

```bash
nova sandbox list
nova sandbox list --browser  # browser containers only
nova sandbox list --json
```

### `nova sandbox recreate`

Remove sandbox runtimes to force recreation with current config. Runtimes are recreated automatically the next time the agent is used.

```bash
nova sandbox recreate --all
nova sandbox recreate --agent mybot        # includes agent:mybot:* sub-sessions
nova sandbox recreate --session "agent:main:main"
nova sandbox recreate --browser --all      # only browser containers
nova sandbox recreate --all --force        # skip confirmation
```

Options:

- `--all`: recreate all sandbox containers
- `--session <key>`: recreate the runtime with this exact scope key (as shown by `sandbox list`); no short-name expansion
- `--agent <id>`: recreate runtimes for one agent (matches `agent:<id>` and `agent:<id>:*`)
- `--browser`: only affect browser containers
- `--force`: skip the confirmation prompt

Pass exactly one of `--all`, `--session`, or `--agent`.

For `ssh` and OpenShell `remote`, recreate matters more than with Docker: the remote workspace is canonical after the initial seed, `recreate` deletes that canonical remote workspace for the selected scope, and the next run reseeds it from the current local workspace.

### `nova sandbox explain`

Inspect the effective sandbox mode/scope/workspace access, sandbox tool policy, and elevated-tool gates (with fix-it config key paths).

The report keeps `workspaceRoot` as the configured sandbox root and separately shows the effective host workspace, backend runtime workdir, and Docker mount table. For `workspaceAccess: "rw"`, the effective host workspace is the agent workspace rather than a directory below `workspaceRoot`.

```bash
nova sandbox explain
nova sandbox explain --session agent:main:main
nova sandbox explain --agent work
nova sandbox explain --json
```

Unlike `recreate --session`, this accepts short session names (for example `main`) and expands them against the resolved agent.

## Why recreate is needed

Updating sandbox config does not affect running containers: existing runtimes keep their old settings, and idle runtimes are only pruned after `prune.idleHours` (default 24h). Regularly used agents can keep stale runtimes alive indefinitely. `nova sandbox recreate` removes the old runtime so the next use rebuilds it from current config.

<Tip>
Prefer `nova sandbox recreate` over manual backend-specific cleanup. It uses the Gateway's runtime registry and avoids mismatches when scope or session keys change.
</Tip>

## Common triggers

| Change                                                                                                                                                         | Command                                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Docker image update (`agents.defaults.sandbox.docker.image`)                                                                                                   | `nova sandbox recreate --all`                                   |
| Sandbox config (`agents.defaults.sandbox.*`)                                                                                                                   | `nova sandbox recreate --all`                                   |
| SSH target/auth (`agents.defaults.sandbox.ssh.{target,workspaceRoot,identityFile,certificateFile,knownHostsFile,identityData,certificateData,knownHostsData}`) | `nova sandbox recreate --all`                                   |
| OpenShell source/policy/mode (`plugins.entries.openshell.config.{from,mode,policy}`)                                                                           | `nova sandbox recreate --all`                                   |
| `setupCommand`                                                                                                                                                 | `nova sandbox recreate --all` (or `--agent <id>` for one agent) |

<Note>
Runtimes are automatically recreated when the agent is next used.
</Note>

## Registry migration

Sandbox runtime metadata lives in the shared SQLite state database. Older installs may have legacy registry files that regular reads no longer rewrite:

- `~/.nova/sandbox/containers.json`
- `~/.nova/sandbox/browsers.json`
- one JSON shard per container/browser under `~/.nova/sandbox/containers/` or `~/.nova/sandbox/browsers/`

Run `nova doctor --fix` to migrate valid legacy entries into SQLite. Invalid legacy files are quarantined so a corrupt old registry cannot hide current runtime entries.

## Configuration

Sandbox settings live in `~/.nova/nova.json` under `agents.defaults.sandbox` (per-agent overrides go in `agents.list[].sandbox`):

```jsonc
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all", // off, non-main, all
        "backend": "docker", // docker, ssh, openshell (plugin-provided)
        "scope": "agent", // session, agent, shared
        "docker": {
          "image": "nova-sandbox:bookworm-slim",
          "containerPrefix": "nova-sbx-",
          // ... more Docker options
        },
        "prune": {
          "idleHours": 24, // auto-prune after 24h idle
          "maxAgeDays": 7, // auto-prune after 7 days
        },
      },
    },
  },
}
```

## Related

- [CLI reference](/cli)
- [Sandboxing](/gateway/sandboxing)
- [Agent workspace](/concepts/agent-workspace)
- [Doctor](/gateway/doctor): checks sandbox setup.
