// Tests gateway process argv parsing for diagnostics.
import { describe, expect, it } from "vitest";
import { isGatewayArgv, isNovaCommandArgv, parseProcCmdline } from "./gateway-process-argv.js";

describe("parseProcCmdline", () => {
  it("splits null-delimited argv and trims empty entries", () => {
    expect(parseProcCmdline(" node \0 gateway \0\0 --port \0 18789 \0")).toEqual([
      "node",
      "gateway",
      "--port",
      "18789",
    ]);
  });

  it("keeps non-delimited single arguments and drops whitespace-only entries", () => {
    expect(parseProcCmdline(" gateway ")).toEqual(["gateway"]);
    expect(parseProcCmdline(" \0\t\0 ")).toStrictEqual([]);
  });
});

describe("isGatewayArgv", () => {
  it("requires a gateway token", () => {
    expect(isGatewayArgv(["node", "dist/index.js", "--port", "18789"])).toBe(false);
  });

  it("matches known entrypoints across slash and case variants", () => {
    expect(isGatewayArgv(["NODE", "C:\\Nova\\DIST\\ENTRY.JS", "gateway"])).toBe(true);
    expect(isGatewayArgv(["bun", "/srv/nova/scripts/run-node.mjs", "gateway"])).toBe(true);
    expect(isGatewayArgv(["node", "/srv/nova/nova.mjs", "gateway"])).toBe(true);
    expect(isGatewayArgv(["tsx", "/srv/nova/src/entry.ts", "gateway"])).toBe(true);
    expect(isGatewayArgv(["tsx", "/srv/nova/src/index.ts", "gateway"])).toBe(true);
  });

  it("matches the nova executable but gates the gateway binary behind the opt-in flag", () => {
    expect(isGatewayArgv(["C:\\bin\\nova.cmd", "gateway"])).toBe(true);
    expect(isGatewayArgv(["/usr/local/bin/nova-gateway", "gateway"])).toBe(false);
    expect(isGatewayArgv(["nova-gateway"])).toBe(false);
    expect(
      isGatewayArgv(["/usr/local/bin/nova-gateway", "gateway"], {
        allowGatewayBinary: true,
      }),
    ).toBe(true);
    expect(
      isGatewayArgv(["C:\\bin\\nova-gateway.EXE", "gateway"], {
        allowGatewayBinary: true,
      }),
    ).toBe(true);
    expect(isGatewayArgv(["nova-gateway"], { allowGatewayBinary: true })).toBe(true);
  });

  it("rejects unknown gateway argv even when the token is present", () => {
    expect(isGatewayArgv(["node", "/srv/nova/custom.js", "gateway"])).toBe(false);
    expect(isGatewayArgv(["python", "gateway", "script.py"])).toBe(false);
  });
});

describe("isNovaCommandArgv", () => {
  it("matches doctor across source, built, and installed entrypoints", () => {
    expect(isNovaCommandArgv(["node", "/srv/nova/nova.mjs", "doctor"], "doctor")).toBe(true);
    expect(isNovaCommandArgv(["NODE", "C:\\Nova\\DIST\\ENTRY.JS", "DOCTOR"], "doctor")).toBe(true);
    expect(isNovaCommandArgv(["C:\\bin\\nova.cmd", "doctor", "--fix"], "doctor")).toBe(true);
  });

  it("rejects other Nova commands and unrelated doctor processes", () => {
    expect(isNovaCommandArgv(["nova", "gateway"], "doctor")).toBe(false);
    expect(isNovaCommandArgv(["python", "doctor", "worker.py"], "doctor")).toBe(false);
  });
});
