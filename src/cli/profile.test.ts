// Profile CLI tests cover profile selection, persistence, and command wiring.
import path from "node:path";
import { describe, expect, it } from "vitest";
import { formatCliCommand } from "./command-format.js";
import { applyCliProfileEnv, parseCliProfileArgs } from "./profile.js";

describe("parseCliProfileArgs", () => {
  it("leaves gateway --dev for subcommands", () => {
    const res = parseCliProfileArgs(["node", "nova", "gateway", "--dev", "--allow-unconfigured"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual(["node", "nova", "gateway", "--dev", "--allow-unconfigured"]);
  });

  it("leaves gateway --dev for subcommands after leading root options", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "--no-color",
      "gateway",
      "--dev",
      "--allow-unconfigured",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual([
      "node",
      "nova",
      "--no-color",
      "gateway",
      "--dev",
      "--allow-unconfigured",
    ]);
  });

  it("still accepts global --dev before subcommand", () => {
    const res = parseCliProfileArgs(["node", "nova", "--dev", "gateway"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("dev");
    expect(res.argv).toEqual(["node", "nova", "gateway"]);
  });

  it("parses --profile value and strips it", () => {
    const res = parseCliProfileArgs(["node", "nova", "--profile", "work", "status"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "status"]);
  });

  it("parses interleaved --profile after the command token", () => {
    const res = parseCliProfileArgs(["node", "nova", "status", "--profile", "work", "--deep"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "status", "--deep"]);
  });

  it("preserves Matrix QA --profile for the command parser", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "matrix",
      "--profile",
      "fast",
      "--fail-fast",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual(["node", "nova", "qa", "matrix", "--profile", "fast", "--fail-fast"]);
  });

  it("preserves Matrix QA --profile after leading root options", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "--no-color",
      "qa",
      "matrix",
      "--profile=fast",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual(["node", "nova", "--no-color", "qa", "matrix", "--profile=fast"]);
  });

  it("parses qa run --profile smoke-ci as a root profile", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "run",
      "--profile",
      "smoke-ci",
      "--category",
      "agent-runtime-and-provider-execution.agent-turn-execution",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("smoke-ci");
    expect(res.argv).toEqual([
      "node",
      "nova",
      "qa",
      "run",
      "--category",
      "agent-runtime-and-provider-execution.agent-turn-execution",
    ]);
  });

  it("parses qa run --profile=release self-check invocations as root profiles", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "run",
      "--profile=release",
      "--output",
      "qa-report.md",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("release");
    expect(res.argv).toEqual(["node", "nova", "qa", "run", "--output", "qa-report.md"]);
  });

  it("preserves qa run --qa-profile for the command parser", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "run",
      "--qa-profile",
      "smoke-ci",
      "--surface",
      "agent-runtime-and-provider-execution",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual([
      "node",
      "nova",
      "qa",
      "run",
      "--qa-profile",
      "smoke-ci",
      "--surface",
      "agent-runtime-and-provider-execution",
    ]);
  });

  it("parses arbitrary qa run --profile values as root profiles", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "run",
      "--profile",
      "work",
      "--output",
      "qa-report.md",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "qa", "run", "--output", "qa-report.md"]);
  });

  it("parses arbitrary qa run --profile= values as root profiles", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "qa",
      "run",
      "--profile=work",
      "--output",
      "qa-report.md",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "qa", "run", "--output", "qa-report.md"]);
  });

  it("still parses root --profile before qa run", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "--profile",
      "work",
      "qa",
      "run",
      "--qa-profile",
      "smoke-ci",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "qa", "run", "--qa-profile", "smoke-ci"]);
  });

  it("still parses root --profile before Matrix QA", () => {
    const res = parseCliProfileArgs([
      "node",
      "nova",
      "--profile",
      "work",
      "qa",
      "matrix",
      "--fail-fast",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "nova", "qa", "matrix", "--fail-fast"]);
  });

  it("parses interleaved --dev after the command token", () => {
    const res = parseCliProfileArgs(["node", "nova", "status", "--dev"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("dev");
    expect(res.argv).toEqual(["node", "nova", "status"]);
  });

  it("rejects missing profile value", () => {
    const res = parseCliProfileArgs(["node", "nova", "--profile"]);
    expect(res.ok).toBe(false);
  });

  it.each([
    ["--dev first", ["node", "nova", "--dev", "--profile", "work", "status"]],
    ["--profile first", ["node", "nova", "--profile", "work", "--dev", "status"]],
    ["interleaved after command", ["node", "nova", "status", "--profile", "work", "--dev"]],
  ])("rejects combining --dev with --profile (%s)", (_name, argv) => {
    const res = parseCliProfileArgs(argv);
    expect(res.ok).toBe(false);
  });
});

describe("applyCliProfileEnv", () => {
  it("fills env defaults for dev profile", () => {
    const env: Record<string, string | undefined> = {};
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    const expectedStateDir = path.join(path.resolve("/home/peter"), ".nova-dev");
    expect(env.NOVA_PROFILE).toBe("dev");
    expect(env.NOVA_STATE_DIR).toBe(expectedStateDir);
    expect(env.NOVA_CONFIG_PATH).toBe(path.join(expectedStateDir, "nova.json"));
    expect(env.NOVA_GATEWAY_PORT).toBe("19001");
  });

  it("does not override explicit env values", () => {
    const env: Record<string, string | undefined> = {
      NOVA_PROFILE: "prod",
      NOVA_STATE_DIR: "/custom",
      NOVA_GATEWAY_PORT: "19099",
    };
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    expect(env.NOVA_PROFILE).toBe("dev");
    expect(env.NOVA_STATE_DIR).toBe("/custom");
    expect(env.NOVA_GATEWAY_PORT).toBe("19099");
    expect(env.NOVA_CONFIG_PATH).toBe(path.join("/custom", "nova.json"));
  });

  it("uses NOVA_HOME when deriving profile state dir", () => {
    const env: Record<string, string | undefined> = {
      NOVA_HOME: "/srv/nova-home",
      HOME: "/home/other",
    };
    applyCliProfileEnv({
      profile: "work",
      env,
      homedir: () => "/home/fallback",
    });

    const resolvedHome = path.resolve("/srv/nova-home");
    expect(env.NOVA_STATE_DIR).toBe(path.join(resolvedHome, ".nova-work"));
    expect(env.NOVA_CONFIG_PATH).toBe(path.join(resolvedHome, ".nova-work", "nova.json"));
  });
});

describe("formatCliCommand", () => {
  it.each([
    {
      name: "no profile is set",
      cmd: "nova doctor --fix",
      env: {},
      expected: "nova doctor --fix",
    },
    {
      name: "profile is default",
      cmd: "nova doctor --fix",
      env: { NOVA_PROFILE: "default" },
      expected: "nova doctor --fix",
    },
    {
      name: "profile is Default (case-insensitive)",
      cmd: "nova doctor --fix",
      env: { NOVA_PROFILE: "Default" },
      expected: "nova doctor --fix",
    },
    {
      name: "profile is invalid",
      cmd: "nova doctor --fix",
      env: { NOVA_PROFILE: "bad profile" },
      expected: "nova doctor --fix",
    },
    {
      name: "--profile is already present",
      cmd: "nova --profile work doctor --fix",
      env: { NOVA_PROFILE: "work" },
      expected: "nova --profile work doctor --fix",
    },
    {
      name: "--dev is already present",
      cmd: "nova --dev doctor",
      env: { NOVA_PROFILE: "dev" },
      expected: "nova --dev doctor",
    },
  ])("returns command unchanged when $name", ({ cmd, env, expected }) => {
    expect(formatCliCommand(cmd, env)).toBe(expected);
  });

  it("inserts --profile flag when profile is set", () => {
    expect(formatCliCommand("nova doctor --fix", { NOVA_PROFILE: "work" })).toBe(
      "nova --profile work doctor --fix",
    );
  });

  it("trims whitespace from profile", () => {
    expect(formatCliCommand("nova doctor --fix", { NOVA_PROFILE: "  jbnova  " })).toBe(
      "nova --profile jbnova doctor --fix",
    );
  });

  it("handles command with no args after nova", () => {
    expect(formatCliCommand("nova", { NOVA_PROFILE: "test" })).toBe("nova --profile test");
  });

  it("handles pnpm wrapper", () => {
    expect(formatCliCommand("pnpm nova doctor", { NOVA_PROFILE: "work" })).toBe(
      "pnpm nova --profile work doctor",
    );
  });

  it("inserts --container when a container hint is set", () => {
    expect(formatCliCommand("nova gateway status --deep", { NOVA_CONTAINER_HINT: "demo" })).toBe(
      "nova --container demo gateway status --deep",
    );
  });

  it("ignores unsafe container hints", () => {
    expect(
      formatCliCommand("nova gateway status --deep", {
        NOVA_CONTAINER_HINT: "demo; rm -rf /",
      }),
    ).toBe("nova gateway status --deep");
  });

  it("preserves both --container and --profile hints", () => {
    expect(
      formatCliCommand("nova doctor", {
        NOVA_CONTAINER_HINT: "demo",
        NOVA_PROFILE: "work",
      }),
    ).toBe("nova --container demo doctor");
  });

  it("does not prepend --container for update commands", () => {
    expect(formatCliCommand("nova update", { NOVA_CONTAINER_HINT: "demo" })).toBe("nova update");
    expect(
      formatCliCommand("pnpm nova update --channel beta", { NOVA_CONTAINER_HINT: "demo" }),
    ).toBe("pnpm nova update --channel beta");
  });
});
