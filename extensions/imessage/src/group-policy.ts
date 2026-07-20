// Imessage plugin module implements group policy behavior.
import {
  buildChannelGroupsScopeTree,
  resolveScopeRequireMention,
  resolveScopeToolsPolicy,
  type GroupToolPolicyConfig,
} from "nova/plugin-sdk/channel-policy";
import type { NovaConfig } from "nova/plugin-sdk/core";

type IMessageGroupContext = {
  cfg: NovaConfig;
  accountId?: string | null;
  groupId?: string | null;
  senderId?: string | null;
  senderName?: string | null;
  senderUsername?: string | null;
  senderE164?: string | null;
};

function resolveScopePath(params: IMessageGroupContext) {
  return params.groupId ? [params.groupId] : [];
}

export function resolveIMessageGroupRequireMention(params: IMessageGroupContext): boolean {
  return resolveScopeRequireMention({
    tree: buildChannelGroupsScopeTree(params.cfg, "imessage", params.accountId),
    path: resolveScopePath(params),
  });
}

export function resolveIMessageGroupToolPolicy(
  params: IMessageGroupContext,
): GroupToolPolicyConfig | undefined {
  return resolveScopeToolsPolicy({
    ...params,
    tree: buildChannelGroupsScopeTree(params.cfg, "imessage", params.accountId),
    path: resolveScopePath(params),
    messageProvider: "imessage",
  });
}
