// Logger browser import tests cover safe import behavior in browser-like runtimes.
import { importFreshModule } from "nova/plugin-sdk/test-fixtures";
import { afterEach, describe, expect, it, vi } from "vitest";

type LoggerModule = typeof import("./logger.js");

const originalGetBuiltinModule = (
  process as NodeJS.Process & { getBuiltinModule?: (id: string) => unknown }
).getBuiltinModule;

async function importBrowserSafeLogger(params?: {
  resolvePreferredNovaTmpDir?: ReturnType<typeof vi.fn>;
}): Promise<{
  module: LoggerModule;
  resolvePreferredNovaTmpDir: ReturnType<typeof vi.fn>;
}> {
  const resolvePreferredNovaTmpDir =
    params?.resolvePreferredNovaTmpDir ??
    vi.fn(() => {
      throw new Error("resolvePreferredNovaTmpDir should not run during browser-safe import");
    });

  vi.doMock("../infra/tmp-nova-dir.js", async () => {
    const actual = await vi.importActual<typeof import("../infra/tmp-nova-dir.js")>(
      "../infra/tmp-nova-dir.js",
    );
    return {
      ...actual,
      resolvePreferredNovaTmpDir,
    };
  });

  Object.defineProperty(process, "getBuiltinModule", {
    configurable: true,
    value: undefined,
  });

  const module = await importFreshModule<LoggerModule>(
    import.meta.url,
    "./logger.js?scope=browser-safe",
  );
  return { module, resolvePreferredNovaTmpDir };
}

describe("logging/logger browser-safe import", () => {
  afterEach(() => {
    vi.doUnmock("../infra/tmp-nova-dir.js");
    Object.defineProperty(process, "getBuiltinModule", {
      configurable: true,
      value: originalGetBuiltinModule,
    });
  });

  it("does not resolve the preferred temp dir at import time when node fs is unavailable", async () => {
    const { module, resolvePreferredNovaTmpDir } = await importBrowserSafeLogger();

    expect(resolvePreferredNovaTmpDir).not.toHaveBeenCalled();
    expect(module.DEFAULT_LOG_DIR).toBe("/tmp/nova");
    expect(module.DEFAULT_LOG_FILE).toBe("/tmp/nova/nova.log");
  });

  it("disables file logging when imported in a browser-like environment", async () => {
    const { module, resolvePreferredNovaTmpDir } = await importBrowserSafeLogger();

    expect(module.getResolvedLoggerSettings()).toStrictEqual({
      level: "silent",
      file: "/tmp/nova/nova.log",
      maxFileBytes: 100 * 1024 * 1024,
    });
    expect(module.isFileLogLevelEnabled("info")).toBe(false);
    expect(module.getLogger().info("browser-safe")).toBeUndefined();
    expect(resolvePreferredNovaTmpDir).not.toHaveBeenCalled();
  });
});
