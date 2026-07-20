/** Tests plugin version drift detection between package, manifest, and install records. */
import { describe, expect, it } from "vitest";
import type { NovaConfig } from "../config/types.js";
import type { PluginInstallRecord } from "../config/types.plugins.js";
import {
  detectPluginVersionDrift,
  resolvePluginVersionDriftUpdateCommand,
} from "./plugin-version-drift.js";

function npmRecord(
  version: string,
  overrides: Partial<PluginInstallRecord> = {},
): PluginInstallRecord {
  const resolvedName = overrides.resolvedName ?? "@nova/whatsapp";
  return {
    source: "npm",
    spec: `${resolvedName}@latest`,
    resolvedName,
    resolvedVersion: version,
    ...overrides,
  };
}

function clawhubRecord(
  version: string,
  overrides: Partial<PluginInstallRecord> = {},
): PluginInstallRecord {
  return {
    source: "clawhub",
    spec: "clawhub:@nova/whatsapp",
    clawhubPackage: "@nova/whatsapp",
    resolvedVersion: version,
    ...overrides,
  };
}

describe("detectPluginVersionDrift", () => {
  it("returns empty drifts when all externalized plugins match the gateway", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.4"),
        discord: npmRecord("2026.5.4", { resolvedName: "@nova/discord" }),
      },
    });

    expect(result.drifts).toEqual([]);
    expect(result.gatewayVersion).toBe("2026.5.4");
  });

  it("reports plugins whose installed version does not match the gateway", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3", {
          resolvedName: "@nova/whatsapp",
          spec: "@nova/whatsapp@2026.5.3",
        }),
        discord: npmRecord("2026.5.4", { resolvedName: "@nova/discord" }),
      },
    });

    expect(result.drifts).toHaveLength(1);
    expect(result.drifts[0]).toEqual({
      pluginId: "whatsapp",
      installedVersion: "2026.5.3",
      gatewayVersion: "2026.5.4",
      source: "npm",
      packageName: "@nova/whatsapp",
      spec: "@nova/whatsapp@2026.5.3",
    });
  });

  it("treats a build-qualifier suffix on either side as matching (2026.5.4-1 ≈ 2026.5.4)", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4-1",
      installRecords: {
        whatsapp: npmRecord("2026.5.4"),
        // ...and the inverse direction
        discord: npmRecord("2026.5.4-1", { resolvedName: "@nova/discord" }),
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("includes ClawHub-installed plugins in the drift check", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: clawhubRecord("2026.5.3"),
      },
    });

    expect(result.drifts).toHaveLength(1);
    expect(result.drifts[0]?.source).toBe("clawhub");
  });

  it("includes official ClawHub installs whose catalog entry only declares npm install metadata", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        discord: clawhubRecord("2026.5.3", {
          spec: "clawhub:@nova/discord",
          clawhubPackage: "@nova/discord",
          clawhubChannel: "official",
          clawhubUrl: "https://clawhub.ai",
        }),
      },
    });

    expect(result.drifts.map((d) => d.pluginId)).toEqual(["discord"]);
  });

  it("ignores community npm installs without an official lockstep contract", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        community: npmRecord("1.2.3", {
          resolvedName: "community-plugin",
          spec: "community-plugin@1.2.3",
        }),
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("ignores community ClawHub installs without an official lockstep contract", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        community: clawhubRecord("1.2.3", {
          spec: "clawhub:community-plugin@1.2.3",
          clawhubPackage: "community-plugin",
        }),
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("ignores official catalog installs pinned to independent package versions", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        "nova-plugin-yuanbao": npmRecord("2.13.1", {
          resolvedName: "nova-plugin-yuanbao",
          spec: "nova-plugin-yuanbao@2.13.1",
        }),
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("ignores exact catalog pins even when the pin matches the gateway version", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.7",
      installRecords: {
        "wecom-nova-plugin": npmRecord("2026.5.6", {
          resolvedName: "@wecom/wecom-nova-plugin",
          spec: "@wecom/wecom-nova-plugin@2026.5.6",
        }),
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("ignores install sources that are not official external installs", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        // archive/path/git installs are local artifacts; they pin to whatever
        // the operator chose and should not be flagged on a gateway version
        // bump alone.
        archive: {
          source: "archive",
          resolvedName: "@nova/whatsapp",
          resolvedVersion: "2026.5.3",
          spec: "@nova/whatsapp@archive",
        },
        local: {
          source: "path",
          resolvedName: "@nova/whatsapp",
          resolvedVersion: "2026.5.3",
          spec: "/tmp/local-plugin",
        },
        forked: {
          source: "git",
          resolvedName: "@nova/whatsapp",
          resolvedVersion: "2026.5.3",
          spec: "git+ssh://example/forked",
        },
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("falls back to the install record's `version` field when `resolvedVersion` is absent", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: {
          source: "npm",
          spec: "@nova/whatsapp@latest",
          resolvedName: "@nova/whatsapp",
          version: "2026.5.3",
        },
      },
    });

    expect(result.drifts).toHaveLength(1);
    expect(result.drifts[0]?.installedVersion).toBe("2026.5.3");
  });

  it("skips plugins with no recorded version (cannot detect drift)", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: { source: "npm", spec: "@nova/whatsapp@latest" },
      },
    });

    expect(result.drifts).toEqual([]);
  });

  it("skips plugins that are explicitly disabled in config", () => {
    const config: NovaConfig = {
      plugins: {
        entries: {
          whatsapp: { enabled: false },
          discord: { enabled: true },
        },
      },
    } as NovaConfig;

    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
        discord: npmRecord("2026.5.3", { resolvedName: "@nova/discord" }),
      },
      config,
    });

    expect(result.drifts.map((d) => d.pluginId)).toEqual(["discord"]);
  });

  it("skips plugins disabled by the global plugin activation policy", () => {
    const config: NovaConfig = {
      plugins: {
        enabled: false,
      },
    } as NovaConfig;

    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
      },
      config,
    });

    expect(result.drifts).toEqual([]);
  });

  it("skips plugins blocked by denylist or restrictive allowlist policy", () => {
    const denied = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
      },
      config: {
        plugins: {
          deny: ["whatsapp"],
        },
      } as NovaConfig,
    });
    const notAllowed = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
      },
      config: {
        plugins: {
          allow: ["discord"],
        },
      } as NovaConfig,
    });

    expect(denied.drifts).toEqual([]);
    expect(notAllowed.drifts).toEqual([]);
  });

  it("includes plugins with no entry in config (default-enabled)", () => {
    const config: NovaConfig = { plugins: { entries: {} } } as NovaConfig;
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
      },
      config,
    });

    expect(result.drifts).toHaveLength(1);
  });

  it("returns drifts sorted by pluginId for deterministic output", () => {
    const result = detectPluginVersionDrift({
      gatewayVersion: "2026.5.4",
      installRecords: {
        whatsapp: npmRecord("2026.5.3"),
        discord: npmRecord("2026.5.3", { resolvedName: "@nova/discord" }),
        matrix: npmRecord("2026.5.3", { resolvedName: "@nova/matrix" }),
      },
    });

    expect(result.drifts.map((d) => d.pluginId)).toEqual(["discord", "matrix", "whatsapp"]);
  });
});

describe("resolvePluginVersionDriftUpdateCommand", () => {
  it("uses an exact npm package target when the drifted install is pinned", () => {
    expect(
      resolvePluginVersionDriftUpdateCommand({
        pluginId: "brave",
        installedVersion: "2026.6.9",
        gatewayVersion: "2026.6.10-beta.1",
        source: "npm",
        packageName: "@nova/brave-plugin",
        spec: "@nova/brave-plugin@2026.6.9",
      }),
    ).toBe("nova plugins update @nova/brave-plugin@2026.6.10-beta.1");
  });

  it("parses the package name from exact npm specs when drift metadata is sparse", () => {
    expect(
      resolvePluginVersionDriftUpdateCommand({
        pluginId: "brave",
        installedVersion: "2026.6.9",
        gatewayVersion: "2026.6.10-beta.1",
        source: "npm",
        spec: "@nova/brave-plugin@2026.6.9",
      }),
    ).toBe("nova plugins update @nova/brave-plugin@2026.6.10-beta.1");
  });

  it("prefers the parsed exact npm spec package over inconsistent drift metadata", () => {
    expect(
      resolvePluginVersionDriftUpdateCommand({
        pluginId: "brave",
        installedVersion: "2026.6.9",
        gatewayVersion: "2026.6.10-beta.1",
        source: "npm",
        packageName: "@nova/other-plugin",
        spec: "@nova/brave-plugin@2026.6.9",
      }),
    ).toBe("nova plugins update @nova/brave-plugin@2026.6.10-beta.1");
  });

  it("keeps plugin-id updates for floating npm install records", () => {
    expect(
      resolvePluginVersionDriftUpdateCommand({
        pluginId: "brave",
        installedVersion: "2026.6.9",
        gatewayVersion: "2026.6.10-beta.1",
        source: "npm",
        packageName: "@nova/brave-plugin",
        spec: "@nova/brave-plugin",
      }),
    ).toBe("nova plugins update brave");
  });

  it("keeps plugin-id updates when the gateway version is not a registry version", () => {
    expect(
      resolvePluginVersionDriftUpdateCommand({
        pluginId: "brave",
        installedVersion: "2026.6.9",
        gatewayVersion: "unknown",
        source: "npm",
        packageName: "@nova/brave-plugin",
        spec: "@nova/brave-plugin@2026.6.9",
      }),
    ).toBe("nova plugins update brave");
  });
});
