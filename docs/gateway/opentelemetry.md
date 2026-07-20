---
summary: "Export Nova diagnostics to OpenTelemetry collectors or stdout JSONL via the diagnostics-otel plugin"
title: "OpenTelemetry export"
read_when:
  - You want to send Nova model usage, message flow, or session metrics to an OpenTelemetry collector
  - You are wiring traces, metrics, or logs into Grafana, Datadog, Honeycomb, New Relic, Tempo, or another OTLP backend
  - You need the exact metric names, span names, or attribute shapes to build dashboards or alerts
---

Nova exports diagnostics through the official `diagnostics-otel` plugin
using **OTLP/HTTP (protobuf)**. Logs can also be written as stdout JSONL for
container and sandbox log pipelines. Any collector or backend that accepts
OTLP/HTTP works without code changes. For local file logs, see
[Logging](/logging).

- **Diagnostics events** are structured, in-process records emitted by the
  Gateway and bundled plugins for model runs, message flow, sessions, queues,
  and exec.
- **`diagnostics-otel`** subscribes to those events and exports them as
  OpenTelemetry **metrics**, **traces**, and **logs** over OTLP/HTTP, and can
  mirror log records to stdout JSONL.
- **Provider calls** receive a W3C `traceparent` header from Nova's
  trusted model-call span context when the provider transport accepts custom
  headers. Plugin-emitted trace context is not propagated.
- Exporters attach only when both the diagnostics surface and the plugin are
  enabled, so in-process cost stays near zero by default.

## Quick start

```bash
nova plugins install clawhub:@nova/diagnostics-otel
```

```json5
{
  plugins: {
    allow: ["diagnostics-otel"],
    entries: {
      "diagnostics-otel": { enabled: true },
    },
  },
  diagnostics: {
    enabled: true,
    otel: {
      enabled: true,
      endpoint: "http://otel-collector:4318",
      protocol: "http/protobuf",
      serviceName: "nova-gateway",
      traces: true,
      metrics: true,
      logs: true,
      sampleRate: 0.2,
      flushIntervalMs: 60000,
    },
  },
}
```

Or enable the plugin from the CLI: `nova plugins enable diagnostics-otel`.

<Note>
`protocol` supports `http/protobuf` only. Since `traces` and `metrics` default to enabled, any other value (including `grpc`) aborts the entire diagnostics-otel subscription with an `unsupported protocol` warning - this also stops stdout log export. Explicitly set `traces: false` and `metrics: false` if you only want `logsExporter: "stdout"` with a non-OTLP protocol value.
</Note>

## Signals exported

| Signal      | What goes in it                                                                                                                                                                                              |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Metrics** | Counters/histograms for token usage, cost, run duration, failover, skill usage, message flow, Talk events, queue lanes, session state/recovery, tool execution, exec, memory, liveness, and exporter health. |
| **Traces**  | Spans for model usage, model calls, harness lifecycle, skill usage, tool execution, exec, webhook/message processing, context assembly, and tool loops.                                                      |
| **Logs**    | Structured `logging.file` records exported over OTLP or stdout JSONL when `diagnostics.otel.logs` is enabled; log bodies are withheld unless content capture is explicitly enabled.                          |

Toggle `traces`, `metrics`, and `logs` independently. Traces and metrics
default to on when `diagnostics.otel.enabled` is true; logs default to off
and export only when `diagnostics.otel.logs` is explicitly `true`. Log export
defaults to OTLP; set `diagnostics.otel.logsExporter` to `stdout` for JSONL on
stdout, or `both` for both.

## Configuration reference

```json5
{
  diagnostics: {
    enabled: true,
    otel: {
      enabled: true,
      endpoint: "http://otel-collector:4318",
      tracesEndpoint: "http://otel-collector:4318/v1/traces",
      metricsEndpoint: "http://otel-collector:4318/v1/metrics",
      logsEndpoint: "http://otel-collector:4318/v1/logs",
      protocol: "http/protobuf", // grpc disables OTLP export
      serviceName: "nova-gateway", // unset falls back to OTEL_SERVICE_NAME, then "nova"
      headers: { "x-collector-token": "..." },
      traces: true,
      metrics: true,
      logs: true,
      logsExporter: "otlp", // otlp | stdout | both
      sampleRate: 0.2, // root-span sampler, 0.0..1.0
      flushIntervalMs: 60000, // metric export interval (min 1000ms)
      captureContent: {
        enabled: false,
        inputMessages: false,
        outputMessages: false,
        toolInputs: false,
        toolOutputs: false,
        systemPrompt: false,
        toolDefinitions: false,
      },
    },
  },
}
```

### Environment variables

| Variable                                                                                                          | Purpose                                                                                                                                                                                                                                                                                                        |
| ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `OTEL_EXPORTER_OTLP_ENDPOINT`                                                                                     | Fallback for `diagnostics.otel.endpoint` when the config key is unset.                                                                                                                                                                                                                                         |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` / `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` / `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` | Signal-specific endpoint fallbacks used when the matching `diagnostics.otel.*Endpoint` config key is unset. Signal-specific config wins over signal-specific env, which wins over the shared endpoint.                                                                                                         |
| `OTEL_SERVICE_NAME`                                                                                               | Fallback for `diagnostics.otel.serviceName` when the config key is unset. Default service name is `nova`.                                                                                                                                                                                                      |
| `OTEL_EXPORTER_OTLP_PROTOCOL`                                                                                     | Fallback for the wire protocol when `diagnostics.otel.protocol` is unset. Only `http/protobuf` enables export.                                                                                                                                                                                                 |
| `OTEL_SEMCONV_STABILITY_OPT_IN`                                                                                   | Set to `gen_ai_latest_experimental` to emit the latest GenAI inference span shape: `{gen_ai.operation.name} {gen_ai.request.model}` span names, `CLIENT` span kind, and `gen_ai.provider.name` instead of the legacy `gen_ai.system`. GenAI metrics always use bounded, low-cardinality attributes regardless. |
| `NOVA_OTEL_PRELOADED`                                                                                             | Set to `1` when another preload or host process already registered the global OpenTelemetry SDK. The plugin then skips its own NodeSDK lifecycle but still wires diagnostic listeners and honors `traces`/`metrics`/`logs`.                                                                                    |

## Privacy and content capture

Raw model/tool content is **not** exported by default. Spans carry bounded
identifiers (channel, provider, model, error category, hash-only request ids,
tool source, tool owner, skill name/source) and never include prompt text,
response text, tool inputs, tool outputs, skill file paths, or session keys.
Values that look like scoped agent session keys (for example starting with
`agent:`) are replaced with `unknown` on low-cardinality attributes. OTLP log
records keep severity, logger, code location, trusted trace context, and
sanitized attributes by default; the raw log message body is exported only
when `diagnostics.otel.captureContent` is boolean `true`. Granular
`captureContent.*` subkeys never enable log bodies. Talk metrics export only
bounded event metadata (mode, transport, provider, event type) - no
transcripts, audio payloads, session ids, turn ids, call ids, room ids, or
handoff tokens.

Outbound model requests may include a W3C `traceparent` header generated only
from Nova-owned diagnostic trace context for the active model call.
Existing caller-supplied `traceparent` headers are replaced, so plugins or
custom provider options cannot spoof cross-service trace ancestry.

Set `diagnostics.otel.captureContent.*` to `true` only when your collector
and retention policy are approved for prompt, response, tool, or
system-prompt text. Each subkey is independent:

- `inputMessages` - user prompt content.
- `outputMessages` - model response content.
- `toolInputs` - tool argument payloads.
- `toolOutputs` - tool result payloads.
- `systemPrompt` - assembled system/developer prompt.
- `toolDefinitions` - model tool names, descriptions, and schemas.

When any subkey is enabled, model and tool spans get bounded, redacted
`nova.content.*` attributes for that class only.

<Note>
Boolean `captureContent: true` enables `inputMessages`, `outputMessages`, `toolInputs`, `toolOutputs`, `toolDefinitions`, and OTLP log bodies together, but **not** `systemPrompt` - set `captureContent.systemPrompt: true` explicitly if you also need the assembled system prompt.
</Note>

`toolInputs`/`toolOutputs` content is captured for the built-in agent
runtime's tool executions (`nova.content.tool_input` and
`gen_ai.tool.call.arguments` on completed/error spans;
`nova.content.tool_output` and `gen_ai.tool.call.result` on completed
spans). The `nova.content.*` names remain the stable Nova attribute
names; the `gen_ai.tool.call.*` copies mirror them for semconv-native viewers.
External harness tool calls (Codex, Claude CLI) emit
`tool.execution.*` spans without content payloads. Captured content travels on a
trusted, listener-only channel and is never placed on the public diagnostic event
bus.

## Sampling and flushing

- **Traces:** `diagnostics.otel.sampleRate` sets a `TraceIdRatioBasedSampler`
  on the root span only (`0.0` drops all, `1.0` keeps all). Unset uses the
  OpenTelemetry SDK default (always-on).
- **Metrics:** `diagnostics.otel.flushIntervalMs` (clamped to a minimum of
  `1000`); unset uses the SDK's periodic-export default.
- **Logs:** OTLP logs respect `logging.level` (file log level) and use the
  diagnostic log-record redaction path, not console formatting. High-volume
  installs should prefer OTLP collector sampling/filtering over local
  sampling. Set `diagnostics.otel.logsExporter: "stdout"` when your platform
  already ships stdout/stderr to a log processor and you have no OTLP logs
  collector. Stdout records are one JSON object per line with `ts`, `signal`,
  `service.name`, severity, body, redacted attributes, and trusted trace
  fields when available.
- **File-log correlation:** JSONL file logs include top-level `traceId`,
  `spanId`, `parentSpanId`, and `traceFlags` when the log call carries a valid
  diagnostic trace context, letting log processors join local log lines with
  exported spans.
- **Request correlation:** Gateway HTTP requests and WebSocket frames create
  an internal request trace scope. Logs and diagnostic events inside that
  scope inherit the request trace by default, while agent run and model-call
  spans are created as children so provider `traceparent` headers stay on the
  same trace.
- **Model-call correlation:** `nova.model.call` spans include safe prompt
  component sizes by default and per-call token attributes when the provider
  result exposes usage. `nova.model.usage` remains the run-level
  accounting span for aggregate cost, context, and channel dashboards, and
  stays on the same diagnostic trace when the emitting runtime has trusted
  trace context.

### Model-call observation units

Every `nova.model.call` span identifies what its lifecycle measures through
`nova.model_call.observation_unit`:

- `request` - one observable model/provider request. Native embedded model
  calls use this unit, and exporters treat a missing value as `request` for
  compatibility with older or external emitters.
- `turn` - one opaque agent CLI turn that may contain hidden model requests,
  retries, tool work, or background work. Claude Code CLI and Codex app-server
  calls use this unit.

Both units remain model-call spans so trace backends can render model input,
output, usage, and hierarchy. Request spans use the API-derived GenAI operation
(`chat`, `generate_content`, or `text_completion`), while turn spans use
`gen_ai.operation.name = invoke_agent`. Both contribute to
`gen_ai.client.operation.duration`, where the operation name keeps direct
request latency separate from full-turn latency. Nova's OTEL model-call
metrics also include `nova.model_call.observation_unit`; the Prometheus
model-call metrics expose the equivalent `observation_unit` label.

### Claude Code CLI model-call fidelity

Claude Code CLI turns emit one synthetic, turn-level `nova.model.call`
span. These are not Anthropic HTTP request spans. They use `nova.api =
claude-code`, `nova.model_call.observation_unit = turn`, and identify
the operation as `gen_ai.operation.name = invoke_agent`. They identify
Nova's CLI boundary through
`nova.transport`:

- `stdio` - one-shot local Claude Code process.
- `stdio-live` - one turn on a managed persistent Claude stdio session.
- `paired-node-cli` - one-shot Claude Code execution delegated to a paired
  node.

Claude CLI diagnostics are instantiated only while the process diagnostic
dispatcher is enabled and an internal or trusted event listener is attached.
With no observability plugin or other listener active, Claude CLI turns skip
the synthetic trace hierarchy, content buffers, and diagnostic stream-byte
accounting. When content capture is enabled, prompt and system-prompt fields
are capped at 128 KiB each; assistant output is capped at 128 KiB across at
most 200 envelopes, with 16 KiB and one item reserved for a final visible
fallback response. A marker records truncation when the limit is reached.

Nova gives Claude CLI turns the same ownership hierarchy used by other
agent runtimes: `nova.harness.run` (`nova.harness.id = claude-cli`)
contains `nova.run`, which contains the Claude `nova.model.call`
span. The harness and run spans are synthetic Nova turn boundaries, not
Claude Code internal phases. One-shot and managed stdio turns use the same
hierarchy; a real fresh-session retry creates another model-call child inside
the same Nova run.

The span starts when Nova admits the prepared CLI turn and ends only after
that turn succeeds or fails. For managed sessions, an interim success result
does not end the span while Claude reports result-holding background agents or
workflows; the final post-drain result does. Abort, timeout, process failure,
output/parse failure, and other turn failures end the same span with an error.

Claude Code reports per-assistant-message usage and may also report cumulative
usage on its terminal result. Nova reply accounting continues to use the
last assistant message so existing cost semantics do not change; the
turn-level model-call span uses terminal cumulative usage when available,
including cache-read and cache-creation tokens.

For these CLI spans, byte and timing fields describe the observable Nova
CLI boundary:

- `nova.model_call.request_bytes` is the UTF-8 size of the prompt value
  sent over one-shot stdin/argv, or the managed stdio JSONL user envelope. It
  is not the size of Claude Code's hidden model request.
- `nova.model_call.response_bytes` is the UTF-8 size of Claude CLI stdout
  observed during the turn. It is not Anthropic HTTP response size.
- `nova.model_call.time_to_first_byte_ms` is time to the first observable
  Claude CLI stdout or stderr output. It is not network TTFB.

With the matching granular `captureContent` fields enabled, the span exports
the effective prompt Nova sends to Claude Code, Nova's appended system
prompt, and visible assistant text/reasoning/tool-call identity through
`gen_ai.input.messages`, `gen_ai.output.messages`, and
`gen_ai.system_instructions`. Tool arguments, opaque thinking signatures, and
tool results are omitted from the Claude assistant envelope. Nova does not
claim access to Claude Code's private system prompt, hidden resumed or
compacted request payload, native internal tool schemas, raw Anthropic HTTP
request, internal retries, upstream request id, or true network TTFB. Because
Claude Code does not expose its effective native tool definitions accurately,
these spans do not populate `gen_ai.tool.definitions`.

External Claude harness tool spans remain metadata-only even when tool content
capture is enabled. As with every model span, captured Claude CLI content uses
the trusted listener-only path and the exporter's existing redaction and size
bounds; content remains off by default.

## Exported metrics

### Model usage

- `nova.tokens` (counter, attrs: `nova.token`, `nova.channel`, `nova.provider`, `nova.model`, `nova.agent`)
- `nova.cost.usd` (counter, attrs: `nova.channel`, `nova.provider`, `nova.model`)
- `nova.run.duration_ms` (histogram, attrs: `nova.channel`, `nova.provider`, `nova.model`)
- `nova.context.tokens` (histogram, attrs: `nova.context`, `nova.channel`, `nova.provider`, `nova.model`)
- `gen_ai.client.token.usage` (histogram, GenAI semantic-conventions metric, attrs: `gen_ai.token.type` = `input`/`output`, `gen_ai.provider.name`, `gen_ai.operation.name`, `gen_ai.request.model`)
- `gen_ai.client.operation.duration` (histogram, seconds, GenAI semantic-conventions metric for model requests and synthetic agent turns; attrs: `gen_ai.provider.name`, `gen_ai.operation.name`, `gen_ai.request.model`, optional `error.type`; turn observations use `gen_ai.operation.name = invoke_agent`)
- `nova.model_call.duration_ms` (histogram, attrs: `nova.provider`, `nova.model`, `nova.api`, `nova.transport`, `nova.model_call.observation_unit`, plus `nova.errorCategory` and `nova.failureKind` on classified errors)
- `nova.model_call.request_bytes` (histogram, UTF-8 byte size of the final model request payload; for Claude Code CLI, the observable prompt input/envelope described above; no raw payload content)
- `nova.model_call.response_bytes` (histogram, UTF-8 byte size of streamed response chunk payloads; high-frequency text, thinking, and tool-call deltas count only incremental `delta` bytes; for Claude Code CLI, observed stdout bytes; no raw response content)
- `nova.model_call.time_to_first_byte_ms` (histogram, elapsed time before the first streamed response event; for Claude Code CLI, first observable CLI output rather than network TTFB)
- `nova.model.failover` (counter, attrs: `nova.provider`, `nova.model`, `nova.failover.to_provider`, `nova.failover.to_model`, `nova.failover.reason`, `nova.failover.suspended`, `nova.lane`)
- `nova.skill.used` (counter, attrs: `nova.skill.name`, `nova.skill.source`, `nova.skill.activation`, optional `nova.agent`, optional `nova.toolName`)

### Message flow

- `nova.webhook.received` (counter, attrs: `nova.channel`, `nova.webhook`)
- `nova.webhook.error` (counter, attrs: `nova.channel`, `nova.webhook`)
- `nova.webhook.duration_ms` (histogram, attrs: `nova.channel`, `nova.webhook`)
- `nova.message.queued` (counter, attrs: `nova.channel`, `nova.source`)
- `nova.message.received` (counter, attrs: `nova.channel`, `nova.source`)
- `nova.message.dispatch.started` (counter, attrs: `nova.channel`, `nova.source`)
- `nova.message.dispatch.completed` (counter, attrs: `nova.channel`, `nova.outcome`, `nova.reason`, `nova.source`)
- `nova.message.dispatch.duration_ms` (histogram, attrs: `nova.channel`, `nova.outcome`, `nova.reason`, `nova.source`)
- `nova.message.processed` (counter, attrs: `nova.channel`, `nova.outcome`)
- `nova.message.duration_ms` (histogram, attrs: `nova.channel`, `nova.outcome`)
- `nova.message.delivery.started` (counter, attrs: `nova.channel`, `nova.delivery.kind`)
- `nova.message.delivery.duration_ms` (histogram, attrs: `nova.channel`, `nova.delivery.kind`, `nova.outcome`, `nova.errorCategory`)

### Talk

- `nova.talk.event` (counter, attrs: `nova.talk.event_type`, `nova.talk.mode`, `nova.talk.transport`, `nova.talk.brain`, `nova.talk.provider`)
- `nova.talk.event.duration_ms` (histogram, attrs: same as `nova.talk.event`; emitted when a Talk event reports duration)
- `nova.talk.audio.bytes` (histogram, attrs: same as `nova.talk.event`; emitted for Talk audio frame events that report byte length)

### Queues and sessions

- `nova.queue.lane.enqueue` (counter, attrs: `nova.lane`)
- `nova.queue.lane.dequeue` (counter, attrs: `nova.lane`)
- `nova.queue.depth` (histogram, attrs: `nova.lane` or `nova.channel=heartbeat`)
- `nova.queue.wait_ms` (histogram, attrs: `nova.lane`)
- `nova.session.state` (counter, attrs: `nova.state`, `nova.reason`)
- `nova.session.stuck` (counter, attrs: `nova.state`; emitted for recoverable stale session bookkeeping)
- `nova.session.stuck_age_ms` (histogram, attrs: `nova.state`; emitted for recoverable stale session bookkeeping)
- `nova.session.turn.created` (counter, attrs: `nova.agent`, `nova.channel`, `nova.trigger`)
- `nova.session.recovery.requested` (counter, attrs: `nova.state`, `nova.action`, `nova.active_work_kind`, `nova.reason`)
- `nova.session.recovery.completed` (counter, attrs: `nova.state`, `nova.action`, `nova.status`, `nova.active_work_kind`, `nova.reason`)
- `nova.session.recovery.age_ms` (histogram, attrs: same as the matching recovery counter)
- `nova.run.attempt` (counter, attrs: `nova.attempt`)

### Session liveness telemetry

A `processing` session does not age toward the built-in liveness threshold while Nova observes reply, tool, status, block, or ACP runtime progress. Typing keepalives do not count as progress, so a silent model or harness can still be detected.

Nova classifies sessions by the work it can still observe:

- `session.long_running`: active embedded work, model calls, or tool calls
  are still making progress. Owned silent model calls also report as long-running before the built-in abort threshold, so slow or non-streaming model providers do not look like stalled gateway sessions while abort-observable.
- `session.stalled`: active work exists, but the active run has not reported
  recent progress. Owned model calls switch from `session.long_running` to
  `session.stalled` at or after the built-in abort threshold; ownerless
  stale model/tool activity is not treated as harmless long-running work.
  Stalled embedded runs stay observe-only at first, then abort-drain after
  the abort threshold with no progress so queued turns behind the lane can resume.
- `session.stuck`: stale session bookkeeping with no active work, or an idle
  queued session with stale ownerless model/tool activity. This releases the
  affected session lane immediately after recovery gates pass.

Recovery emits structured `session.recovery.requested` and
`session.recovery.completed` events. Diagnostic session state is marked idle
only after a mutating recovery outcome (`aborted` or `released`) and only if
the same processing generation is still current.

Only `session.stuck` emits the `nova.session.stuck` counter, the
`nova.session.stuck_age_ms` histogram, and the `nova.session.stuck`
span. Repeated `session.stuck` diagnostics back off while the session remains
unchanged, so dashboards should alert on sustained increases rather than
every heartbeat tick. For the config knob and defaults, see
[Configuration reference](/gateway/configuration-reference#diagnostics).

Liveness warnings also emit:

- `nova.liveness.warning` (counter, attrs: `nova.liveness.reason`)
- `nova.liveness.event_loop_delay_p99_ms` (histogram, attrs: `nova.liveness.reason`)
- `nova.liveness.event_loop_delay_max_ms` (histogram, attrs: `nova.liveness.reason`)
- `nova.liveness.event_loop_utilization` (histogram, attrs: `nova.liveness.reason`)
- `nova.liveness.cpu_core_ratio` (histogram, attrs: `nova.liveness.reason`)

### Harness lifecycle

- `nova.harness.duration_ms` (histogram, attrs: `nova.harness.id`, `nova.harness.plugin`, `nova.outcome`, `nova.harness.phase` on errors)

### Tool execution and loop detection

- `nova.tool.execution.duration_ms` (histogram, attrs: `gen_ai.tool.name`, `nova.toolName`, `nova.tool.source`, `nova.tool.owner`, `nova.tool.params.kind`, plus `nova.errorCategory` on errors)
- `nova.tool.execution.blocked` (counter, attrs: `gen_ai.tool.name`, `nova.toolName`, `nova.tool.source`, `nova.tool.owner`, `nova.tool.params.kind`, `nova.deniedReason`)
- `nova.tool.loop` (counter, attrs: `nova.toolName`, `nova.loop.level`, `nova.loop.action`, `nova.loop.detector`, `nova.loop.count`, optional `nova.loop.paired_tool`; emitted when a repetitive tool-call loop is detected)

### Exec

- `nova.exec.duration_ms` (histogram, attrs: `nova.exec.target`, `nova.exec.mode`, `nova.outcome`, `nova.failureKind`)

### Diagnostics internals (memory, payloads, exporter health)

- `nova.payload.large` (counter, attrs: `nova.payload.surface`, `nova.payload.action`, `nova.channel`, `nova.plugin`, `nova.reason`)
- `nova.payload.large_bytes` (histogram, attrs: same as `nova.payload.large`)
- `nova.memory.rss_bytes` / `nova.memory.heap_used_bytes` / `nova.memory.heap_total_bytes` / `nova.memory.external_bytes` / `nova.memory.array_buffers_bytes` (histograms, no attrs; process memory samples)
- `nova.memory.pressure` (counter, attrs: `nova.memory.level`, `nova.memory.reason`)
- `nova.diagnostic.async_queue.dropped` (counter, attrs: `nova.diagnostic.async_queue.drop_class`; internal diagnostic-queue backpressure drops)
- `nova.telemetry.exporter.events` (counter, attrs: `nova.exporter`, `nova.signal`, `nova.status`, optional `nova.reason`, optional `nova.errorCategory`; exporter lifecycle/failure self-telemetry)

## Exported spans

- `nova.model.usage`
  - `nova.channel`, `nova.provider`, `nova.model`
  - `nova.tokens.*` (input/output/cache_read/cache_write/total)
  - `gen_ai.system` by default, or `gen_ai.provider.name` when the latest GenAI semantic conventions are opted in
  - `gen_ai.request.model`, `gen_ai.operation.name`, `gen_ai.usage.*`
- `nova.run`
  - `nova.outcome`, `nova.channel`, `nova.provider`, `nova.model`, `nova.errorCategory`
- `nova.model.call`
  - `gen_ai.system` by default, or `gen_ai.provider.name` when the latest GenAI semantic conventions are opted in
  - `gen_ai.request.model`, `gen_ai.operation.name`, `nova.provider`, `nova.model`, `nova.api`, `nova.transport`, `nova.model_call.observation_unit` (`request` or `turn`)
  - `nova.errorCategory`, `error.type`, and optional `nova.failureKind` on errors
  - `nova.model_call.request_bytes`, `nova.model_call.response_bytes`, `nova.model_call.time_to_first_byte_ms`
  - `nova.model_call.prompt.input_messages_count`, `nova.model_call.prompt.input_messages_chars`, `nova.model_call.prompt.system_prompt_chars`, `nova.model_call.prompt.tool_definitions_count`, `nova.model_call.prompt.tool_definitions_chars`, `nova.model_call.prompt.total_chars` (safe component sizes only, no prompt text)
  - `nova.model_call.usage.*` and `gen_ai.usage.*` when the result carries usage for that request or aggregate turn
  - Span event `nova.provider.request` with attribute `nova.upstreamRequestIdHash` (bounded, hash-based) when the upstream provider result exposes a request id; raw ids are never exported
  - With `OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental`, request spans use the latest GenAI inference span name `{gen_ai.operation.name} {gen_ai.request.model}`. Turn spans use `invoke_agent` because Nova does not claim a native agent name from the opaque CLI boundary. Both use `CLIENT` span kind instead of `nova.model.call`.
- `nova.harness.run`
  - `nova.harness.id`, `nova.harness.plugin`, `nova.outcome`, `nova.provider`, `nova.model`, `nova.channel`
  - On completion: `nova.harness.result_classification`, `nova.harness.yield_detected`, `nova.harness.items.started`, `nova.harness.items.completed`, `nova.harness.items.active`
  - On error: `nova.harness.phase`, `nova.errorCategory`, optional `nova.harness.cleanup_failed`
- `nova.tool.execution`
  - `gen_ai.tool.name`, `gen_ai.operation.name` (`execute_tool`), `nova.toolName`, `nova.tool.source`, optional `gen_ai.tool.call.id`, `nova.tool.owner`, `nova.tool.params.*`
  - Optional `nova.errorCategory`/`nova.errorCode` on errors, `nova.deniedReason` and `nova.outcome=blocked` when denied by policy or sandbox
- `nova.exec`
  - `nova.exec.target`, `nova.exec.mode`, `nova.outcome`, `nova.failureKind`, `nova.exec.command_length`, `nova.exec.exit_code`, `nova.exec.exit_signal`, `nova.exec.timed_out`
- `nova.webhook.processed`
  - `nova.channel`, `nova.webhook`
- `nova.webhook.error`
  - `nova.channel`, `nova.webhook`, `nova.error`
- `nova.message.processed`
  - `nova.channel`, `nova.outcome`, `nova.reason`
- `nova.message.delivery`
  - `nova.channel`, `nova.delivery.kind`, `nova.outcome`, `nova.errorCategory`, `nova.delivery.result_count`
- `nova.session.stuck`
  - `nova.state`, `nova.ageMs`, `nova.queueDepth`
- `nova.context.assembled`
  - `nova.prompt.size`, `nova.history.size`, `nova.context.tokens`, `nova.errorCategory` (no prompt, history, response, or session-key content)
- `nova.tool.loop`
  - `nova.toolName`, `nova.loop.level`, `nova.loop.action`, `nova.loop.detector`, `nova.loop.count`, optional `nova.loop.paired_tool` (no loop messages, params, or tool output)
- `nova.memory.pressure`
  - `nova.memory.level`, `nova.memory.reason`, `nova.memory.rss_bytes`, `nova.memory.heap_used_bytes`, `nova.memory.heap_total_bytes`, `nova.memory.external_bytes`, `nova.memory.array_buffers_bytes`, optional `nova.memory.threshold_bytes`/`nova.memory.rss_growth_bytes`/`nova.memory.window_ms`

When content capture is explicitly enabled, model and tool spans can also
include bounded, redacted `nova.content.*` attributes for the specific
content classes you opted into.

## Diagnostic event catalog

The events below back the metrics and spans above or are available for direct
plugin subscription. `run.progress` and `run.execution_phase` are direct-only
lifecycle signals; the diagnostics-otel plugin does not export them as
standalone OTLP signals. Event kinds and `run.execution_phase.phase` values are
additive. TypeScript consumers should keep default branches instead of assuming
either union is permanently exhaustive.

**Model usage**

- `model.usage` - tokens, cost, duration, context, provider/model/channel,
  session ids. `usage` is provider/turn accounting for cost and telemetry;
  `context.used` is the current prompt/context snapshot and can be lower than
  provider `usage.total` when cached input or tool-loop calls are involved.

**Message flow**

- `webhook.received` / `webhook.processed` / `webhook.error`
- `message.queued` / `message.processed`
- `message.delivery.started` / `message.delivery.completed` / `message.delivery.error`

**Queue and session**

- `queue.lane.enqueue` / `queue.lane.dequeue`
- `session.state` / `session.long_running` / `session.stalled` / `session.stuck`
- `run.attempt` / `run.progress`
- `run.execution_phase` (public, session-correlated embedded-runner startup milestones)
- `diagnostic.heartbeat` (aggregate counters: webhooks/queue/session)

**Harness lifecycle**

- `harness.run.started` / `harness.run.completed` / `harness.run.error` -
  per-run lifecycle for the agent harness. Includes `harnessId`, optional
  `pluginId`, provider/model/channel, and run id. Completion adds
  `durationMs`, `outcome`, optional `resultClassification`, `yieldDetected`,
  and `itemLifecycle` counts. Errors add `phase`
  (`prepare`/`start`/`send`/`resolve`/`cleanup`), `errorCategory`, and
  optional `cleanupFailed`.

**Exec**

- `exec.process.completed` - terminal outcome, duration, target, mode, exit
  code, and failure kind. Command text and working directories are not
  included.
- `exec.approval.followup_suppressed` - stale approval follow-up dropped
  after a session rebound. Includes `approvalId`, `reason`
  (`session_rebound`), `phase` (`direct_delivery` or `gateway_preflight`),
  and the dispatcher timestamp. Session keys, routes, and command text are
  not included.

## Without an exporter

Keep diagnostics events available to plugins or custom sinks without running
`diagnostics-otel`:

```json5
{
  diagnostics: { enabled: true },
}
```

For targeted debug output without raising `logging.level`, use diagnostics
flags. Flags are case-insensitive and support wildcards (`telegram.*` or
`*`):

```json5
{
  diagnostics: { flags: ["telegram.http"] },
}
```

Or as a one-off env override:

```bash
NOVA_DIAGNOSTICS=telegram.http,telegram.payload nova gateway
```

Flag output goes to the standard log file (`logging.file`) and is still
redacted by `logging.redactSensitive`. Full guide:
[Diagnostics flags](/diagnostics/flags).

## Disable

```json5
{
  diagnostics: { otel: { enabled: false } },
}
```

Or leave `diagnostics-otel` out of `plugins.allow`, or run
`nova plugins disable diagnostics-otel`.

## Related

- [Logging](/logging) - file logs, console output, CLI tailing, and the Control UI Logs tab
- [Gateway logging internals](/gateway/logging) - WS log styles, subsystem prefixes, and console capture
- [Diagnostics flags](/diagnostics/flags) - targeted debug-log flags
- [Diagnostics export](/gateway/diagnostics) - operator support-bundle tool (separate from OTEL export)
- [Configuration reference](/gateway/configuration-reference#diagnostics) - full `diagnostics.*` field reference
