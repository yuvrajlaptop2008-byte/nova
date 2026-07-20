import { describe, expect, it } from "vitest";
import type { BundledPluginSource } from "./bundled-sources.js";
import { isNovaTrustedPluginInstallSpec } from "./install-provenance.js";

const bundledSources = new Map<string, BundledPluginSource>([
  [
    "discord",
    {
      pluginId: "discord",
      localPath: "/opt/nova/extensions/discord",
      npmSpec: "@nova/discord",
    },
  ],
]);

describe("plugin install provenance", () => {
  it.each([
    "discord",
    "@nova/discord",
    "npm:@nova/discord",
    "/opt/nova/extensions/discord",
    "brave",
    "npm:@nova/brave-plugin",
    "clawhub:nova-demo",
  ])("trusts Nova-owned install source %s", (spec) => {
    expect(isNovaTrustedPluginInstallSpec(spec, bundledSources)).toBe(true);
  });

  it.each(["npm:discord", "npm:@example/plugin", "/tmp/example-plugin"])(
    "keeps arbitrary install source %s untrusted",
    (spec) => {
      expect(isNovaTrustedPluginInstallSpec(spec, bundledSources)).toBe(false);
    },
  );
});
