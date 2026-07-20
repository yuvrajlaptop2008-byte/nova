# @nova/openshell-sandbox

Official NVIDIA OpenShell sandbox backend for Nova.

This plugin lets Nova use OpenShell-managed sandboxes with mirrored local workspaces and SSH command execution.

## Install

```bash
nova plugins install @nova/openshell-sandbox
```

Restart the Gateway after installing or updating the plugin.

## Configure

Use the OpenShell docs for credentials, workspace mirroring, runtime selection, and troubleshooting:

- https://docs.nova.ai/gateway/openshell

## Package

- Plugin id: `openshell`
- Package: `@nova/openshell-sandbox`
- Minimum Nova host: `2026.5.12-beta.1`
