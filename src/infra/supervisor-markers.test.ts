// Covers supervisor marker files used to identify managed Nova processes.
import { describe, expect, it } from "vitest";
import {
  detectGatewayRespawnSupervisor,
  detectRespawnSupervisor,
  SUPERVISOR_HINT_ENV_VARS,
} from "./supervisor-markers.js";

describe("SUPERVISOR_HINT_ENV_VARS", () => {
  it("includes the cross-platform supervisor hint env vars", () => {
    const envVars = new Set(SUPERVISOR_HINT_ENV_VARS);
    expect(envVars.has("NOVA_SUPERVISOR_MODE")).toBe(true);
    expect(envVars.has("LAUNCH_JOB_LABEL")).toBe(true);
    expect(envVars.has("INVOCATION_ID")).toBe(true);
    expect(envVars.has("NOVA_WINDOWS_TASK_NAME")).toBe(true);
    expect(envVars.has("NOVA_SERVICE_MARKER")).toBe(true);
    expect(envVars.has("NOVA_SERVICE_KIND")).toBe(true);
  });
});

describe("detectRespawnSupervisor", () => {
  it("detects launchd from Nova's explicit marker or current gateway launchd job", () => {
    expect(detectRespawnSupervisor({ NOVA_LAUNCHD_LABEL: " ai.nova.gateway " }, "darwin")).toBe(
      "launchd",
    );
    expect(detectRespawnSupervisor({ NOVA_LAUNCHD_LABEL: "   " }, "darwin")).toBeNull();
    expect(detectRespawnSupervisor({ LAUNCH_JOB_LABEL: "ai.nova.gateway" }, "darwin")).toBe(
      "launchd",
    );
    expect(
      detectRespawnSupervisor({ LAUNCH_JOB_NAME: "ai.nova.work", NOVA_PROFILE: "work" }, "darwin"),
    ).toBe("launchd");
    expect(detectRespawnSupervisor({ LAUNCH_JOB_LABEL: "ai.nova.mac" }, "darwin")).toBeNull();
    expect(detectRespawnSupervisor({ XPC_SERVICE_NAME: "ai.nova.mac" }, "darwin")).toBeNull();
    expect(
      detectRespawnSupervisor({ XPC_SERVICE_NAME: "ai.nova.mac", NOVA_PROFILE: "mac" }, "darwin"),
    ).toBeNull();
    expect(detectRespawnSupervisor({ XPC_SERVICE_NAME: "ai.nova.gateway" }, "darwin")).toBe(
      "launchd",
    );
  });

  it("detects systemd only from non-blank platform-specific hints", () => {
    expect(detectRespawnSupervisor({ INVOCATION_ID: "abc123" }, "linux")).toBe("systemd");
    expect(detectRespawnSupervisor({ JOURNAL_STREAM: "" }, "linux")).toBeNull();
  });

  it("detects Linux Nova gateway service markers only for opt-in callers", () => {
    const gatewayServiceEnv = {
      NOVA_SERVICE_MARKER: " nova ",
      NOVA_SERVICE_KIND: " gateway ",
    };
    expect(detectRespawnSupervisor(gatewayServiceEnv, "linux")).toBeNull();
    expect(
      detectRespawnSupervisor(gatewayServiceEnv, "linux", {
        includeLinuxNovaGatewayServiceMarker: true,
      }),
    ).toBe("systemd");
    expect(
      detectRespawnSupervisor(
        {
          NOVA_SERVICE_MARKER: "nova",
          NOVA_SERVICE_KIND: "worker",
        },
        "linux",
        { includeLinuxNovaGatewayServiceMarker: true },
      ),
    ).toBeNull();
    expect(
      detectRespawnSupervisor(
        {
          NOVA_SERVICE_MARKER: "other",
          NOVA_SERVICE_KIND: "gateway",
        },
        "linux",
        { includeLinuxNovaGatewayServiceMarker: true },
      ),
    ).toBeNull();
  });

  it("detects scheduled-task supervision on Windows from either hint family", () => {
    expect(detectRespawnSupervisor({ NOVA_WINDOWS_TASK_NAME: "Nova Gateway" }, "win32")).toBe(
      "schtasks",
    );
    expect(
      detectRespawnSupervisor(
        {
          NOVA_SERVICE_MARKER: "nova",
          NOVA_SERVICE_KIND: "gateway",
        },
        "win32",
      ),
    ).toBe("schtasks");
    expect(
      detectRespawnSupervisor(
        {
          NOVA_SERVICE_MARKER: "nova",
          NOVA_SERVICE_KIND: "worker",
        },
        "win32",
      ),
    ).toBeNull();
  });

  it("ignores service markers on non-Windows platforms and unknown platforms", () => {
    expect(
      detectRespawnSupervisor(
        {
          NOVA_SERVICE_MARKER: "nova",
          NOVA_SERVICE_KIND: "gateway",
        },
        "linux",
      ),
    ).toBeNull();
    expect(detectRespawnSupervisor({ LAUNCH_JOB_LABEL: "ai.nova.gateway" }, "freebsd")).toBeNull();
  });
});

describe("detectGatewayRespawnSupervisor", () => {
  it("keeps external ownership separate from native supervisor detection", () => {
    const env = {
      NOVA_SUPERVISOR_MODE: "external",
      NOVA_LAUNCHD_LABEL: "ai.nova.gateway",
    };

    expect(detectGatewayRespawnSupervisor(env, "darwin")).toBe("external");
    expect(detectRespawnSupervisor(env, "darwin")).toBe("launchd");
  });
});
