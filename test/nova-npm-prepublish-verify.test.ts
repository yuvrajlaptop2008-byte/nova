import { describe, expect, it } from "vitest";
import {
  novaNpmPrepublishVerifyUsage,
  parseNovaNpmPrepublishVerifyArgs,
  usesPreparedLocalDependencyInstall,
} from "../scripts/nova-npm-prepublish-verify.ts";

describe("parseNovaNpmPrepublishVerifyArgs", () => {
  it("supports help, optional versions, and package-manager separators", () => {
    expect(parseNovaNpmPrepublishVerifyArgs(["--help"])).toEqual({
      dependencyTarballPaths: [],
      help: true,
      tarballPath: "",
    });
    expect(parseNovaNpmPrepublishVerifyArgs(["nova.tgz"])).toEqual({
      dependencyTarballPaths: [],
      help: false,
      tarballPath: "nova.tgz",
    });
    expect(parseNovaNpmPrepublishVerifyArgs(["--", "nova.tgz", "2026.3.23"])).toEqual({
      dependencyTarballPaths: [],
      expectedVersion: "2026.3.23",
      help: false,
      tarballPath: "nova.tgz",
    });
  });

  it("rejects missing, option-like, and extra arguments before installing", () => {
    expect(() => parseNovaNpmPrepublishVerifyArgs([])).toThrow(novaNpmPrepublishVerifyUsage());
    expect(() => parseNovaNpmPrepublishVerifyArgs(["--tag"])).toThrow(
      "Unknown nova npm prepublish verifier option: --tag",
    );
    expect(() => parseNovaNpmPrepublishVerifyArgs(["nova.tgz", "--tag"])).toThrow(
      "Unknown nova npm prepublish verifier option: --tag",
    );
    expect(
      parseNovaNpmPrepublishVerifyArgs(["nova.tgz", "2026.3.23", "llm-core.tgz", "ai.tgz"]),
    ).toEqual({
      dependencyTarballPaths: ["llm-core.tgz", "ai.tgz"],
      expectedVersion: "2026.3.23",
      help: false,
      tarballPath: "nova.tgz",
    });
    expect(() => parseNovaNpmPrepublishVerifyArgs(["nova.tgz", "2026.3.23", "--bad"])).toThrow(
      "Invalid dependency tarball path: --bad",
    );
  });
});

describe("usesPreparedLocalDependencyInstall", () => {
  it("uses the prepared local project only for the single AI tarball release path", () => {
    expect(usesPreparedLocalDependencyInstall(0)).toBe(false);
    expect(usesPreparedLocalDependencyInstall(1)).toBe(true);
    expect(usesPreparedLocalDependencyInstall(2)).toBe(false);
  });
});
