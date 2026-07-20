/** Test-only reset for process-global plugin conversation binding state. */
import { resolveGlobalMap, resolveGlobalSingleton } from "../shared/global-singleton.js";

type PluginBindingGlobalState = {
  fallbackNoticeBindingIds: Set<string>;
  approvalsCache: unknown;
  approvalsLoaded: boolean;
  approvalsSaveChain: Promise<void>;
};

export function resetPluginConversationBindingStateForTest(): void {
  resolveGlobalMap(Symbol.for("nova.pluginBindingPendingRequests")).clear();
  const state = resolveGlobalSingleton<PluginBindingGlobalState>(
    Symbol.for("nova.plugins.binding.global-state"),
    () => ({
      fallbackNoticeBindingIds: new Set(),
      approvalsCache: null,
      approvalsLoaded: false,
      approvalsSaveChain: Promise.resolve(),
    }),
  );
  state.approvalsCache = null;
  state.approvalsLoaded = false;
  state.approvalsSaveChain = Promise.resolve();
  state.fallbackNoticeBindingIds.clear();
}
