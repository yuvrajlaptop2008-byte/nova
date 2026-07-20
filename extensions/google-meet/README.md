# @nova/google-meet

Official Google Meet participant plugin for Nova.

This plugin registers the `google_meet` tool so agents can join Google Meet calls through supported Chrome or Twilio transports.

## Install

```bash
nova plugins install @nova/google-meet
```

Restart the Gateway after installing or updating the plugin.

## Configure

Enable the plugin and follow the Google Meet docs for browser profile, transport, and call-join setup:

- https://docs.nova.ai/plugins/google-meet

## Package

- Plugin id: `google-meet`
- Tool: `google_meet`
- Package: `@nova/google-meet`
- Minimum Nova host: `2026.4.20`
