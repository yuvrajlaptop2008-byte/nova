import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ConfigFileSnapshot, NovaConfig } from "../config/types.nova.js";
import { withoutPluginInstallRecords } from "../plugins/installed-plugin-index-records.js";

const mocks = vi.hoisted(() => ({
  commitConfigWriteWithPendingPluginInstalls: vi.fn(),
  replaceConfigFile: vi.fn(),
}));

vi.mock("../config/config.js", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../config/config.js")>()),
  replaceConfigFile: mocks.replaceConfigFile,
}));

vi.mock("../plugins/install-record-commit.js", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../plugins/install-record-commit.js")>()),
  commitConfigWriteWithPendingPluginInstalls: mocks.commitConfigWriteWithPendingPluginInstalls,
}));

import { writeWizardConfigFile } from "./setup.shared.js";

describe("writeWizardConfigFile pending install ownership", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.commitConfigWriteWithPendingPluginInstalls.mockImplementation(
      async (params: { nextConfig: NovaConfig }) => ({
        config: withoutPluginInstallRecords(params.nextConfig),
        installRecords: {},
        movedInstallRecords: true,
        persistedHash: "test-hash",
      }),
    );
    mocks.replaceConfigFile.mockResolvedValue({ persistedHash: "next-hash" });
  });

  it("rejects a normal write with pending records but no migration base", async () => {
    const config: NovaConfig = {
      plugins: { installs: { demo: { source: "npm", spec: "demo@1.0.0" } } },
    };

    await expect(writeWizardConfigFile(config, { allowConfigSizeDrop: false })).rejects.toThrow(
      "declare migration ownership",
    );
    expect(mocks.commitConfigWriteWithPendingPluginInstalls).not.toHaveBeenCalled();
  });

  it("migrates the baseline as source before the final wizard write", async () => {
    const baseConfig: NovaConfig = {
      plugins: { installs: { demo: { source: "npm", spec: "demo@1.0.0" } } },
    };

    await writeWizardConfigFile(baseConfig, {
      allowConfigSizeDrop: false,
      migrationBaseConfig: baseConfig,
    });

    expect(mocks.commitConfigWriteWithPendingPluginInstalls).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        nextConfig: baseConfig,
        sourceConfig: baseConfig,
        writeOptions: { allowConfigSizeDrop: true },
      }),
    );
    expect(mocks.commitConfigWriteWithPendingPluginInstalls).toHaveBeenCalledTimes(2);
  });

  it("commits fresh pending records after baseline migration is complete", async () => {
    const config: NovaConfig = {
      plugins: { installs: { fresh: { source: "npm", spec: "fresh@1.0.0" } } },
    };

    await writeWizardConfigFile(config, {
      allowConfigSizeDrop: false,
      migrationBaseConfig: undefined,
    });

    expect(mocks.commitConfigWriteWithPendingPluginInstalls).toHaveBeenCalledOnce();
    expect(mocks.commitConfigWriteWithPendingPluginInstalls).toHaveBeenCalledWith(
      expect.objectContaining({ nextConfig: config }),
    );
  });

  it("binds the final write to the live-verified config hash", async () => {
    const config: NovaConfig = { gateway: { port: 18789 } };

    await writeWizardConfigFile(config, { baseHash: "verified-hash" });

    const commit = mocks.commitConfigWriteWithPendingPluginInstalls.mock.calls[0]?.[0]?.commit;
    expect(commit).toBeTypeOf("function");
    await commit(config);
    expect(mocks.replaceConfigFile).toHaveBeenCalledWith(
      expect.objectContaining({
        nextConfig: config,
        baseHash: "verified-hash",
        afterWrite: { mode: "auto" },
      }),
    );
  });

  it("preserves an absent config snapshot through the final write", async () => {
    const config: NovaConfig = { gateway: { port: 18789 } };
    const baseSnapshot: ConfigFileSnapshot = {
      path: "/tmp/nova.json",
      exists: false,
      raw: null,
      parsed: undefined,
      sourceConfig: {},
      resolved: {},
      valid: true,
      runtimeConfig: {},
      config: {},
      issues: [],
      warnings: [],
      legacyIssues: [],
    };

    await writeWizardConfigFile(config, { baseSnapshot });

    const commit = mocks.commitConfigWriteWithPendingPluginInstalls.mock.calls[0]?.[0]?.commit;
    expect(commit).toBeTypeOf("function");
    await commit(config);
    expect(mocks.replaceConfigFile).toHaveBeenCalledWith(
      expect.objectContaining({ nextConfig: config, snapshot: baseSnapshot }),
    );
  });
});
