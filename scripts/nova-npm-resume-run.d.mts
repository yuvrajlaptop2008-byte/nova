export interface NovaNpmResumeRunRecord {
  conclusion?: unknown;
  event?: unknown;
  head_branch?: unknown;
  head_sha?: unknown;
  html_url?: unknown;
  path?: unknown;
  workflow_id?: unknown;
}

export interface NovaNpmResumeTagRecord {
  object?: {
    sha?: unknown;
    type?: unknown;
  };
  verification?: {
    verified?: unknown;
  };
}

export interface NovaNpmResumeJobRecord {
  conclusion?: unknown;
  name?: unknown;
}

export interface NovaNpmResumeValidationInput {
  canonicalWorkflowId: unknown;
  compareStatus: unknown;
  jobs: NovaNpmResumeJobRecord[];
  run: NovaNpmResumeRunRecord;
  tag: NovaNpmResumeTagRecord;
  tagRef: NovaNpmResumeTagRecord;
}

export interface NovaNpmResumeIdentity {
  tagObjectSha: string;
  url: string;
  workflowRef: string;
  workflowSha: string;
}

export function validateNovaNpmResumeRun(
  input: NovaNpmResumeValidationInput,
): NovaNpmResumeIdentity;

export function runNovaNpmResumeGh(
  args: string[],
  params?: {
    execFileSyncImpl?: (
      command: string,
      args: string[],
      options: {
        encoding: "utf8";
        killSignal: "SIGKILL";
        maxBuffer: number;
        timeout: number;
      },
    ) => string;
  },
): string;

export function resolveNovaNpmResumeRun(options: {
  repo: string;
  runId: string;
  runGh?: (args: string[]) => string;
}): NovaNpmResumeIdentity;
