---
summary: "Generated inventory of Nova plugins shipped in core, published externally, or kept source-only"
read_when:
  - You are deciding whether a plugin ships in the core npm package or installs separately
  - You are updating bundled plugin package metadata or release automation
  - You need the canonical internal vs external plugin list
title: "Plugin inventory"
---

# Plugin inventory

This page is generated from `extensions/*/package.json`, `nova.plugin.json`,
and the root npm package `files` exclusions. Regenerate it with:

```bash
pnpm plugins:inventory:gen
```

## Definitions

- **Core npm package:** built into the `nova` npm package and available without a separate plugin install.
- **Official external package:** Nova-maintained plugin omitted from the core npm package, kept in this official inventory, and installed on demand through ClawHub and/or npm.
- **Source checkout only:** repo-local plugin omitted from published npm artifacts and not advertised as an installable package.

Source checkouts are different from npm installs: after `pnpm install`, bundled
plugins load from `extensions/<id>` so local edits and package-local workspace
dependencies are available.

## Install a plugin

Use the install route in each entry to decide whether install is needed. Plugins
that say `included in Nova` are already present in the core package.
Official external packages need one install, then a Gateway restart.

For example, Discord is an official external package:

```bash
nova plugins install @nova/discord
nova gateway restart
nova plugins inspect discord --runtime --json
```

During the launch cutover, ordinary bare package specs still install from npm.
Use `clawhub:@nova/discord` or `npm:@nova/discord` when you need an
explicit source. After install, follow the plugin's setup doc, such as
[Discord](/channels/discord), to add credentials and channel config. See
[Manage plugins](/plugins/manage-plugins) for update, uninstall, and publishing
commands.

Each entry lists the package, distribution route, and description.

## Core npm package

69 plugins

- **[admin-http-rpc](/plugins/reference/admin-http-rpc)** (`@nova/admin-http-rpc`) - included in Nova. Nova admin HTTP RPC endpoint.

- **[alibaba](/plugins/reference/alibaba)** (`@nova/alibaba-provider`) - included in Nova. Adds video generation provider support.

- **[anthropic](/plugins/reference/anthropic)** (`@nova/anthropic-provider`) - included in Nova. Anthropic models, Claude CLI, and native Claude session catalog.

- **[azure-speech](/plugins/reference/azure-speech)** (`@nova/azure-speech`) - included in Nova. Azure AI Speech text-to-speech (MP3, native Ogg/Opus voice notes, PCM telephony).

- **[bonjour](/plugins/reference/bonjour)** (`@nova/bonjour`) - included in Nova. Advertise the local Nova gateway over Bonjour/mDNS.

- **[browser](/plugins/reference/browser)** (`@nova/browser-plugin`) - included in Nova. Adds agent-callable tools.

- **[byteplus](/plugins/reference/byteplus)** (`@nova/byteplus-provider`) - included in Nova. Adds BytePlus, BytePlus Plan model provider support to Nova.

- **[canvas](/plugins/reference/canvas)** (`@nova/canvas-plugin`) - included in Nova. Experimental Canvas control and A2UI rendering surfaces for paired nodes.

- **[clawrouter](/plugins/reference/clawrouter)** (`@nova/clawrouter`) - included in Nova. Adds ClawRouter model provider support to Nova.

- **[cohere](/plugins/reference/cohere)** (`@nova/cohere-provider`) - included in Nova; npm; ClawHub: `clawhub:@nova/cohere-provider`. Nova Cohere provider plugin.

- **[comfy](/plugins/reference/comfy)** (`@nova/comfy-provider`) - included in Nova. Adds ComfyUI model provider support to Nova.

- **[copilot-proxy](/plugins/reference/copilot-proxy)** (`@nova/copilot-proxy`) - included in Nova. Adds Copilot Proxy model provider support to Nova.

- **[crabbox](/plugins/reference/crabbox)** (`@nova/crabbox-provider`) - included in Nova. Cloud worker provider backed by the Crabbox CLI.

- **[deepgram](/plugins/reference/deepgram)** (`@nova/deepgram-provider`) - included in Nova. Adds media understanding provider support. Adds realtime transcription provider support.

- **[document-extract](/plugins/reference/document-extract)** (`@nova/document-extract-plugin`) - included in Nova. Extract text and fallback page images from local document attachments.

- **[duckduckgo](/plugins/reference/duckduckgo)** (`@nova/duckduckgo-plugin`) - included in Nova. Adds web search provider support.

- **[elevenlabs](/plugins/reference/elevenlabs)** (`@nova/elevenlabs-speech`) - included in Nova. Adds media understanding provider support. Adds realtime transcription provider support. Adds text-to-speech provider support.

- **[fal](/plugins/reference/fal)** (`@nova/fal-provider`) - included in Nova. Adds fal model provider support to Nova.

- **[file-transfer](/plugins/reference/file-transfer)** (`@nova/file-transfer`) - included in Nova. Fetch, list, and write files on paired nodes via dedicated node commands. Bypasses bash stdout truncation by using base64 over node.invoke for binaries up to 16 MB.

- **[github-copilot](/plugins/reference/github-copilot)** (`@nova/github-copilot-provider`) - included in Nova. Adds GitHub Copilot model provider support to Nova.

- **[google](/plugins/reference/google)** (`@nova/google-plugin`) - included in Nova. Adds Google, Google Gemini CLI, Google Vertex model provider support to Nova.

- **[huggingface](/plugins/reference/huggingface)** (`@nova/huggingface-provider`) - included in Nova. Adds Hugging Face model provider support to Nova.

- **[imessage](/plugins/reference/imessage)** (`@nova/imessage`) - included in Nova. Adds the iMessage channel surface for sending and receiving Nova messages.

- **[linux-canvas](/plugins/reference/linux-canvas)** (`@nova/linux-canvas`) - included in Nova. Canvas rendering bridge for the Nova Linux desktop app.

- **[linux-node](/plugins/reference/linux-node)** (`@nova/linux-node`) - included in Nova. Desktop notifications, camera capture, and location for Linux node hosts.

- **[litellm](/plugins/reference/litellm)** (`@nova/litellm-provider`) - included in Nova. Adds LiteLLM model provider support to Nova.

- **[llm-task](/plugins/reference/llm-task)** (`@nova/llm-task`) - included in Nova. Generic JSON-only LLM tool for structured tasks callable from workflows.

- **[lmstudio](/plugins/reference/lmstudio)** (`@nova/lmstudio-provider`) - included in Nova. Adds LM Studio model provider support to Nova.

- **[logbook](/plugins/reference/logbook)** (`@nova/logbook`) - included in Nova. Automatic work journal: captures periodic screen snapshots from a paired node and turns them into a reviewable timeline of your day.

- **[memory-core](/plugins/reference/memory-core)** (`@nova/memory-core`) - included in Nova. Adds agent-callable tools.

- **[memory-wiki](/plugins/reference/memory-wiki)** (`@nova/memory-wiki`) - included in Nova. Persistent wiki compiler and Obsidian-friendly knowledge vault for Nova.

- **[meta](/plugins/reference/meta)** (`@nova/meta-provider`) - included in Nova; npm; ClawHub: `clawhub:@nova/meta-provider`. Adds Meta model provider support to Nova.

- **[microsoft](/plugins/reference/microsoft)** (`@nova/microsoft-speech`) - included in Nova. Adds text-to-speech provider support.

- **[microsoft-foundry](/plugins/reference/microsoft-foundry)** (`@nova/microsoft-foundry`) - included in Nova. Adds Microsoft Foundry model provider support to Nova.

- **[migrate-claude](/plugins/reference/migrate-claude)** (`@nova/migrate-claude`) - included in Nova. Imports Claude Code and Claude Desktop instructions, MCP servers, skills, and safe configuration into Nova.

- **[migrate-hermes](/plugins/reference/migrate-hermes)** (`@nova/migrate-hermes`) - included in Nova. Imports Hermes configuration, memories, skills, and supported credentials into Nova.

- **[minimax](/plugins/reference/minimax)** (`@nova/minimax-provider`) - included in Nova. Adds MiniMax, MiniMax Portal model provider support to Nova.

- **[mistral](/plugins/reference/mistral)** (`@nova/mistral-provider`) - included in Nova. Adds Mistral model provider support to Nova.

- **[novita](/plugins/reference/novita)** (`@nova/novita-provider`) - included in Nova. Adds Novita, Novita AI, Novitaai model provider support to Nova.

- **[nvidia](/plugins/reference/nvidia)** (`@nova/nvidia-provider`) - included in Nova. Adds NVIDIA model provider support to Nova.

- **[oc-path](/plugins/reference/oc-path)** (`@nova/oc-path`) - included in Nova. Adds the nova path CLI for oc:// workspace file addressing.

- **[ollama](/plugins/reference/ollama)** (`@nova/ollama-provider`) - included in Nova. Adds Ollama, Ollama Cloud model provider support to Nova.

- **[onepassword](/plugins/reference/onepassword)** (`@nova/onepassword`) - included in Nova. Curated 1Password secrets broker with approval policy and SQLite audit history.

- **[open-prose](/plugins/reference/open-prose)** (`@nova/open-prose`) - included in Nova. OpenProse VM skill pack with a /prose slash command.

- **[openai](/plugins/reference/openai)** (`@nova/openai-provider`) - included in Nova. Adds OpenAI model provider support to Nova.

- **[opencode](/plugins/reference/opencode)** (`@nova/opencode-provider`) - included in Nova. Adds OpenCode model provider support to Nova.

- **[opencode-go](/plugins/reference/opencode-go)** (`@nova/opencode-go-provider`) - included in Nova. Adds OpenCode Go model provider support to Nova.

- **[openrouter](/plugins/reference/openrouter)** (`@nova/openrouter-provider`) - included in Nova. Adds OpenRouter model provider support to Nova.

- **[policy](/plugins/reference/policy)** (`@nova/policy`) - included in Nova. Adds policy-backed doctor checks for workspace conformance.

- **[reef](/plugins/reference/reef)** (`@nova/reef`) - included in Nova. Guarded end-to-end encrypted claw channel.

- **[runway](/plugins/reference/runway)** (`@nova/runway-provider`) - included in Nova. Adds video generation provider support.

- **[senseaudio](/plugins/reference/senseaudio)** (`@nova/senseaudio-provider`) - included in Nova. Adds media understanding provider support.

- **[sglang](/plugins/reference/sglang)** (`@nova/sglang-provider`) - included in Nova. Adds SGLang model provider support to Nova.

- **[synthetic](/plugins/reference/synthetic)** (`@nova/synthetic-provider`) - included in Nova. Adds Synthetic model provider support to Nova.

- **[teams-meetings](/plugins/reference/teams-meetings)** (`@nova/teams-meetings`) - included in Nova. Join Microsoft Teams meetings as a Chrome browser guest.

- **[telegram](/plugins/reference/telegram)** (`@nova/telegram`) - included in Nova. Adds the Telegram channel surface for sending and receiving Nova messages.

- **[together](/plugins/reference/together)** (`@nova/together-provider`) - included in Nova. Adds Together model provider support to Nova.

- **[tts-local-cli](/plugins/reference/tts-local-cli)** (`@nova/tts-local-cli`) - included in Nova. Adds text-to-speech provider support.

- **[vault](/plugins/reference/vault)** (`@nova/vault`) - included in Nova. HashiCorp Vault SecretRef provider integration.

- **[vllm](/plugins/reference/vllm)** (`@nova/vllm-provider`) - included in Nova. Adds vLLM model provider support to Nova.

- **[volcengine](/plugins/reference/volcengine)** (`@nova/volcengine-provider`) - included in Nova. Adds Volcengine, Volcengine Plan model provider support to Nova.

- **[voyage](/plugins/reference/voyage)** (`@nova/voyage-provider`) - included in Nova. Adds memory embedding provider support.

- **[vydra](/plugins/reference/vydra)** (`@nova/vydra-provider`) - included in Nova. Adds Vydra model provider support to Nova.

- **[web-readability](/plugins/reference/web-readability)** (`@nova/web-readability-plugin`) - included in Nova. Extract readable article content from local HTML web fetch responses.

- **[webhooks](/plugins/reference/webhooks)** (`@nova/webhooks`) - included in Nova. Authenticated inbound webhooks that bind external automation to Nova TaskFlows.

- **[workboard](/plugins/reference/workboard)** (`@nova/workboard`) - included in Nova. Dashboard workboard for agent-owned issues and sessions.

- **[xai](/plugins/reference/xai)** (`@nova/xai-plugin`) - included in Nova. Adds xAI model provider support to Nova.

- **[xiaomi](/plugins/reference/xiaomi)** (`@nova/xiaomi-provider`) - included in Nova. Adds Xiaomi, Xiaomi Token Plan model provider support to Nova.

- **[zoom-meetings](/plugins/reference/zoom-meetings)** (`@nova/zoom-meetings`) - included in Nova. Join Zoom meetings as a Chrome browser guest.

## Official external packages

72 plugins

- **[acpx](/plugins/reference/acpx)** (`@nova/acpx`) - npm; ClawHub. Nova ACP runtime backend with plugin-owned session and transport management.

- **[amazon-bedrock](/plugins/reference/amazon-bedrock)** (`@nova/amazon-bedrock-provider`) - npm; ClawHub. Nova Amazon Bedrock provider plugin with model discovery, embeddings, and guardrail support.

- **[amazon-bedrock-mantle](/plugins/reference/amazon-bedrock-mantle)** (`@nova/amazon-bedrock-mantle-provider`) - npm; ClawHub. Nova Amazon Bedrock Mantle provider plugin for OpenAI-compatible model routing.

- **[anthropic-vertex](/plugins/reference/anthropic-vertex)** (`@nova/anthropic-vertex-provider`) - npm; ClawHub. Nova Anthropic Vertex provider plugin for Claude models on Google Vertex AI.

- **[arcee](/plugins/reference/arcee)** (`@nova/arcee-provider`) - npm; ClawHub: `clawhub:@nova/arcee-provider`. Adds Arcee model provider support to Nova.

- **[baseten](/plugins/reference/baseten)** (`@nova/baseten-provider`) - npm; ClawHub: `clawhub:@nova/baseten-provider`. Nova Baseten provider plugin.

- **[brave](/plugins/reference/brave)** (`@nova/brave-plugin`) - npm; ClawHub. Nova Brave Search provider plugin for web search.

- **[cerebras](/plugins/reference/cerebras)** (`@nova/cerebras-provider`) - npm; ClawHub: `clawhub:@nova/cerebras-provider`. Adds Cerebras model provider support to Nova.

- **[chutes](/plugins/reference/chutes)** (`@nova/chutes-provider`) - npm; ClawHub: `clawhub:@nova/chutes-provider`. Adds Chutes model provider support to Nova.

- **[clickclack](/plugins/reference/clickclack)** (`@nova/clickclack`) - npm; ClawHub: `clawhub:@nova/clickclack`. Adds the Clickclack channel surface for sending and receiving Nova messages.

- **[cloudflare-ai-gateway](/plugins/reference/cloudflare-ai-gateway)** (`@nova/cloudflare-ai-gateway-provider`) - npm; ClawHub: `clawhub:@nova/cloudflare-ai-gateway-provider`. Adds Cloudflare AI Gateway model provider support to Nova.

- **[codex](/plugins/reference/codex)** (`@nova/codex`) - npm; ClawHub. Codex app-server harness and native session catalog.

- **[copilot](/plugins/reference/copilot)** (`@nova/copilot`) - npm; ClawHub: `clawhub:@nova/copilot`. Registers the GitHub Copilot agent runtime.

- **[deepinfra](/plugins/reference/deepinfra)** (`@nova/deepinfra-provider`) - npm; ClawHub: `clawhub:@nova/deepinfra-provider`. Adds DeepInfra model provider support to Nova.

- **[deepseek](/plugins/reference/deepseek)** (`@nova/deepseek-provider`) - npm; ClawHub: `clawhub:@nova/deepseek-provider`. Adds DeepSeek model provider support to Nova.

- **[diagnostics-otel](/plugins/reference/diagnostics-otel)** (`@nova/diagnostics-otel`) - npm; ClawHub: `clawhub:@nova/diagnostics-otel`. Nova diagnostics OpenTelemetry exporter for metrics, traces, and logs.

- **[diagnostics-prometheus](/plugins/reference/diagnostics-prometheus)** (`@nova/diagnostics-prometheus`) - npm; ClawHub: `clawhub:@nova/diagnostics-prometheus`. Nova diagnostics Prometheus exporter for runtime metrics.

- **[diffs](/plugins/reference/diffs)** (`@nova/diffs`) - npm; ClawHub. Nova read-only diff viewer plugin and file renderer for agents.

- **[diffs-language-pack](/plugins/reference/diffs-language-pack)** (`@nova/diffs-language-pack`) - npm; ClawHub: `clawhub:@nova/diffs-language-pack`. Adds syntax highlighting for languages outside the default diffs viewer set.

- **[discord](/plugins/reference/discord)** (`@nova/discord`) - npm; ClawHub. Nova Discord channel plugin for channels, DMs, commands, and app events.

- **[exa](/plugins/reference/exa)** (`@nova/exa-plugin`) - npm; ClawHub: `clawhub:@nova/exa-plugin`. Adds web search provider support.

- **[featherless](/plugins/reference/featherless)** (`@nova/featherless-provider`) - npm; ClawHub: `clawhub:@nova/featherless-provider`. Nova Featherless AI provider plugin.

- **[feishu](/plugins/reference/feishu)** (`@nova/feishu`) - npm; ClawHub. Nova Feishu/Lark channel plugin for chats and workplace tools (community maintained by @m1heng).

- **[firecrawl](/plugins/reference/firecrawl)** (`@nova/firecrawl-plugin`) - npm; ClawHub: `clawhub:@nova/firecrawl-plugin`. Adds agent-callable tools. Adds web fetch provider support. Adds web search provider support.

- **[fireworks](/plugins/reference/fireworks)** (`@nova/fireworks-provider`) - npm; ClawHub: `clawhub:@nova/fireworks-provider`. Adds Fireworks model provider support to Nova.

- **[gmi](/plugins/reference/gmi)** (`@nova/gmi-provider`) - npm; ClawHub: `clawhub:@nova/gmi-provider`. Nova GMI Cloud provider plugin.

- **[google-meet](/plugins/reference/google-meet)** (`@nova/google-meet`) - npm; ClawHub. Nova Google Meet participant plugin for joining calls through Chrome or Twilio transports.

- **[googlechat](/plugins/reference/googlechat)** (`@nova/googlechat`) - npm; ClawHub. Nova Google Chat channel plugin for spaces and direct messages.

- **[gradium](/plugins/reference/gradium)** (`@nova/gradium-speech`) - npm; ClawHub: `clawhub:@nova/gradium-speech`. Adds text-to-speech provider support.

- **[groq](/plugins/reference/groq)** (`@nova/groq-provider`) - npm; ClawHub: `clawhub:@nova/groq-provider`. Adds Groq model provider support to Nova.

- **[inworld](/plugins/reference/inworld)** (`@nova/inworld-speech`) - npm; ClawHub: `clawhub:@nova/inworld-speech`. Inworld streaming text-to-speech (MP3, OGG_OPUS, PCM telephony).

- **[irc](/plugins/reference/irc)** (`@nova/irc`) - npm; ClawHub: `clawhub:@nova/irc`. Adds the IRC channel surface for sending and receiving Nova messages.

- **[kilocode](/plugins/reference/kilocode)** (`@nova/kilocode-provider`) - npm; ClawHub: `clawhub:@nova/kilocode-provider`. Adds Kilocode model provider support to Nova.

- **[kimi](/plugins/reference/kimi)** (`@nova/kimi-provider`) - npm; ClawHub: `clawhub:@nova/kimi-provider`. Adds Kimi, Kimi Coding model provider support to Nova.

- **[line](/plugins/reference/line)** (`@nova/line`) - npm; ClawHub. Nova LINE channel plugin for LINE Bot API chats.

- **[llama-cpp](/plugins/reference/llama-cpp)** (`@nova/llama-cpp-provider`) - npm; ClawHub. Local GGUF text inference and embeddings through node-llama-cpp.

- **[lobster](/plugins/reference/lobster)** (`@nova/lobster`) - npm; ClawHub. Lobster workflow tool plugin for typed pipelines and resumable approvals.

- **[longcat](/plugins/reference/longcat)** (`@nova/longcat-provider`) - npm; ClawHub: `clawhub:@nova/longcat-provider`. Nova LongCat provider plugin.

- **[matrix](/plugins/reference/matrix)** (`@nova/matrix`) - ClawHub: `clawhub:@nova/matrix`; npm. Nova Matrix channel plugin for rooms and direct messages.

- **[mattermost](/plugins/reference/mattermost)** (`@nova/mattermost`) - npm; ClawHub: `clawhub:@nova/mattermost`. Adds the Mattermost channel surface for sending and receiving Nova messages.

- **[memory-lancedb](/plugins/reference/memory-lancedb)** (`@nova/memory-lancedb`) - npm; ClawHub. Nova LanceDB-backed long-term memory plugin with auto-recall, auto-capture, and vector search.

- **[moonshot](/plugins/reference/moonshot)** (`@nova/moonshot-provider`) - npm; ClawHub: `clawhub:@nova/moonshot-provider`. Adds Moonshot model provider support to Nova.

- **[msteams](/plugins/reference/msteams)** (`@nova/msteams`) - npm; ClawHub. Nova Microsoft Teams channel plugin for bot conversations.

- **[mxc](/plugins/reference/mxc)** (`@nova/mxc-sandbox`) - npm; ClawHub. OS-level sandboxed tool execution via MXC for MXC-capable Windows hosts: runs commands in ProcessContainer (Windows) with configured MXC policy files.

- **[nextcloud-talk](/plugins/reference/nextcloud-talk)** (`@nova/nextcloud-talk`) - npm; ClawHub. Nova Nextcloud Talk channel plugin for conversations.

- **[nostr](/plugins/reference/nostr)** (`@nova/nostr`) - npm; ClawHub. Nova Nostr channel plugin for NIP-04 encrypted direct messages.

- **[openshell](/plugins/reference/openshell)** (`@nova/openshell-sandbox`) - npm; ClawHub. Nova sandbox backend for the NVIDIA OpenShell CLI with mirrored local workspaces and SSH command execution.

- **[parallel](/tools/parallel-search)** (`@nova/parallel-plugin`) - npm; ClawHub: `clawhub:@nova/parallel-plugin`. Adds web search provider support.

- **[perplexity](/plugins/reference/perplexity)** (`@nova/perplexity-plugin`) - npm; ClawHub: `clawhub:@nova/perplexity-plugin`. Adds web search provider support.

- **[pixverse](/plugins/reference/pixverse)** (`@nova/pixverse-provider`) - npm; ClawHub: `clawhub:@nova/pixverse-provider`. Nova PixVerse video generation provider plugin.

- **[qianfan](/plugins/reference/qianfan)** (`@nova/qianfan-provider`) - npm; ClawHub: `clawhub:@nova/qianfan-provider`. Adds Qianfan model provider support to Nova.

- **[qqbot](/plugins/reference/qqbot)** (`@nova/qqbot`) - npm; ClawHub. Nova QQ Bot channel plugin for group and direct-message workflows.

- **[qwen](/plugins/reference/qwen)** (`@nova/qwen-provider`) - npm; ClawHub: `clawhub:@nova/qwen-provider`. Adds Qwen, Qwen Cloud, Model Studio, DashScope, Qwen Token Plan, Bailian Token Plan model provider support to Nova.

- **[raft](/plugins/reference/raft)** (`@nova/raft`) - npm; ClawHub. Nova Raft channel plugin for secure CLI wake bridges.

- **[searxng](/plugins/reference/searxng)** (`@nova/searxng-plugin`) - npm; ClawHub: `clawhub:@nova/searxng-plugin`. Adds web search provider support.

- **[signal](/plugins/reference/signal)** (`@nova/signal`) - npm; ClawHub: `clawhub:@nova/signal`. Adds the Signal channel surface for sending and receiving Nova messages.

- **[slack](/plugins/reference/slack)** (`@nova/slack`) - npm; ClawHub. Nova Slack channel plugin for channels, DMs, commands, and app events.

- **[sms](/plugins/reference/sms)** (`@nova/sms`) - npm; ClawHub: `clawhub:@nova/sms`. Twilio SMS channel plugin for Nova text messages.

- **[stepfun](/plugins/reference/stepfun)** (`@nova/stepfun-provider`) - npm; ClawHub: `clawhub:@nova/stepfun-provider`. Adds StepFun, StepFun Plan model provider support to Nova.

- **[synology-chat](/plugins/reference/synology-chat)** (`@nova/synology-chat`) - npm; ClawHub. Synology Chat channel plugin for Nova channels and direct messages.

- **[tavily](/plugins/reference/tavily)** (`@nova/tavily-plugin`) - npm; ClawHub: `clawhub:@nova/tavily-plugin`. Adds agent-callable tools. Adds web search provider support.

- **[tencent](/plugins/reference/tencent)** (`@nova/tencent-provider`) - npm; ClawHub: `clawhub:@nova/tencent-provider`. Adds Tencent TokenHub, Tencent Tokenplan model provider support to Nova.

- **[tlon](/plugins/reference/tlon)** (`@nova/tlon`) - npm; ClawHub. Nova Tlon/Urbit channel plugin for chat workflows.

- **[tokenjuice](/plugins/reference/tokenjuice)** (`@nova/tokenjuice`) - npm; ClawHub: `clawhub:@nova/tokenjuice`. Compacts exec and bash tool results with tokenjuice reducers.

- **[twitch](/plugins/reference/twitch)** (`@nova/twitch`) - npm; ClawHub. Nova Twitch channel plugin for chat and moderation workflows.

- **[venice](/plugins/reference/venice)** (`@nova/venice-provider`) - npm; ClawHub: `clawhub:@nova/venice-provider`. Adds Venice model provider support to Nova.

- **[vercel-ai-gateway](/plugins/reference/vercel-ai-gateway)** (`@nova/vercel-ai-gateway-provider`) - npm; ClawHub: `clawhub:@nova/vercel-ai-gateway-provider`. Adds Vercel AI Gateway model provider support to Nova.

- **[voice-call](/plugins/reference/voice-call)** (`@nova/voice-call`) - npm; ClawHub. Nova voice-call plugin for Twilio, Telnyx, and Plivo phone calls.

- **[whatsapp](/plugins/reference/whatsapp)** (`@nova/whatsapp`) - ClawHub: `clawhub:@nova/whatsapp`; npm. Nova WhatsApp channel plugin for WhatsApp Web chats.

- **[zai](/plugins/reference/zai)** (`@nova/zai-provider`) - npm; ClawHub: `clawhub:@nova/zai-provider`. Adds Z.AI model provider support to Nova.

- **[zalo](/plugins/reference/zalo)** (`@nova/zalo`) - npm; ClawHub. Nova Zalo channel plugin for bot and webhook chats.

- **[zalouser](/plugins/reference/zalouser)** (`@nova/zalouser`) - npm; ClawHub. Nova Zalo Personal Account plugin via native zca-js integration.

## Source checkout only

2 plugins

- **[qa-channel](/plugins/reference/qa-channel)** (`@nova/qa-channel`) - source checkout only. Adds the QA Channel surface for sending and receiving Nova messages.

- **[qa-lab](/plugins/reference/qa-lab)** (`@nova/qa-lab`) - source checkout only. Nova QA lab plugin with private debugger UI and scenario runner.
