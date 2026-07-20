# @nova/diagnostics-otel

Official OpenTelemetry diagnostics exporter for Nova.

This plugin exports Nova Gateway traces, metrics, and logs to an OTLP collector for observability stacks such as Grafana, Datadog, Honeycomb, New Relic, Tempo, and compatible collectors. It can also write diagnostic log records as stdout JSONL for container log pipelines.

## Install

```bash
nova plugins install @nova/diagnostics-otel
```

Restart the Gateway after installing or updating the plugin.

## Configure

Enable the plugin and set the OTLP endpoint in `plugins.entries.diagnostics-otel.config`.

The full config surface, metric names, span names, and collector examples live in the docs:

- https://docs.nova.ai/gateway/opentelemetry

## Package

- Plugin id: `diagnostics-otel`
- Package: `@nova/diagnostics-otel`
- Minimum Nova host: `2026.4.25`
