/** Covers bundled plugin source overlays and packaged load-path decisions. */
import { expectDefined } from "@nova/normalization-core";
import { bundledPluginRootAt } from "nova/plugin-sdk/test-fixtures";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  findBundledPluginSource,
  findBundledPluginSourceInMap,
  getProcessBundledPluginSources,
  resolveBundledPluginSources,
} from "./bundled-sources.js";

const APP_ROOT = "/app";

function appBundledPluginRoot(pluginId: string): string {
  return bundledPluginRootAt(APP_ROOT, pluginId);
}

const discoverNovaPluginsMock = vi.fn();
const loadPluginManifestMock = vi.fn();

vi.mock("./discovery.js", () => ({
  discoverNovaPlugins: (...args: unknown[]) => discoverNovaPluginsMock(...args),
}));

vi.mock("./manifest.js", () => ({
  loadPluginManifest: (...args: unknown[]) => loadPluginManifestMock(...args),
}));

function createBundledCandidate(params: {
  rootDir: string;
  packageName: string;
  npmSpec?: string;
  origin?: "bundled" | "global";
}) {
  return {
    origin: params.origin ?? "bundled",
    rootDir: params.rootDir,
    packageName: params.packageName,
    packageManifest: {
      install: {
        npmSpec: params.npmSpec ?? params.packageName,
      },
    },
  };
}

function setBundledDiscoveryCandidates(candidates: unknown[]) {
  discoverNovaPluginsMock.mockReturnValue({
    candidates,
    diagnostics: [],
  });
}

function setBundledManifestIdsByRoot(
  manifestIds: Record<string, string | { id: string; required?: string[] }>,
) {
  loadPluginManifestMock.mockImplementation((rootDir: string) =>
    rootDir in manifestIds
      ? {
          ok: true,
          manifest:
            typeof manifestIds[rootDir] === "string"
              ? { id: manifestIds[rootDir] }
              : {
                  id: expectDefined(manifestIds[rootDir], "manifestIds[rootDir] test invariant").id,
                  configSchema: {
                    type: "object",
                    required: expectDefined(
                      manifestIds[rootDir],
                      "manifestIds[rootDir] test invariant",
                    ).required,
                  },
                },
        }
      : {
          ok: false,
          error: "invalid manifest",
          manifestPath: `${rootDir}/nova.plugin.json`,
        },
  );
}

function setBundledLookupFixture() {
  setBundledDiscoveryCandidates([
    createBundledCandidate({
      rootDir: appBundledPluginRoot("feishu"),
      packageName: "@nova/feishu",
    }),
    createBundledCandidate({
      rootDir: appBundledPluginRoot("diffs"),
      packageName: "@nova/diffs",
    }),
  ]);
  setBundledManifestIdsByRoot({
    [appBundledPluginRoot("feishu")]: "feishu",
    [appBundledPluginRoot("diffs")]: "diffs",
  });
}

function createResolvedBundledSource(params: {
  pluginId: string;
  localPath: string;
  npmSpec?: string;
  configSchema?: Record<string, unknown>;
  requiresConfig?: boolean;
}) {
  return {
    pluginId: params.pluginId,
    localPath: params.localPath,
    npmSpec: params.npmSpec ?? `@nova/${params.pluginId}`,
    ...(params.configSchema ? { configSchema: params.configSchema } : {}),
    requiresConfig: params.requiresConfig ?? false,
  };
}

function expectBundledSourceLookup(
  lookup: Parameters<typeof findBundledPluginSource>[0]["lookup"],
  expected:
    | {
        pluginId: string;
        localPath: string;
      }
    | undefined,
) {
  const resolved = findBundledPluginSource({ lookup });
  if (!expected) {
    expect(resolved).toBeUndefined();
    return;
  }
  expect(resolved?.pluginId).toBe(expected.pluginId);
  expect(resolved?.localPath).toBe(expected.localPath);
}

function expectBundledSourceLookupCase(params: {
  lookup: Parameters<typeof findBundledPluginSource>[0]["lookup"];
  expected:
    | {
        pluginId: string;
        localPath: string;
      }
    | undefined;
}) {
  setBundledLookupFixture();
  expectBundledSourceLookup(params.lookup, params.expected);
}

describe("bundled plugin sources", () => {
  beforeEach(() => {
    discoverNovaPluginsMock.mockReset();
    loadPluginManifestMock.mockReset();
  });

  it("reuses one process-stable bundled source snapshot", () => {
    setBundledLookupFixture();

    const first = getProcessBundledPluginSources();
    const second = getProcessBundledPluginSources();

    expect(second).toBe(first);
    expect(discoverNovaPluginsMock).toHaveBeenCalledOnce();
  });

  it("resolves bundled sources keyed by plugin id", () => {
    setBundledDiscoveryCandidates([
      createBundledCandidate({
        origin: "global",
        rootDir: "/global/feishu",
        packageName: "@nova/feishu",
      }),
      createBundledCandidate({
        rootDir: appBundledPluginRoot("feishu"),
        packageName: "@nova/feishu",
      }),
      createBundledCandidate({
        rootDir: appBundledPluginRoot("feishu-dup"),
        packageName: "@nova/feishu",
      }),
      createBundledCandidate({
        rootDir: appBundledPluginRoot("msteams"),
        packageName: "@nova/msteams",
      }),
    ]);
    setBundledManifestIdsByRoot({
      [appBundledPluginRoot("feishu")]: "feishu",
      [appBundledPluginRoot("msteams")]: "msteams",
    });

    const map = resolveBundledPluginSources({});

    expect(Array.from(map.keys())).toEqual(["feishu", "msteams"]);
    expect(map.get("feishu")).toEqual(
      createResolvedBundledSource({
        pluginId: "feishu",
        localPath: appBundledPluginRoot("feishu"),
      }),
    );
  });

  it.each([
    [
      "finds bundled source by npm spec",
      { kind: "npmSpec", value: "@nova/feishu" } as const,
      { pluginId: "feishu", localPath: appBundledPluginRoot("feishu") },
    ],
    [
      "returns undefined for missing npm spec",
      { kind: "npmSpec", value: "@nova/not-found" } as const,
      undefined,
    ],
    [
      "finds bundled source by plugin id",
      { kind: "pluginId", value: "diffs" } as const,
      { pluginId: "diffs", localPath: appBundledPluginRoot("diffs") },
    ],
    [
      "finds bundled source by local path",
      { kind: "localPath", value: appBundledPluginRoot("diffs") } as const,
      { pluginId: "diffs", localPath: appBundledPluginRoot("diffs") },
    ],
    [
      "returns undefined for missing plugin id",
      { kind: "pluginId", value: "not-found" } as const,
      undefined,
    ],
  ] as const)("%s", (_name, lookup, expected) => {
    expectBundledSourceLookupCase({ lookup, expected });
  });

  it("forwards an explicit env to bundled discovery helpers", () => {
    setBundledDiscoveryCandidates([]);

    const env = { HOME: "/tmp/nova-home" } as NodeJS.ProcessEnv;

    resolveBundledPluginSources({
      workspaceDir: "/workspace",
      env,
    });
    findBundledPluginSource({
      lookup: { kind: "pluginId", value: "feishu" },
      workspaceDir: "/workspace",
      env,
    });

    expect(discoverNovaPluginsMock).toHaveBeenNthCalledWith(1, {
      workspaceDir: "/workspace",
      env,
    });
    expect(discoverNovaPluginsMock).toHaveBeenNthCalledWith(2, {
      workspaceDir: "/workspace",
      env,
    });
  });

  it("marks bundled sources that require plugin config before activation", () => {
    setBundledDiscoveryCandidates([
      createBundledCandidate({
        rootDir: appBundledPluginRoot("memory-lancedb"),
        packageName: "@nova/memory-lancedb",
      }),
    ]);
    setBundledManifestIdsByRoot({
      [appBundledPluginRoot("memory-lancedb")]: {
        id: "memory-lancedb",
        required: ["embedding"],
      },
    });

    expect(resolveBundledPluginSources({}).get("memory-lancedb")).toEqual(
      createResolvedBundledSource({
        pluginId: "memory-lancedb",
        localPath: appBundledPluginRoot("memory-lancedb"),
        configSchema: {
          type: "object",
          required: ["embedding"],
        },
        requiresConfig: true,
      }),
    );
  });

  it("reuses a pre-resolved bundled map for repeated lookups", () => {
    const bundled = new Map([
      [
        "feishu",
        createResolvedBundledSource({
          pluginId: "feishu",
          localPath: appBundledPluginRoot("feishu"),
        }),
      ],
    ]);

    expect(
      findBundledPluginSourceInMap({
        bundled,
        lookup: { kind: "pluginId", value: "feishu" },
      }),
    ).toEqual(
      createResolvedBundledSource({
        pluginId: "feishu",
        localPath: appBundledPluginRoot("feishu"),
      }),
    );
    expect(
      findBundledPluginSourceInMap({
        bundled,
        lookup: { kind: "npmSpec", value: "@nova/feishu" },
      })?.pluginId,
    ).toBe("feishu");
  });
});
