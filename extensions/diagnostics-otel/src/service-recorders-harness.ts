import { SpanStatusCode } from "@opentelemetry/api";
import type {
  DiagnosticEventMetadata,
  DiagnosticEventPayload,
  DiagnosticEventPrivateData,
} from "../api.js";
import { lowCardinalityAttr, lowCardinalityQueueLaneAttr } from "./service-attributes.js";
import { normalizeOtelErrorMessage } from "./service-content-normalization.js";
import type { DiagnosticsRecorderRuntime } from "./service-recorder-runtime.js";
import type { HarnessRunDiagnosticEvent, ModelFailoverDiagnosticEvent } from "./service-types.js";

export function createHarnessRecorders(runtime: DiagnosticsRecorderRuntime) {
  const {
    harnessDurationHistogram,
    modelFailoverCounter,
    activeTrustedSpans,
    spanWithDuration,
    trustedTraceContext,
    activeTrustedParentContext,
    trackTrustedSpan,
    takeTrackedTrustedSpan,
    setSpanAttrs,
    completeTrackedLifecycleSpan,
    addRunAttrs,
    tracesEnabled,
  } = runtime;

  const harnessRunMetricAttrs = (evt: HarnessRunDiagnosticEvent) => ({
    "nova.harness.id": lowCardinalityAttr(evt.harnessId, "unknown"),
    "nova.harness.plugin": lowCardinalityAttr(evt.pluginId),
    ...(evt.type === "harness.run.started"
      ? {}
      : {
          "nova.outcome": evt.type === "harness.run.error" ? "error" : evt.outcome,
        }),
    "nova.provider": lowCardinalityAttr(evt.provider, "unknown"),
    "nova.model": lowCardinalityAttr(evt.model, "unknown"),
    ...(evt.channel ? { "nova.channel": lowCardinalityAttr(evt.channel) } : {}),
  });

  const recordHarnessRunStarted = (
    evt: Extract<DiagnosticEventPayload, { type: "harness.run.started" }>,
    metadata: DiagnosticEventMetadata,
  ) => {
    if (!tracesEnabled || !metadata.trusted) {
      return;
    }
    trackTrustedSpan(
      evt,
      metadata,
      spanWithDuration("nova.harness.run", harnessRunMetricAttrs(evt), undefined, {
        parentContext: activeTrustedParentContext(evt, metadata),
        startTimeMs: evt.ts,
      }),
    );
  };

  const recordHarnessRunCompleted = (
    evt: Extract<DiagnosticEventPayload, { type: "harness.run.completed" }>,
    metadata: DiagnosticEventMetadata,
    privateData: DiagnosticEventPrivateData,
  ) => {
    harnessDurationHistogram.record(evt.durationMs, harnessRunMetricAttrs(evt));
    if (!tracesEnabled) {
      return;
    }
    const spanAttrs: Record<string, string | number | boolean> = {
      ...harnessRunMetricAttrs(evt),
    };
    if (evt.resultClassification) {
      spanAttrs["nova.harness.result_classification"] = lowCardinalityAttr(
        evt.resultClassification,
      );
    }
    if (typeof evt.yieldDetected === "boolean") {
      spanAttrs["nova.harness.yield_detected"] = evt.yieldDetected;
    }
    if (evt.itemLifecycle) {
      spanAttrs["nova.harness.items.started"] = evt.itemLifecycle.startedCount;
      spanAttrs["nova.harness.items.completed"] = evt.itemLifecycle.completedCount;
      spanAttrs["nova.harness.items.active"] = evt.itemLifecycle.activeCount;
    }
    // Redacted message goes on the span only, never the low-cardinality metric attrs.
    const redactedError = normalizeOtelErrorMessage(privateData.errorMessage);
    if (redactedError) {
      spanAttrs["nova.error"] = redactedError;
    }
    const trustedTrace = trustedTraceContext(evt, metadata);
    const trackedSpan = trustedTrace?.spanId
      ? activeTrustedSpans.get(trustedTrace.spanId)
      : undefined;
    const span =
      trackedSpan ??
      spanWithDuration("nova.harness.run", spanAttrs, evt.durationMs, {
        parentContext: activeTrustedParentContext(evt, metadata),
        endTimeMs: evt.ts,
      });
    setSpanAttrs(span, spanAttrs);
    if (evt.outcome === "error") {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: redactedError ?? "error",
      });
    }
    if (trackedSpan && trustedTrace?.spanId) {
      completeTrackedLifecycleSpan(trustedTrace.spanId, trackedSpan, evt.ts);
      return;
    }
    span.end(evt.ts);
  };

  const recordHarnessRunError = (
    evt: Extract<DiagnosticEventPayload, { type: "harness.run.error" }>,
    metadata: DiagnosticEventMetadata,
    privateData: DiagnosticEventPrivateData,
  ) => {
    const errorType = lowCardinalityAttr(evt.errorCategory, "other");
    const attrs = {
      ...harnessRunMetricAttrs(evt),
      "nova.harness.phase": evt.phase,
      "nova.errorCategory": errorType,
    };
    harnessDurationHistogram.record(evt.durationMs, attrs);
    if (!tracesEnabled) {
      return;
    }
    // Redacted message goes on the span only; attrs above feed the metric.
    const redactedError = normalizeOtelErrorMessage(privateData.errorMessage);
    const spanAttrs: Record<string, string | number | boolean> = {
      ...attrs,
      "error.type": errorType,
      ...(redactedError ? { "nova.error": redactedError } : {}),
      ...(evt.cleanupFailed ? { "nova.harness.cleanup_failed": true } : {}),
    };
    const span =
      takeTrackedTrustedSpan(evt, metadata) ??
      spanWithDuration("nova.harness.run", spanAttrs, evt.durationMs, {
        parentContext: activeTrustedParentContext(evt, metadata),
        endTimeMs: evt.ts,
      });
    setSpanAttrs(span, spanAttrs);
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: redactedError ?? errorType,
    });
    span.end(evt.ts);
  };

  const recordContextAssembled = (
    evt: Extract<DiagnosticEventPayload, { type: "context.assembled" }>,
    metadata: DiagnosticEventMetadata,
  ) => {
    if (!tracesEnabled) {
      return;
    }
    const spanAttrs: Record<string, string | number | boolean> = {
      "nova.context.message_count": evt.messageCount,
      "nova.context.history_text_chars": evt.historyTextChars,
      "nova.context.history_image_blocks": evt.historyImageBlocks,
      "nova.context.max_message_text_chars": evt.maxMessageTextChars,
      "nova.context.system_prompt_chars": evt.systemPromptChars,
      "nova.context.prompt_chars": evt.promptChars,
      "nova.context.prompt_images": evt.promptImages,
    };
    addRunAttrs(spanAttrs, evt);
    if (evt.contextTokenBudget !== undefined) {
      spanAttrs["nova.context.token_budget"] = evt.contextTokenBudget;
    }
    if (evt.reserveTokens !== undefined) {
      spanAttrs["nova.context.reserve_tokens"] = evt.reserveTokens;
    }
    const span = spanWithDuration("nova.context.assembled", spanAttrs, 0, {
      parentContext: activeTrustedParentContext(evt, metadata),
      endTimeMs: evt.ts,
    });
    span.end(evt.ts);
  };

  const recordModelFailover = (
    evt: ModelFailoverDiagnosticEvent,
    metadata: DiagnosticEventMetadata,
  ) => {
    const metricAttrs: Record<string, string> = {
      "nova.failover.reason": lowCardinalityAttr(evt.reason, "unknown"),
      "nova.failover.suspended": evt.suspended === undefined ? "unknown" : String(evt.suspended),
      "nova.lane": lowCardinalityQueueLaneAttr(evt.lane, "unknown"),
      "nova.model": lowCardinalityAttr(evt.fromModel),
      "nova.provider": lowCardinalityAttr(evt.fromProvider),
      "nova.failover.to_model": lowCardinalityAttr(evt.toModel),
      "nova.failover.to_provider": lowCardinalityAttr(evt.toProvider),
    };
    modelFailoverCounter.add(1, metricAttrs);
    if (!tracesEnabled) {
      return;
    }
    const spanAttrs: Record<string, string | number | boolean> = {
      "nova.failover.reason": lowCardinalityAttr(evt.reason, "unknown"),
    };
    if (evt.fromProvider) {
      spanAttrs["nova.provider"] = evt.fromProvider;
    }
    if (evt.fromModel) {
      spanAttrs["nova.model"] = evt.fromModel;
    }
    if (evt.toProvider) {
      spanAttrs["nova.failover.to_provider"] = evt.toProvider;
    }
    if (evt.toModel) {
      spanAttrs["nova.failover.to_model"] = evt.toModel;
    }
    if (evt.lane) {
      spanAttrs["nova.lane"] = lowCardinalityQueueLaneAttr(evt.lane, "unknown");
    }
    if (evt.suspended !== undefined) {
      spanAttrs["nova.failover.suspended"] = evt.suspended;
    }
    if (evt.cascadeDepth !== undefined) {
      spanAttrs["nova.failover.cascade_depth"] = evt.cascadeDepth;
    }
    const span = spanWithDuration("nova.model.failover", spanAttrs, 0, {
      parentContext: activeTrustedParentContext(evt, metadata),
      endTimeMs: evt.ts,
    });
    span.end(evt.ts);
  };

  return {
    recordHarnessRunStarted,
    recordHarnessRunCompleted,
    recordHarnessRunError,
    recordContextAssembled,
    recordModelFailover,
  };
}
