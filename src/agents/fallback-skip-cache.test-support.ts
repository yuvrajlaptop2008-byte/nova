type FallbackSkipCacheState = {
  buckets: Map<string, Map<string, unknown>>;
  lastGlobalPruneAtMs: number;
};

function getFallbackSkipCacheGlobals() {
  return globalThis as typeof globalThis & {
    novaFallbackSkipCache?: Map<string, Map<string, unknown>>;
    novaFallbackSkipCacheState?: FallbackSkipCacheState;
  };
}

export function resetFallbackSkipCacheForTest(): void {
  const globals = getFallbackSkipCacheGlobals();
  globals.novaFallbackSkipCache?.clear();
  globals.novaFallbackSkipCacheState?.buckets.clear();
  if (globals.novaFallbackSkipCacheState) {
    globals.novaFallbackSkipCacheState.lastGlobalPruneAtMs = 0;
  }
}

export function listFallbackSkipCacheSessionIdsForTest(): string[] {
  const globals = getFallbackSkipCacheGlobals();
  return [...(globals.novaFallbackSkipCacheState?.buckets.keys() ?? [])];
}
