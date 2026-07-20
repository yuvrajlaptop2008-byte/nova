# @nova/pixverse-provider

Official PixVerse video generation provider plugin for Nova.

This plugin registers PixVerse as a `video_generate` provider for text-to-video and image-to-video workflows.

## Install

```bash
nova plugins install @nova/pixverse-provider
```

Restart the Gateway after installing or updating the plugin.

## Configure

Store your PixVerse API key in Nova config or expose the supported environment variable to the Gateway. Then select PixVerse as a video generation provider.

Full setup and model/provider examples:

- https://docs.nova.ai/providers/pixverse

## Package

- Plugin id: `pixverse`
- Package: `@nova/pixverse-provider`
- Minimum Nova host: `2026.5.26`
