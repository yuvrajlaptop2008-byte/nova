# @nova/diagnostics-prometheus

Official Prometheus diagnostics exporter for Nova.

This plugin exposes Nova Gateway runtime metrics in Prometheus text format for Prometheus, Grafana, VictoriaMetrics, and compatible scrapers.

## Install

```bash
nova plugins install @nova/diagnostics-prometheus
```

Restart the Gateway after installing or updating the plugin.

## Configure

Enable the plugin and set the scrape endpoint options in `plugins.entries.diagnostics-prometheus.config`.

The full config surface, metric names, and scrape examples live in the docs:

- https://docs.nova.ai/gateway/prometheus

## Package

- Plugin id: `diagnostics-prometheus`
- Package: `@nova/diagnostics-prometheus`
- Minimum Nova host: `2026.4.25`
