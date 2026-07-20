// Tests version fast-path output before the full entrypoint loads.
import { describe, expect, it, vi } from "vitest";
import { tryHandleRootVersionFastPath } from "./entry.version-fast-path.js";

vi.mock("./cli/argv.js", () => ({
  isRootHelpInvocation: () => false,
  isRootVersionInvocation: (argv: string[]) => argv.includes("--version"),
}));

vi.mock("./cli/container-target.js", () => ({
  parseCliContainerArgs: (argv: string[]) => ({ ok: true, container: null, argv }),
  resolveCliContainerTarget: (argv: string[], env: NodeJS.ProcessEnv = process.env) =>
    argv.includes("--container") ? "demo" : (env.NOVA_CONTAINER ?? null),
}));

async function flushVersionFastPath() {
  await Promise.resolve();
  await Promise.resolve();
}

describe("entry root version fast path", () => {
  it("prints version output and skips host handling when container-targeted", async () => {
    const output = vi.fn();
    const exit = vi.fn();
    const resolveVersion = vi.fn<
      () => Promise<{
        VERSION: string;
        resolveCommitHash: (params: { moduleUrl: string }) => string | null;
      }>
    >(async () => ({
      VERSION: "9.9.9-test",
      resolveCommitHash: vi.fn(() => "abc1234"),
    }));

    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--version"], {
        output,
        exit,
        resolveVersion,
      }),
    ).toBe(true);
    await flushVersionFastPath();
    expect(output).toHaveBeenCalledWith("Nova 9.9.9-test (abc1234)");
    expect(exit).toHaveBeenCalledWith(0);

    output.mockClear();
    exit.mockClear();
    resolveVersion.mockResolvedValueOnce({
      VERSION: "9.9.9-test",
      resolveCommitHash: vi.fn(() => null),
    });

    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--version"], {
        output,
        exit,
        resolveVersion,
      }),
    ).toBe(true);
    await flushVersionFastPath();
    expect(output).toHaveBeenCalledWith("Nova 9.9.9-test");
    expect(exit).toHaveBeenCalledWith(0);

    output.mockClear();
    exit.mockClear();
    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--container", "demo", "--version"], {
        output,
        exit,
        resolveVersion,
      }),
    ).toBe(false);
    expect(resolveVersion).toHaveBeenCalledTimes(2);
    expect(output).not.toHaveBeenCalled();
    expect(exit).not.toHaveBeenCalled();

    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--version"], {
        env: { NOVA_CONTAINER: "demo" },
        output,
        exit,
        resolveVersion,
      }),
    ).toBe(false);
  });

  it("calls exit(1) via injected exit hook when resolveVersion rejects", async () => {
    const exit = vi.fn();
    const output = vi.fn();
    const resolveVersion = vi
      .fn<() => Promise<never>>()
      .mockRejectedValue(new Error("version resolution failed"));

    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--version"], {
        output,
        exit,
        resolveVersion,
      }),
    ).toBe(true);
    await flushVersionFastPath();
    expect(resolveVersion).toHaveBeenCalledTimes(1);
    expect(exit).toHaveBeenCalledWith(1);
    expect(output).not.toHaveBeenCalled();
    expect(exit).toHaveBeenCalledTimes(1);
  });

  it("calls injected onError when provided and resolveVersion rejects", async () => {
    const exit = vi.fn();
    const onError = vi.fn();
    const resolveVersion = vi
      .fn<() => Promise<never>>()
      .mockRejectedValue(new Error("version resolution failed"));

    expect(
      tryHandleRootVersionFastPath(["node", "nova", "--version"], {
        exit,
        onError,
        resolveVersion,
      }),
    ).toBe(true);
    await flushVersionFastPath();
    expect(resolveVersion).toHaveBeenCalledTimes(1);
    expect(onError).toHaveBeenCalledTimes(1);
    expect(exit).not.toHaveBeenCalled();
  });
});
