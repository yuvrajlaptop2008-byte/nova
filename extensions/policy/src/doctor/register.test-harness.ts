// Policy tests cover register plugin behavior.
import { promises as fs } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  runDoctorLintChecks,
  type HealthCheck,
  type HealthCheckContext,
  type HealthFinding,
  type HealthRepairContext,
  type NovaConfig,
} from "nova/plugin-sdk/health";
import { clearHealthChecksForTest } from "nova/plugin-sdk/plugin-test-runtime";
import { registerPolicyDoctorChecks } from "./register.js";

export let workspaceDir: string;

let originalNovaHome: string | undefined;

let originalNovaStateDir: string | undefined;

export function cfgWithPolicy(settings: Record<string, unknown> = {}): NovaConfig {
  return {
    plugins: {
      entries: {
        policy: {
          enabled: true,
          config: { enabled: true, ...settings },
        },
      },
    },
  };
}

export function ctx(configPath: string, cfg: NovaConfig = {}): HealthCheckContext {
  return {
    mode: "lint",
    runtime: {
      log() {},
      error() {},
      exit() {},
    },
    cfg,
    cwd: workspaceDir,
    configPath,
  };
}

export function repairCtx(configPath: string, cfg: NovaConfig = {}): HealthRepairContext {
  return {
    ...ctx(configPath, cfg),
    mode: "fix",
  };
}

export function registerChecks(): readonly HealthCheck[] {
  const checks: HealthCheck[] = [];
  registerPolicyDoctorChecks({
    registerHealthCheck(check) {
      checks.push(check);
    },
  });
  return checks;
}

export async function runPolicyChecks(checkCtx: HealthCheckContext): Promise<{
  readonly findings: readonly HealthFinding[];
}> {
  const checks = registerChecks();
  const findings: HealthFinding[] = [];
  for (const check of checks) {
    findings.push(...(check.detect === undefined ? [] : await check.detect(checkCtx)));
  }
  return { findings };
}

export async function runPolicyDoctorLint(checkCtx: HealthCheckContext) {
  return runDoctorLintChecks(checkCtx, { checks: registerChecks() });
}

export async function runDeniedChannelRepair(repairCheckCtx: HealthRepairContext) {
  const check = registerChecks().find((entry) => entry.id === "policy/channels-denied-provider");
  if (check?.detect === undefined || check.repair === undefined) {
    throw new Error("policy channel repair check was not registered");
  }
  const findings = await check.detect(repairCheckCtx);
  const result = await check.repair(repairCheckCtx, findings);
  const config = result.config ?? repairCheckCtx.cfg;
  const remainingFindings = await check.detect({ ...repairCheckCtx, cfg: config });
  return { ...result, config, remainingFindings };
}

export async function runPolicyRepairCheck(checkId: string, repairCheckCtx: HealthRepairContext) {
  const check = registerChecks().find((entry) => entry.id === checkId);
  if (check?.detect === undefined || check.repair === undefined) {
    throw new Error(`${checkId} repair check was not registered`);
  }
  const findings = await check.detect(repairCheckCtx);
  const result = await check.repair(repairCheckCtx, findings);
  const config = result.config ?? repairCheckCtx.cfg;
  const remainingFindings =
    repairCheckCtx.dryRun === true ? [] : await check.detect({ ...repairCheckCtx, cfg: config });
  return { ...result, findings, config, remainingFindings };
}

export const describe0BeforeEach0 = async () => {
  clearHealthChecksForTest();
  originalNovaHome = process.env.NOVA_HOME;
  originalNovaStateDir = process.env.NOVA_STATE_DIR;
  workspaceDir = await fs.mkdtemp(join(tmpdir(), "policy-doctor-"));
  process.env.NOVA_HOME = workspaceDir;
  delete process.env.NOVA_STATE_DIR;
  await fs.mkdir(join(workspaceDir, ".nova"), { recursive: true });
  try {
    await fs.symlink("../exec-approvals.json", join(workspaceDir, ".nova", "exec-approvals.json"));
  } catch (err) {
    if (typeof err !== "object" || err === null || !("code" in err) || err.code !== "EPERM") {
      throw err;
    }
    await fs.rm(join(workspaceDir, ".nova"), { recursive: true, force: true });
    await fs.symlink(workspaceDir, join(workspaceDir, ".nova"), "junction");
  }
};

export const describe0AfterEach1 = async () => {
  if (originalNovaHome === undefined) {
    delete process.env.NOVA_HOME;
  } else {
    process.env.NOVA_HOME = originalNovaHome;
  }
  if (originalNovaStateDir === undefined) {
    delete process.env.NOVA_STATE_DIR;
  } else {
    process.env.NOVA_STATE_DIR = originalNovaStateDir;
  }
  await fs.rm(workspaceDir, { recursive: true, force: true });
  clearHealthChecksForTest();
};
