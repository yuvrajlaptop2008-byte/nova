/**
 * Engine import boundary test.
 *
 * Ensures that engine/ sources only import from `nova/plugin-sdk/*`
 * and never reach into other nova internals directly.
 */

import fs from "node:fs";
import path from "node:path";
import { expectDefined } from "@nova/normalization-core";
import { describe, expect, it } from "vitest";

const ENGINE_DIR = path.resolve(import.meta.dirname);

/** Recursively collect all non-test .ts files under a directory. */
function walkSourceFiles(dir: string, files: string[] = []): string[] {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === "dist") {
        continue;
      }
      walkSourceFiles(fullPath, files);
      continue;
    }
    if (
      entry.name.endsWith(".ts") &&
      !entry.name.endsWith(".test.ts") &&
      !entry.name.endsWith(".spec.ts")
    ) {
      files.push(fullPath);
    }
  }
  return files;
}

/**
 * Extract all `nova/...` import specifiers from source text.
 * Matches: import ... from "nova/...", import("nova/...")
 */
function findnovaImports(source: string): string[] {
  return [
    ...source.matchAll(/from\s+["'](nova\/[^"']+)["']/g),
    ...source.matchAll(/import\(\s*["'](nova\/[^"']+)["']\s*\)/g),
  ].map((match) => expectDefined(match[1], "Nova import specifier"));
}

/** Check if an import specifier is an allowed nova/plugin-sdk subpath. */
const ALLOWED_PREFIX = ["nova", "plugin-sdk"].join("/");
function isAllowedImport(specifier: string): boolean {
  return specifier.startsWith(ALLOWED_PREFIX);
}

describe("engine import boundary", () => {
  it("only imports from nova/plugin-sdk, never from other nova internals", () => {
    const sourceFiles = walkSourceFiles(ENGINE_DIR);
    const offenders: Array<{ file: string; imports: string[] }> = [];

    for (const file of sourceFiles) {
      const source = fs.readFileSync(file, "utf8");
      const novaImports = findnovaImports(source);
      const forbidden = novaImports.filter((specifier) => !isAllowedImport(specifier));

      if (forbidden.length > 0) {
        offenders.push({
          file: path.relative(ENGINE_DIR, file),
          imports: forbidden,
        });
      }
    }

    expect(offenders).toStrictEqual([]);
  });
});
