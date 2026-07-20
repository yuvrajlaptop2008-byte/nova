// Covers browser-safe importing of temp-dir helpers with fs shims.
import { Buffer } from "node:buffer";
import crypto from "node:crypto";
import { expectDefined } from "@nova/normalization-core";
import { build, type Plugin } from "esbuild";
import { describe, expect, it } from "vitest";

describe("tmp-nova-dir browser-safe import", () => {
  it("loads when a browser fs shim omits constants", async () => {
    const resultKey = `__novaTmpDirBrowserImport_${crypto.randomUUID().replaceAll("-", "_")}`;
    const nodeShimPlugin: Plugin = {
      name: "node-browser-shims",
      setup(pluginBuild) {
        pluginBuild.onResolve({ filter: /^node:(fs|os|path)$/ }, (args) => ({
          path: args.path,
          namespace: "node-browser-shim",
        }));
        pluginBuild.onLoad({ filter: /^node:fs$/, namespace: "node-browser-shim" }, () => ({
          contents: "export default { constants: undefined };",
          loader: "js",
        }));
        pluginBuild.onLoad({ filter: /^node:os$/, namespace: "node-browser-shim" }, () => ({
          contents: 'export const tmpdir = () => "/tmp";',
          loader: "js",
        }));
        pluginBuild.onLoad({ filter: /^node:path$/, namespace: "node-browser-shim" }, () => ({
          contents: "export default { join: (...parts) => parts.join('/') };",
          loader: "js",
        }));
      },
    };

    const bundled = await build({
      bundle: true,
      format: "esm",
      platform: "browser",
      plugins: [nodeShimPlugin],
      stdin: {
        contents: `
          import { POSIX_NOVA_TMP_DIR, resolvePreferredNovaTmpDir } from "./src/infra/tmp-nova-dir.ts";
          globalThis.${resultKey} = {
            posixTmpDir: POSIX_NOVA_TMP_DIR,
            resolverType: typeof resolvePreferredNovaTmpDir,
          };
        `,
        loader: "ts",
        resolveDir: process.cwd(),
        sourcefile: "tmp-nova-dir-browser-entry.ts",
      },
      write: false,
    });

    const bundledSource = bundled.outputFiles[0]?.text;
    expect(bundledSource).toContain(resultKey);

    await import(
      `data:text/javascript;base64,${Buffer.from(expectDefined(bundledSource, "bundledSource test invariant")).toString("base64")}`
    );

    try {
      expect((globalThis as Record<string, unknown>)[resultKey]).toEqual({
        posixTmpDir: "/tmp/nova",
        resolverType: "function",
      });
    } finally {
      delete (globalThis as Record<string, unknown>)[resultKey];
    }
  });
});
