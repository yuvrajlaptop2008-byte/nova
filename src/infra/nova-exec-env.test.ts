// Tests Nova execution environment construction.
import { describe, expect, it } from "vitest";
import { deleteTestEnvValue, setTestEnvValue } from "../test-utils/env.js";
import {
  ensureNovaExecMarkerOnProcess,
  markNovaExecEnv,
  NOVA_CLI_ENV_VAR,
} from "./nova-exec-env.js";

const NOVA_CLI_ENV_VALUE = "1";

describe("markNovaExecEnv", () => {
  it("returns a cloned env object with the exec marker set", () => {
    const env = { PATH: "/usr/bin", NOVA_CLI: "0" };
    const marked = markNovaExecEnv(env);

    expect(marked).toEqual({
      PATH: "/usr/bin",
      NOVA_CLI: NOVA_CLI_ENV_VALUE,
    });
    expect(marked).not.toBe(env);
    expect(env.NOVA_CLI).toBe("0");
  });
});

describe("ensureNovaExecMarkerOnProcess", () => {
  it.each([
    {
      name: "mutates and returns the provided process env",
      env: { PATH: "/usr/bin" } as NodeJS.ProcessEnv,
    },
    {
      name: "overwrites an existing marker on the provided process env",
      env: { PATH: "/usr/bin", [NOVA_CLI_ENV_VAR]: "0" } as NodeJS.ProcessEnv,
    },
  ])("$name", ({ env }) => {
    expect(ensureNovaExecMarkerOnProcess(env)).toBe(env);
    expect(env[NOVA_CLI_ENV_VAR]).toBe(NOVA_CLI_ENV_VALUE);
  });

  it("defaults to mutating process.env when no env object is provided", () => {
    const previous = process.env[NOVA_CLI_ENV_VAR];
    deleteTestEnvValue(NOVA_CLI_ENV_VAR);

    try {
      expect(ensureNovaExecMarkerOnProcess()).toBe(process.env);
      expect(process.env[NOVA_CLI_ENV_VAR]).toBe(NOVA_CLI_ENV_VALUE);
    } finally {
      if (previous === undefined) {
        deleteTestEnvValue(NOVA_CLI_ENV_VAR);
      } else {
        setTestEnvValue(NOVA_CLI_ENV_VAR, previous);
      }
    }
  });
});
