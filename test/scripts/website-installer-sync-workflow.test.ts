// Website Installer Sync Workflow tests cover website installer sync workflow script behavior.
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const { detectInstallSmokeScope } = (await import("../../scripts/ci-changed-scope.mjs")) as {
  detectInstallSmokeScope: (paths: string[]) => {
    runFastInstallSmoke: boolean;
    runFullInstallSmoke: boolean;
  };
};

const WORKFLOW_PATH = ".github/workflows/website-installer-sync.yml";

describe("website installer sync workflow", () => {
  const workflow = readFileSync(WORKFLOW_PATH, "utf8");

  it("treats all website installer scripts as Nova-owned inputs", () => {
    for (const path of ["scripts/install.sh", "scripts/install-cli.sh", "scripts/install.ps1"]) {
      expect(workflow).toContain(path);
      expect(detectInstallSmokeScope([path]).runFullInstallSmoke).toBe(true);
    }
  });

  it("verifies installers on Linux Docker plus native macOS and Windows runners", () => {
    expect(workflow).toContain("linux-docker:");
    expect(workflow.match(/timeout --kill-after=30s 20m docker run --rm/g)?.length).toBe(2);
    expect(workflow).not.toContain("timeout 20m docker run --rm");
    expect(workflow).not.toMatch(/(^|\n)\s+docker run --rm/u);
    expect(workflow).toContain("bash /tmp/install.sh --version latest && nova --version");
    expect(workflow).not.toContain("bash /tmp/install.sh --no-prompt --no-onboard");
    expect(workflow).toContain("bash /tmp/install-cli.sh --prefix /tmp/nova");
    expect(workflow).toContain("macos-installer:");
    expect(workflow).toContain("runs-on: macos-15");
    expect(workflow).toContain("node-version: 24");
    expect(workflow).toContain('NOVA_NO_ONBOARD: "1"');
    expect(workflow).toContain('NOVA_NO_PROMPT: "1"');
    expect(workflow).toContain("bash scripts/install.sh --no-onboard --no-prompt --version latest");
    expect(workflow).toContain("nova --version");
    expect(workflow).toContain("windows-installer:");
    expect(workflow).toContain("runs-on: windows-latest");
    expect(workflow).toContain(".\\scripts\\install.ps1 -DryRun");
    expect(workflow).not.toContain("install.cmd dry run");
    expect(workflow).not.toContain(".\\scripts\\install.cmd");
  });

  it("syncs verified scripts to nova.ai only after all installer checks pass", () => {
    expect(workflow).toContain("needs: [static, linux-docker, macos-installer, windows-installer]");
    expect(workflow).toContain("repository: nova/nova.ai");
    expect(workflow).toContain("NOVA_GH_TOKEN: ${{ secrets.NOVA_GH_TOKEN }}");
    expect(workflow).toContain("NOVA_GH_TOKEN is not configured");
    expect(workflow).toContain("token: ${{ env.NOVA_GH_TOKEN }}");
    expect(workflow).toContain("cp nova/scripts/install.sh nova.ai/public/install.sh");
    expect(workflow).toContain("cp nova/scripts/install-cli.sh nova.ai/public/install-cli.sh");
    expect(workflow).toContain("cp nova/scripts/install.ps1 nova.ai/public/install.ps1");
    expect(workflow).toContain("rm -f nova.ai/public/install.cmd");
    expect(workflow).toContain("bun run build");
    expect(workflow).toContain("git push origin HEAD:main");
  });
});
