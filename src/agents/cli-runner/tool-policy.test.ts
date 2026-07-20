import { describe, expect, it } from "vitest";
import {
  resolveCliRuntimeToolsAllow,
  resolveLoopbackToolsAllowFromMcpPermissions,
  stripNovaMcpToolPrefix,
} from "./tool-policy.js";

describe("resolveLoopbackToolsAllowFromMcpPermissions", () => {
  it("returns undefined when no MCP permission list is set", () => {
    expect(resolveLoopbackToolsAllowFromMcpPermissions(undefined)).toBeUndefined();
  });

  it("maps prefixed loopback names to gateway tool names", () => {
    expect(
      resolveLoopbackToolsAllowFromMcpPermissions([
        "mcp__nova__memory_search",
        "mcp__nova__memory_get",
      ]),
    ).toEqual(["memory_search", "memory_get"]);
  });

  it("keeps the full surface on wildcard entries", () => {
    expect(resolveLoopbackToolsAllowFromMcpPermissions(["mcp__nova__*"])).toBeUndefined();
    expect(
      resolveLoopbackToolsAllowFromMcpPermissions(["mcp__nova__memory_search", "*"]),
    ).toBeUndefined();
  });

  it("drops tools owned by other MCP servers and fails closed when none remain", () => {
    expect(
      resolveLoopbackToolsAllowFromMcpPermissions([
        "mcp__other__thing",
        "mcp__nova__memory_search",
      ]),
    ).toEqual(["memory_search"]);
    // Only foreign-server entries: the loopback surface exposes nothing.
    expect(resolveLoopbackToolsAllowFromMcpPermissions(["mcp__other__thing"])).toEqual([]);
  });

  it("normalizes and dedupes unprefixed entries", () => {
    expect(
      resolveLoopbackToolsAllowFromMcpPermissions([" Memory_Search ", "memory_search"]),
    ).toEqual(["memory_search"]);
  });
});

describe("stripNovaMcpToolPrefix", () => {
  it("strips only the loopback transport prefix", () => {
    expect(stripNovaMcpToolPrefix("mcp__nova__memory_search")).toBe("memory_search");
    expect(stripNovaMcpToolPrefix("memory_search")).toBe("memory_search");
    expect(stripNovaMcpToolPrefix("mcp__other__tool")).toBe("mcp__other__tool");
  });
});

describe("resolveCliRuntimeToolsAllow", () => {
  it("keeps only real restrictions", () => {
    expect(resolveCliRuntimeToolsAllow(undefined)).toBeUndefined();
    expect(resolveCliRuntimeToolsAllow(["memory_search"], true)).toBeUndefined();
    expect(resolveCliRuntimeToolsAllow(["*"])).toBeUndefined();
    expect(resolveCliRuntimeToolsAllow(["memory_search"])).toEqual(["memory_search"]);
  });
});
