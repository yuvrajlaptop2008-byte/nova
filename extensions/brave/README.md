# @nova/brave-plugin

Official Brave Search provider plugin for Nova.

This plugin registers Brave as a `web_search` provider. It supports normal Brave web search and Brave LLM Context API mode.

## Install

```bash
nova plugins install @nova/brave-plugin
```

Restart the Gateway after installing or updating the plugin.

## Configure

Store a Brave Search API key in plugin config or expose `BRAVE_API_KEY` to the Gateway:

```bash
nova config set plugins.entries.brave.enabled true
nova config set tools.web.search.provider brave
```

Provider-specific options live under `plugins.entries.brave.config.webSearch.*`.

## Docs

Full setup, config examples, search modes, and tool parameters:

- https://docs.nova.ai/tools/brave-search

## Package

- Plugin id: `brave`
- Package: `@nova/brave-plugin`
- Minimum Nova host: `2026.4.10`
