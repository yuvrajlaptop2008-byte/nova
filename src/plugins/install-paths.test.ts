// Covers managed plugin install path generation.
import path from "node:path";
import { describe, expect, it } from "vitest";
import {
  resolvePluginNpmGenerationProjectDir,
  resolvePluginNpmGenerationProjectDirPrefix,
} from "./install-paths.js";

describe("managed npm plugin install paths", () => {
  it("keeps generation project names compact for nested Windows runtime binaries", () => {
    const packageName = "@nova/codex";
    const generationKey = [
      packageName,
      "2026.6.10",
      `${packageName}@2026.6.10`,
      "sha512-test-integrity",
      "codexshasum",
    ].join("\n");
    const projectDir = resolvePluginNpmGenerationProjectDir({
      npmDir: String.raw`C:\Users\Administrator\.nova\npm`,
      packageName,
      generationKey,
    });
    const projectName = path.basename(projectDir);

    expect(projectName).toMatch(/^nova-codex-[a-f0-9]{10}__nova-generation__g-[a-f0-9]{16}$/u);
    expect(projectName.length).toBeLessThanOrEqual(66);

    const nestedCodexBinaryPath = path.win32.join(
      String.raw`C:\Users\Administrator\.nova\npm\projects`,
      projectName,
      "node_modules",
      "@nova",
      "codex",
      "node_modules",
      "@openai",
      "codex-win32-x64",
      "vendor",
      "x86_64-pc-windows-msvc",
      "bin",
      "codex.exe",
    );
    expect(nestedCodexBinaryPath.length).toBeLessThan(260);
  });

  it("keeps generation project names under the recoverable package prefix", () => {
    const packageName = "@nova/codex";
    const projectDir = resolvePluginNpmGenerationProjectDir({
      npmDir: "/tmp/nova/npm",
      packageName,
      generationKey: "codex-v2",
    });

    expect(path.basename(projectDir)).toMatch(
      new RegExp(`^${resolvePluginNpmGenerationProjectDirPrefix(packageName)}`, "u"),
    );
  });
});
