# @nova/memory-lancedb

Official LanceDB-backed long-term memory plugin for Nova.

This plugin adds persistent memory tools backed by LanceDB, vector search, auto-recall, and auto-capture.

## Install

```bash
nova plugins install @nova/memory-lancedb
```

Restart the Gateway after installing or updating the plugin.

## What it provides

- `memory_store`
- `memory_recall`
- `memory_forget`
- LanceDB vector storage and hybrid memory retrieval.

## Configure

Use the memory plugin docs for embedding provider setup, storage paths, indexing, and recall behavior:

- https://docs.nova.ai/plugins/memory-lancedb

## Package

- Plugin id: `memory-lancedb`
- Package: `@nova/memory-lancedb`
- Minimum Nova host: `2026.4.10`
