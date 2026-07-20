import type { NovaConfig } from "../config/config.js";
import "./runtime.js";
import type { CommitmentExtractionBatchResult, CommitmentExtractionItem } from "./types.js";

type TimerHandle = ReturnType<typeof setTimeout>;

type CommitmentExtractionRuntime = {
  extractBatch?: (params: {
    cfg?: NovaConfig;
    items: CommitmentExtractionItem[];
  }) => Promise<CommitmentExtractionBatchResult>;
  resolveDefaultModel?: (params: { cfg: NovaConfig; agentId?: string }) => {
    provider: string;
    model: string;
  };
  setTimer?: (callback: () => void, delayMs: number) => TimerHandle;
  clearTimer?: (timer: TimerHandle) => void;
  forceInTests?: boolean;
};

type CommitmentRuntimeTestApi = {
  configureCommitmentExtractionRuntime(next: CommitmentExtractionRuntime): void;
  drainCommitmentExtractionQueue(): Promise<number>;
  resetCommitmentExtractionRuntimeForTests(): void;
};

function getTestApi(): CommitmentRuntimeTestApi {
  const api = (globalThis as Record<PropertyKey, unknown>)[
    Symbol.for("nova.commitmentRuntimeTestApi")
  ];
  if (!api) {
    throw new Error("commitment runtime test API is unavailable");
  }
  return api as CommitmentRuntimeTestApi;
}

export function configureCommitmentExtractionRuntime(next: CommitmentExtractionRuntime): void {
  getTestApi().configureCommitmentExtractionRuntime(next);
}

export async function drainCommitmentExtractionQueue(): Promise<number> {
  return await getTestApi().drainCommitmentExtractionQueue();
}

export function resetCommitmentExtractionRuntimeForTests(): void {
  getTestApi().resetCommitmentExtractionRuntimeForTests();
}
