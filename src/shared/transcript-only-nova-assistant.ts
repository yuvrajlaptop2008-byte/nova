// Identifies Nova-authored assistant rows that are transcript bookkeeping,
// not provider model output. Some history surfaces keep gateway-injected rows
// visible, so use the narrower delivery-mirror predicate when visibility matters.
export const NOVA_TRANSCRIPT_ARTIFACT_API = "nova-transcript" as const;
export const NOVA_TRANSCRIPT_ARTIFACT_PROVIDER = "nova" as const;
export const NOVA_DELIVERY_MIRROR_MODEL = "delivery-mirror" as const;
const NOVA_GATEWAY_INJECTED_MODEL = "gateway-injected" as const;

const TRANSCRIPT_ONLY_NOVA_ASSISTANT_MODELS = new Set<string>([
  NOVA_DELIVERY_MIRROR_MODEL,
  NOVA_GATEWAY_INJECTED_MODEL,
]);
const NOVA_DELIVERY_MIRROR_KINDS = new Set([
  "channel-final",
  "channel-final-suppressed",
  "message-tool-source-reply",
]);

function isNovaDeliveryMirrorMarker(value: unknown): boolean {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const kind = (value as { kind?: unknown }).kind;
  return typeof kind === "string" && NOVA_DELIVERY_MIRROR_KINDS.has(kind);
}

export function isTranscriptOnlyNovaAssistantModel(provider: unknown, model: unknown): boolean {
  return (
    provider === NOVA_TRANSCRIPT_ARTIFACT_PROVIDER &&
    typeof model === "string" &&
    TRANSCRIPT_ONLY_NOVA_ASSISTANT_MODELS.has(model)
  );
}

/**
 * Returns true when the message is an Nova-authored transcript artifact
 * that must not be replayed to providers.
 *
 * Primary check: provider="nova" + model in known transcript-only set.
 * Fallback: a valid novaDeliveryMirror marker catches observed historical
 * rows whose provider/model provenance was stripped (#99470).
 */
export function isTranscriptOnlyNovaAssistantMessage(message: unknown): boolean {
  if (!message || typeof message !== "object" || Array.isArray(message)) {
    return false;
  }
  const entry = message as {
    role?: unknown;
    provider?: unknown;
    model?: unknown;
    novaDeliveryMirror?: unknown;
  };
  if (entry.role !== "assistant") {
    return false;
  }
  if (isTranscriptOnlyNovaAssistantModel(entry.provider, entry.model)) {
    return true;
  }
  return isNovaDeliveryMirrorMarker(entry.novaDeliveryMirror);
}

export function isNovaMessageToolMirrorAssistantMessage(message: unknown): boolean {
  if (!message || typeof message !== "object" || Array.isArray(message)) {
    return false;
  }
  const entry = message as { role?: unknown; novaMessageToolMirror?: unknown };
  return entry.role === "assistant" && entry.novaMessageToolMirror !== undefined;
}

export function isNovaInternalSourceReplyMirrorAssistantMessage(message: unknown): boolean {
  if (!isNovaMessageToolMirrorAssistantMessage(message)) {
    return false;
  }
  const marker = (message as { novaMessageToolMirror?: unknown }).novaMessageToolMirror;
  return (
    Boolean(marker) &&
    typeof marker === "object" &&
    !Array.isArray(marker) &&
    (marker as { sourceReplySink?: unknown }).sourceReplySink === "internal-ui"
  );
}

export function isNovaDeliveryMirrorAssistantMessage(message: unknown): boolean {
  if (!message || typeof message !== "object" || Array.isArray(message)) {
    return false;
  }
  const entry = message as { role?: unknown; provider?: unknown; model?: unknown };
  return (
    entry.role === "assistant" &&
    entry.provider === NOVA_TRANSCRIPT_ARTIFACT_PROVIDER &&
    entry.model === NOVA_DELIVERY_MIRROR_MODEL
  );
}
