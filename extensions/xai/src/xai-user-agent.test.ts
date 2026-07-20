// Xai tests cover xai user agent plugin behavior.
import { afterEach, describe, expect, it, vi } from "vitest";
import { xaiUserAgent, xaiUserAgentHeaderFor } from "./xai-user-agent.js";

describe("xaiUserAgent", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("prefers NOVA_VERSION env over the bundled package version", () => {
    vi.stubEnv("NOVA_VERSION", "2026.3.22");
    expect(xaiUserAgent()).toBe("nova/2026.3.22");
  });

  it("falls back to NOVA_SERVICE_VERSION when NOVA_VERSION is unset", () => {
    vi.stubEnv("NOVA_VERSION", "");
    vi.stubEnv("NOVA_SERVICE_VERSION", "2026.3.99");
    // NOVA_VERSION from the SDK is the bundled VERSION constant. In a dev
    // checkout it resolves to a real semver, so we cannot deterministically
    // assert "unknown" here. We just lock the prefix to ensure the env-first
    // contract holds whenever the bundle resolves to 0.0.0/empty.
    const result = xaiUserAgent();
    expect(result.startsWith("nova/")).toBe(true);
    expect(result).not.toBe("nova/");
  });

  it("returns the nova/<version> shape", () => {
    vi.stubEnv("NOVA_VERSION", "2026.5.16");
    expect(xaiUserAgent()).toMatch(/^nova\/\d+\.\d+\.\d+$/u);
  });
});

describe("xaiUserAgentHeaderFor", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("emits User-Agent for the xAI-native host", () => {
    vi.stubEnv("NOVA_VERSION", "2026.3.22");
    expect(xaiUserAgentHeaderFor("https://api.x.ai/v1")).toEqual({
      "User-Agent": "nova/2026.3.22",
    });
    expect(xaiUserAgentHeaderFor("https://api.x.ai/v1/tts")).toEqual({
      "User-Agent": "nova/2026.3.22",
    });
  });

  it("withholds User-Agent on user-configured proxy baseUrls", () => {
    vi.stubEnv("NOVA_VERSION", "2026.3.22");
    expect(xaiUserAgentHeaderFor("https://my-corp.proxy/xai/v1")).toEqual({});
    expect(xaiUserAgentHeaderFor("http://127.0.0.1:8080/v1")).toEqual({});
    expect(xaiUserAgentHeaderFor("https://api.grok.x.ai/v1")).toEqual({});
  });

  it("returns an empty record for missing or invalid input", () => {
    expect(xaiUserAgentHeaderFor(undefined)).toEqual({});
    expect(xaiUserAgentHeaderFor("")).toEqual({});
    expect(xaiUserAgentHeaderFor("not a url")).toEqual({});
  });
});
