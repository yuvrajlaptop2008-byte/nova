import type { OutboundDeliveryResult } from "nova/plugin-sdk/channel-send-result";
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import type { ReplyPayload } from "nova/plugin-sdk/reply-runtime";
import { registerSignalApprovalReactionTargetForDeliveredPayload } from "./approval-reactions.js";
import { registerSignalQuestionReactionTargetForDeliveredPayload } from "./question-reactions.js";

export function registerSignalReactionTargetsForDeliveredPayload(params: {
  cfg: NovaConfig;
  target: { channel: string; to: string; accountId?: string | null };
  payload: ReplyPayload;
  results: readonly OutboundDeliveryResult[];
  targetAuthor?: string | null;
  targetAuthorUuid?: string | null;
}): void {
  registerSignalQuestionReactionTargetForDeliveredPayload(params);
  registerSignalApprovalReactionTargetForDeliveredPayload(params);
}
