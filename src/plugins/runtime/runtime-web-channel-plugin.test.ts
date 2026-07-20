// Runtime web-channel plugin tests cover web channel plugin activation and runtime behavior.
import { afterEach, describe, expect, it, vi } from "vitest";

afterEach(() => {
  vi.doUnmock("./runtime-plugin-boundary.js");
  vi.resetModules();
});

describe("runtime web channel plugin", () => {
  it("resolves the default auth dir through the light runtime on each call", async () => {
    let authDir = "/tmp/nova-default-auth";
    const resolveDefaultWebAuthDir = vi.fn(() => authDir);

    vi.doMock("./runtime-plugin-boundary.js", () => ({
      loadPluginBoundaryModule: () => ({ resolveDefaultWebAuthDir }),
      resolvePluginRuntimeModulePath: () => "/tmp/light-runtime-api.js",
      resolvePluginRuntimeRecordByEntryBaseNames: () => ({
        origin: "bundled",
        source: "test",
      }),
    }));

    const { resolveWebChannelAuthDir } = await import("./runtime-web-channel-plugin.js");

    expect(resolveWebChannelAuthDir()).toBe("/tmp/nova-default-auth");
    authDir = "/tmp/nova-profile-auth";
    expect(resolveWebChannelAuthDir()).toBe("/tmp/nova-profile-auth");
    expect(resolveDefaultWebAuthDir).toHaveBeenCalledTimes(2);
  });

  it("falls back to the older WhatsApp light runtime auth dir export", async () => {
    vi.doMock("./runtime-plugin-boundary.js", () => ({
      loadPluginBoundaryModule: () => ({ WA_WEB_AUTH_DIR: "/tmp/nova-legacy-auth" }),
      resolvePluginRuntimeModulePath: () => "/tmp/light-runtime-api.js",
      resolvePluginRuntimeRecordByEntryBaseNames: () => ({
        origin: "external",
        source: "test",
      }),
    }));

    const { resolveWebChannelAuthDir } = await import("./runtime-web-channel-plugin.js");

    expect(resolveWebChannelAuthDir()).toBe("/tmp/nova-legacy-auth");
  });

  it("rejects non-string legacy auth dir exports", async () => {
    vi.doMock("./runtime-plugin-boundary.js", () => ({
      loadPluginBoundaryModule: () => ({
        WA_WEB_AUTH_DIR: Object("/tmp/nova-string-object-auth"),
      }),
      resolvePluginRuntimeModulePath: () => "/tmp/light-runtime-api.js",
      resolvePluginRuntimeRecordByEntryBaseNames: () => ({
        origin: "external",
        source: "test",
      }),
    }));

    const { resolveWebChannelAuthDir } = await import("./runtime-web-channel-plugin.js");

    expect(() => resolveWebChannelAuthDir()).toThrow(
      "web channel plugin runtime is missing export 'resolveDefaultWebAuthDir'",
    );
  });
});
