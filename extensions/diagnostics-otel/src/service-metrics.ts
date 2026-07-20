import type { Meter } from "@opentelemetry/api";
import {
  AGENT_DURATION_MS_BUCKETS,
  CONTEXT_TOKENS_BUCKETS,
  GEN_AI_OPERATION_DURATION_BUCKETS,
  GEN_AI_TOKEN_USAGE_BUCKETS,
} from "./service-constants.js";

export function createDiagnosticsMetrics(meter: Meter) {
  const tokensCounter = meter.createCounter("nova.tokens", {
    unit: "1",
    description: "Token usage by type",
  });
  const genAiTokenUsageHistogram = meter.createHistogram("gen_ai.client.token.usage", {
    unit: "{token}",
    description: "Number of input and output tokens used by GenAI client operations",
    advice: {
      explicitBucketBoundaries: GEN_AI_TOKEN_USAGE_BUCKETS,
    },
  });
  const genAiOperationDurationHistogram = meter.createHistogram(
    "gen_ai.client.operation.duration",
    {
      unit: "s",
      description: "GenAI client operation duration",
      advice: {
        explicitBucketBoundaries: GEN_AI_OPERATION_DURATION_BUCKETS,
      },
    },
  );
  const costCounter = meter.createCounter("nova.cost.usd", {
    unit: "1",
    description: "Estimated model cost (USD)",
  });
  const durationHistogram = meter.createHistogram("nova.run.duration_ms", {
    unit: "ms",
    description: "Agent run duration",
    advice: { explicitBucketBoundaries: AGENT_DURATION_MS_BUCKETS },
  });
  const harnessDurationHistogram = meter.createHistogram("nova.harness.duration_ms", {
    unit: "ms",
    description: "Agent harness lifecycle duration",
    advice: { explicitBucketBoundaries: AGENT_DURATION_MS_BUCKETS },
  });
  const contextHistogram = meter.createHistogram("nova.context.tokens", {
    unit: "1",
    description: "Context window size and usage",
    advice: { explicitBucketBoundaries: CONTEXT_TOKENS_BUCKETS },
  });
  const webhookReceivedCounter = meter.createCounter("nova.webhook.received", {
    unit: "1",
    description: "Webhook requests received",
  });
  const webhookErrorCounter = meter.createCounter("nova.webhook.error", {
    unit: "1",
    description: "Webhook processing errors",
  });
  const webhookDurationHistogram = meter.createHistogram("nova.webhook.duration_ms", {
    unit: "ms",
    description: "Webhook processing duration",
  });
  const messageQueuedCounter = meter.createCounter("nova.message.queued", {
    unit: "1",
    description: "Messages queued for processing",
  });
  const messageReceivedCounter = meter.createCounter("nova.message.received", {
    unit: "1",
    description: "Inbound messages received",
  });
  const messageDispatchStartedCounter = meter.createCounter("nova.message.dispatch.started", {
    unit: "1",
    description: "Inbound message dispatch attempts started",
  });
  const messageDispatchCompletedCounter = meter.createCounter("nova.message.dispatch.completed", {
    unit: "1",
    description: "Inbound message dispatch attempts completed",
  });
  const messageDispatchDurationHistogram = meter.createHistogram(
    "nova.message.dispatch.duration_ms",
    {
      unit: "ms",
      description: "Inbound message dispatch duration",
    },
  );
  const messageProcessedCounter = meter.createCounter("nova.message.processed", {
    unit: "1",
    description: "Messages processed by outcome",
  });
  const messageDurationHistogram = meter.createHistogram("nova.message.duration_ms", {
    unit: "ms",
    description: "Message processing duration",
  });
  const messageDeliveryStartedCounter = meter.createCounter("nova.message.delivery.started", {
    unit: "1",
    description: "Outbound message delivery attempts started",
  });
  const messageDeliveryDurationHistogram = meter.createHistogram(
    "nova.message.delivery.duration_ms",
    {
      unit: "ms",
      description: "Outbound message delivery duration",
    },
  );
  const queueDepthHistogram = meter.createHistogram("nova.queue.depth", {
    unit: "1",
    description: "Queue depth on enqueue/dequeue",
  });
  const queueWaitHistogram = meter.createHistogram("nova.queue.wait_ms", {
    unit: "ms",
    description: "Queue wait time before execution",
  });
  const laneEnqueueCounter = meter.createCounter("nova.queue.lane.enqueue", {
    unit: "1",
    description: "Command queue lane enqueue events",
  });
  const laneDequeueCounter = meter.createCounter("nova.queue.lane.dequeue", {
    unit: "1",
    description: "Command queue lane dequeue events",
  });
  const sessionStateCounter = meter.createCounter("nova.session.state", {
    unit: "1",
    description: "Session state transitions",
  });
  const sessionTurnCreatedCounter = meter.createCounter("nova.session.turn.created", {
    unit: "1",
    description: "Agent session turns created",
  });
  const sessionStuckCounter = meter.createCounter("nova.session.stuck", {
    unit: "1",
    description: "Sessions stuck in processing",
  });
  const sessionStuckAgeHistogram = meter.createHistogram("nova.session.stuck_age_ms", {
    unit: "ms",
    description: "Age of stuck sessions",
  });
  const sessionRecoveryRequestedCounter = meter.createCounter("nova.session.recovery.requested", {
    unit: "1",
    description: "Session recovery attempts requested",
  });
  const sessionRecoveryCompletedCounter = meter.createCounter("nova.session.recovery.completed", {
    unit: "1",
    description: "Session recovery attempts completed",
  });
  const sessionRecoveryAgeHistogram = meter.createHistogram("nova.session.recovery.age_ms", {
    unit: "ms",
    description: "Age of sessions selected for recovery",
  });
  const talkEventCounter = meter.createCounter("nova.talk.event", {
    unit: "1",
    description: "Talk events emitted by type",
  });
  const talkEventDurationHistogram = meter.createHistogram("nova.talk.event.duration_ms", {
    unit: "ms",
    description: "Talk event duration when reported",
  });
  const talkAudioBytesHistogram = meter.createHistogram("nova.talk.audio.bytes", {
    unit: "By",
    description: "Talk audio frame byte lengths",
  });
  const runAttemptCounter = meter.createCounter("nova.run.attempt", {
    unit: "1",
    description: "Run attempts",
  });
  const toolLoopCounter = meter.createCounter("nova.tool.loop", {
    unit: "1",
    description: "Detected repetitive tool-call loop events",
  });
  const skillUsedCounter = meter.createCounter("nova.skill.used", {
    unit: "1",
    description: "Skills used by agent runs",
  });
  const modelCallDurationHistogram = meter.createHistogram("nova.model_call.duration_ms", {
    unit: "ms",
    description: "Model call duration",
  });
  const modelCallRequestBytesHistogram = meter.createHistogram("nova.model_call.request_bytes", {
    unit: "By",
    description: "UTF-8 byte size of sanitized model request payloads",
  });
  const modelCallResponseBytesHistogram = meter.createHistogram("nova.model_call.response_bytes", {
    unit: "By",
    description: "UTF-8 byte size of bounded streamed model response payloads",
  });
  const modelCallTimeToFirstByteHistogram = meter.createHistogram(
    "nova.model_call.time_to_first_byte_ms",
    {
      unit: "ms",
      description: "Elapsed time before the first streamed model response event",
    },
  );
  const modelFailoverCounter = meter.createCounter("nova.model.failover", {
    unit: "1",
    description: "Model failovers by source, destination, lane, and reason",
  });
  const toolExecutionDurationHistogram = meter.createHistogram("nova.tool.execution.duration_ms", {
    unit: "ms",
    description: "Tool execution duration",
  });
  const toolExecutionBlockedCounter = meter.createCounter("nova.tool.execution.blocked", {
    unit: "1",
    description: "Tool executions blocked by policy or sandbox diagnostics",
  });
  const execProcessDurationHistogram = meter.createHistogram("nova.exec.duration_ms", {
    unit: "ms",
    description: "Exec process duration",
  });
  const memoryRssHistogram = meter.createHistogram("nova.memory.rss_bytes", {
    unit: "By",
    description: "Resident set size reported by diagnostic memory samples",
  });
  const memoryHeapUsedHistogram = meter.createHistogram("nova.memory.heap_used_bytes", {
    unit: "By",
    description: "Heap used bytes reported by diagnostic memory samples",
  });
  const memoryHeapTotalHistogram = meter.createHistogram("nova.memory.heap_total_bytes", {
    unit: "By",
    description: "Heap total bytes reported by diagnostic memory samples",
  });
  const memoryExternalHistogram = meter.createHistogram("nova.memory.external_bytes", {
    unit: "By",
    description: "External memory bytes reported by diagnostic memory samples",
  });
  const memoryArrayBuffersHistogram = meter.createHistogram("nova.memory.array_buffers_bytes", {
    unit: "By",
    description: "ArrayBuffer bytes reported by diagnostic memory samples",
  });
  const memoryPressureCounter = meter.createCounter("nova.memory.pressure", {
    unit: "1",
    description: "Diagnostic memory pressure events",
  });
  const asyncQueueDroppedCounter = meter.createCounter("nova.diagnostic.async_queue.dropped", {
    unit: "1",
    description: "Async diagnostic queue drops by dropped event class",
  });
  const payloadLargeCounter = meter.createCounter("nova.payload.large", {
    unit: "1",
    description: "Oversized payload diagnostics by surface and action",
  });
  const payloadLargeBytesHistogram = meter.createHistogram("nova.payload.large_bytes", {
    unit: "By",
    description: "Oversized payload byte sizes by surface and action",
  });
  const livenessWarningCounter = meter.createCounter("nova.liveness.warning", {
    unit: "1",
    description: "Diagnostic liveness warning events",
  });
  const livenessEventLoopDelayP99Histogram = meter.createHistogram(
    "nova.liveness.event_loop_delay_p99_ms",
    {
      unit: "ms",
      description: "P99 event-loop delay reported by diagnostic liveness warnings",
    },
  );
  const livenessEventLoopDelayMaxHistogram = meter.createHistogram(
    "nova.liveness.event_loop_delay_max_ms",
    {
      unit: "ms",
      description: "Maximum event-loop delay reported by diagnostic liveness warnings",
    },
  );
  const livenessEventLoopUtilizationHistogram = meter.createHistogram(
    "nova.liveness.event_loop_utilization",
    {
      unit: "1",
      description: "Event-loop utilization reported by diagnostic liveness warnings",
    },
  );
  const livenessCpuCoreRatioHistogram = meter.createHistogram("nova.liveness.cpu_core_ratio", {
    unit: "1",
    description: "CPU core ratio reported by diagnostic liveness warnings",
  });
  const telemetryExporterCounter = meter.createCounter("nova.telemetry.exporter.events", {
    unit: "1",
    description: "Diagnostic telemetry exporter lifecycle and failure events",
  });
  return {
    tokensCounter,
    genAiTokenUsageHistogram,
    genAiOperationDurationHistogram,
    costCounter,
    durationHistogram,
    harnessDurationHistogram,
    contextHistogram,
    webhookReceivedCounter,
    webhookErrorCounter,
    webhookDurationHistogram,
    messageQueuedCounter,
    messageReceivedCounter,
    messageDispatchStartedCounter,
    messageDispatchCompletedCounter,
    messageDispatchDurationHistogram,
    messageProcessedCounter,
    messageDurationHistogram,
    messageDeliveryStartedCounter,
    messageDeliveryDurationHistogram,
    queueDepthHistogram,
    queueWaitHistogram,
    laneEnqueueCounter,
    laneDequeueCounter,
    sessionStateCounter,
    sessionTurnCreatedCounter,
    sessionStuckCounter,
    sessionStuckAgeHistogram,
    sessionRecoveryRequestedCounter,
    sessionRecoveryCompletedCounter,
    sessionRecoveryAgeHistogram,
    talkEventCounter,
    talkEventDurationHistogram,
    talkAudioBytesHistogram,
    runAttemptCounter,
    toolLoopCounter,
    skillUsedCounter,
    modelCallDurationHistogram,
    modelCallRequestBytesHistogram,
    modelCallResponseBytesHistogram,
    modelCallTimeToFirstByteHistogram,
    modelFailoverCounter,
    toolExecutionDurationHistogram,
    toolExecutionBlockedCounter,
    execProcessDurationHistogram,
    memoryRssHistogram,
    memoryHeapUsedHistogram,
    memoryHeapTotalHistogram,
    memoryExternalHistogram,
    memoryArrayBuffersHistogram,
    memoryPressureCounter,
    asyncQueueDroppedCounter,
    payloadLargeCounter,
    payloadLargeBytesHistogram,
    livenessWarningCounter,
    livenessEventLoopDelayP99Histogram,
    livenessEventLoopDelayMaxHistogram,
    livenessEventLoopUtilizationHistogram,
    livenessCpuCoreRatioHistogram,
    telemetryExporterCounter,
  };
}

export type DiagnosticsMetrics = ReturnType<typeof createDiagnosticsMetrics>;
