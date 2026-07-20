// Covers plugin peer linking for development installs.
import fs from "node:fs";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  auditNovaPeerDependenciesInManagedNpmRoot,
  linkNovaPeerDependencies,
  relinkNovaPeerDependenciesInManagedNpmRoot,
} from "./plugin-peer-link.js";
import { cleanupTrackedTempDirs, makeTrackedTempDir } from "./test-helpers/fs-fixtures.js";

const tempDirs: string[] = [];

afterEach(() => {
  cleanupTrackedTempDirs(tempDirs);
});

function makeTempDir() {
  return makeTrackedTempDir("nova-plugin-peer-link", tempDirs);
}

describe("plugin peer links", () => {
  it("relinks nova peers in the managed npm root", async () => {
    const npmRoot = makeTempDir();
    const packageDir = path.join(npmRoot, "node_modules", "peer-plugin");
    fs.mkdirSync(packageDir, { recursive: true });
    fs.writeFileSync(
      path.join(packageDir, "package.json"),
      JSON.stringify({
        name: "peer-plugin",
        version: "1.0.0",
        peerDependencies: {
          nova: ">=2026.0.0",
        },
      }),
      "utf8",
    );

    const messages: string[] = [];
    const result = await relinkNovaPeerDependenciesInManagedNpmRoot({
      npmRoot,
      logger: {
        info: (message) => messages.push(message),
        warn: (message) => messages.push(message),
      },
    });

    const linkPath = path.join(packageDir, "node_modules", "nova");
    expect(result).toEqual({ checked: 1, attempted: 1, repaired: 1, skipped: 0 });
    expect(fs.lstatSync(linkPath).isSymbolicLink()).toBe(true);
    expect(fs.realpathSync(linkPath)).toBe(fs.realpathSync(process.cwd()));
    expect(messages.join("\n")).toContain('Linked peerDependency "nova"');
  });

  it("reports one unreadable package and continues repairing its sibling", async () => {
    const npmRoot = makeTempDir();
    const unreadableDir = path.join(npmRoot, "node_modules", "bad-plugin");
    const peerDir = path.join(npmRoot, "node_modules", "peer-plugin");
    fs.mkdirSync(unreadableDir, { recursive: true });
    fs.mkdirSync(peerDir, { recursive: true });
    fs.writeFileSync(path.join(unreadableDir, "package.json"), "{", "utf8");
    fs.writeFileSync(
      path.join(peerDir, "package.json"),
      JSON.stringify({
        name: "peer-plugin",
        peerDependencies: { nova: ">=2026.0.0" },
      }),
      "utf8",
    );
    const failures: Array<{ error: unknown; packageDir: string }> = [];

    const result = await relinkNovaPeerDependenciesInManagedNpmRoot({
      npmRoot,
      logger: {},
      onPackageReadError: (error, packageDir) => failures.push({ error, packageDir }),
    });

    expect(result).toEqual({ checked: 1, attempted: 1, repaired: 1, skipped: 1 });
    expect(failures).toHaveLength(1);
    expect(failures[0]?.packageDir).toBe(unreadableDir);
    expect(failures[0]?.error).toBeInstanceOf(SyntaxError);
    expect(fs.lstatSync(path.join(peerDir, "node_modules", "nova")).isSymbolicLink()).toBe(true);
  });

  it("reports one unreadable package and continues auditing its sibling", async () => {
    const npmRoot = makeTempDir();
    const unreadableDir = path.join(npmRoot, "node_modules", "bad-plugin");
    const peerDir = path.join(npmRoot, "node_modules", "peer-plugin");
    fs.mkdirSync(unreadableDir, { recursive: true });
    fs.mkdirSync(peerDir, { recursive: true });
    fs.writeFileSync(path.join(unreadableDir, "package.json"), "{", "utf8");
    fs.writeFileSync(
      path.join(peerDir, "package.json"),
      JSON.stringify({
        name: "peer-plugin",
        peerDependencies: { nova: ">=2026.0.0" },
      }),
      "utf8",
    );
    const failures: Array<{ error: unknown; packageDir: string }> = [];

    const result = await auditNovaPeerDependenciesInManagedNpmRoot({
      npmRoot,
      onPackageReadError: (error, packageDir) => failures.push({ error, packageDir }),
    });

    expect(result.checked).toBe(1);
    expect(result.broken).toBe(1);
    expect(result.issues[0]?.packageName).toBe("peer-plugin");
    expect(failures).toHaveLength(1);
    expect(failures[0]?.packageDir).toBe(unreadableDir);
  });

  it("audits missing managed npm nova peer links without relinking", async () => {
    const npmRoot = makeTempDir();
    const packageDir = path.join(npmRoot, "node_modules", "peer-plugin");
    fs.mkdirSync(packageDir, { recursive: true });
    fs.writeFileSync(
      path.join(packageDir, "package.json"),
      JSON.stringify({
        name: "peer-plugin",
        version: "1.0.0",
        peerDependencies: {
          nova: ">=2026.0.0",
        },
      }),
      "utf8",
    );

    const result = await auditNovaPeerDependenciesInManagedNpmRoot({ npmRoot });

    const linkPath = path.join(packageDir, "node_modules", "nova");
    expect(result.checked).toBe(1);
    expect(result.broken).toBe(1);
    expect(result.issues[0]?.packageName).toBe("peer-plugin");
    expect(result.issues[0]?.reason).toContain(linkPath);
    expect(fs.existsSync(linkPath)).toBe(false);
  });

  it.runIf(process.platform !== "win32")(
    "does not follow a package-local node_modules symlink while linking nova peers",
    async () => {
      const root = makeTempDir();
      const packageDir = path.join(root, "peer-plugin");
      const outsideDir = path.join(root, "outside-node-modules");
      fs.mkdirSync(packageDir, { recursive: true });
      fs.mkdirSync(outsideDir, { recursive: true });
      fs.symlinkSync(outsideDir, path.join(packageDir, "node_modules"), "dir");

      const warnings: string[] = [];
      const result = await linkNovaPeerDependencies({
        installedDir: packageDir,
        peerDependencies: {
          nova: ">=2026.0.0",
        },
        logger: {
          warn: (message) => warnings.push(message),
        },
      });

      expect(result).toEqual({ repaired: 0, skipped: 1 });
      expect(fs.existsSync(path.join(outsideDir, "nova"))).toBe(false);
      expect(warnings.join("\n")).toContain("is not a real directory");
    },
  );

  it("replaces an existing real nova package directory", async () => {
    const root = makeTempDir();
    const packageDir = path.join(root, "peer-plugin");
    const existingNovaDir = path.join(packageDir, "node_modules", "nova");
    fs.mkdirSync(existingNovaDir, { recursive: true });
    fs.writeFileSync(path.join(existingNovaDir, "package.json"), '{"name":"nova"}', "utf8");

    const messages: string[] = [];
    const result = await linkNovaPeerDependencies({
      installedDir: packageDir,
      peerDependencies: {
        nova: ">=2026.0.0",
      },
      logger: {
        info: (message) => messages.push(message),
      },
    });

    expect(result).toEqual({ repaired: 1, skipped: 0 });
    expect(fs.lstatSync(existingNovaDir).isSymbolicLink()).toBe(true);
    expect(fs.realpathSync(existingNovaDir)).toBe(fs.realpathSync(process.cwd()));
    expect(messages.join("\n")).toContain('Linked peerDependency "nova"');
  });

  it("does not delete an unrelated existing package directory", async () => {
    const root = makeTempDir();
    const packageDir = path.join(root, "peer-plugin");
    const existingNovaDir = path.join(packageDir, "node_modules", "nova");
    fs.mkdirSync(existingNovaDir, { recursive: true });
    fs.writeFileSync(path.join(existingNovaDir, "package.json"), '{"name":"not-nova"}', "utf8");

    const warnings: string[] = [];
    const result = await linkNovaPeerDependencies({
      installedDir: packageDir,
      peerDependencies: {
        nova: ">=2026.0.0",
      },
      logger: {
        warn: (message) => warnings.push(message),
      },
    });

    expect(result).toEqual({ repaired: 0, skipped: 1 });
    expect(fs.existsSync(path.join(existingNovaDir, "package.json"))).toBe(true);
    expect(warnings.join("\n")).toContain("already exists and is not a symlink");
  });
});
