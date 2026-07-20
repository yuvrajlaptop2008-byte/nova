// Imessage plugin module implements approval resolver behavior.
import {
  resolveApprovalOverGateway,
  type ApprovalResolveResult,
} from "nova/plugin-sdk/approval-gateway-runtime";
import type { ExecApprovalReplyDecision } from "nova/plugin-sdk/approval-reply-runtime";
import type { NovaConfig } from "nova/plugin-sdk/config-contracts";
import { isApprovalNotFoundError } from "nova/plugin-sdk/error-runtime";

export { isApprovalNotFoundError };

export async function resolveIMessageApproval(params: {
  cfg: NovaConfig;
  approvalId: string;
  approvalKind: "exec" | "plugin";
  decision: ExecApprovalReplyDecision;
  senderId?: string | null;
  gatewayUrl?: string;
}): Promise<ApprovalResolveResult> {
  return await resolveApprovalOverGateway({
    cfg: params.cfg,
    approvalId: params.approvalId,
    approvalKind: params.approvalKind,
    decision: params.decision,
    senderId: params.senderId,
    gatewayUrl: params.gatewayUrl,
    clientDisplayName: `iMessage approval (${params.senderId?.trim() || "unknown"})`,
  });
}
