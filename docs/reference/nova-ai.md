---
summary: "The @nova/ai npm package: reusable model transports, isolated runtimes, and host policy ports"
title: "@nova/ai package"
read_when:
  - You want to reuse Nova's model transports in another application
  - You are changing packages/ai or the AI transport host ports
  - You are reviewing what the nova release publishes to npm besides the root package
---

`@nova/ai` is the publishable library form of Nova's model execution
layer: provider-neutral message/tool/stream contracts, validation, diagnostics,
event streams, an isolated runtime registry, and lazy adapters for the eight
built-in API families (Anthropic Messages, OpenAI Completions, OpenAI
Responses, Azure OpenAI Responses, ChatGPT/Codex Responses, Google Generative
AI, Google Vertex, Mistral Conversations).

It publishes alongside the root `nova` package on every release, pinned to
the same version, with its own `npm-shrinkwrap.json` so its transitive
dependency tree is locked at install time. Installing `nova` installs the
matching `@nova/ai` automatically; library consumers can depend on it
directly without any Nova application code.

## Quick start

```js
import { createLlmRuntime } from "@nova/ai";
import { registerBuiltInApiProviders } from "@nova/ai/providers";

const runtime = createLlmRuntime();
registerBuiltInApiProviders(runtime.registry);

const stream = runtime.streamSimple(model, { messages }, { apiKey });
for await (const event of stream) {
  if (event.type === "text_delta") process.stdout.write(event.delta);
}
const result = await stream.result();
```

A runnable version lives in the repository at `examples/ai-chat`.

## Design contract

- **Instance-scoped by default.** Importing the package registers nothing
  globally. `createApiRegistry()` / `createLlmRuntime()` return isolated
  instances; `registerBuiltInApiProviders(registry)` opts one registry into the
  built-in transports. Provider SDK modules load lazily on first use.
- **Host policy is injected, not bundled.** Request fetch guarding (for
  example SSRF policy), secret redaction of tool-result replay text, OpenAI
  strict-tool defaults, and diagnostics logging are `AiTransportHost` ports
  configured with `configureAiTransportHost`. The library defaults are inert;
  Nova installs its real implementations in its stream facade.
- **One event-stream identity.** `@nova/ai/event-stream` is the canonical
  `EventStream` constructor shared by Nova core, agent-core, and external
  consumers.
- **`internal/*` subpaths are not API.** They exist for the Nova
  application itself and carry no semver guarantee.
- Provider ids, credentials, model catalogs, retries, and failover remain
  application concerns. Nova layers those around this package; a library
  consumer supplies a `Model` object and options directly.

## Subpath exports

| Subpath          | Contents                                                                       |
| ---------------- | ------------------------------------------------------------------------------ |
| `.`              | Contracts, `createApiRegistry`, `createLlmRuntime`, `configureAiTransportHost` |
| `./providers`    | `registerBuiltInApiProviders`, `resetApiProviders`                             |
| `./types`        | Model/message/tool/stream types                                                |
| `./validation`   | Tool argument validation                                                       |
| `./diagnostics`  | Diagnostics contracts                                                          |
| `./event-stream` | Shared `EventStream` implementation                                            |
| `./internal/*`   | Nova-internal, no semver guarantee                                             |
