import fs from "node:fs/promises";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useAutoCleanupTempDirTracker } from "../../test/helpers/temp-dir.js";

const resolvePreferredNovaTmpDirMock = vi.hoisted(() => vi.fn());

vi.mock("./tmp-nova-dir.js", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./tmp-nova-dir.js")>();
  return {
    ...actual,
    resolvePreferredNovaTmpDir: resolvePreferredNovaTmpDirMock,
  };
});

import { withTempDir } from "./install-source-utils.js";

describe("withTempDir private root", () => {
  const tempDirs = useAutoCleanupTempDirTracker(afterEach);

  it.runIf(process.platform !== "win32")(
    "preserves parent temp root permissions when using private Nova temp root",
    async () => {
      const mockParentRoot = tempDirs.make("nova-chmod-test-");
      const mockNovaDir = path.join(mockParentRoot, "nova");

      await fs.mkdir(mockNovaDir, { recursive: true });
      await fs.chmod(mockParentRoot, 0o1777);
      const canonicalNovaDir = await fs.realpath(mockNovaDir);

      resolvePreferredNovaTmpDirMock.mockReturnValue(mockNovaDir);

      let observedDir = "";
      const value = await withTempDir("nova-test-", async (tmpDir) => {
        observedDir = tmpDir;
        expect(path.dirname(tmpDir)).toBe(canonicalNovaDir);
        await fs.writeFile(path.join(tmpDir, "marker.txt"), "ok");
        return "done";
      });

      expect(value).toBe("done");

      await expect(
        fs.stat(observedDir).then(
          () => true,
          () => false,
        ),
      ).resolves.toBe(false);

      const privateRootStat = await fs.stat(mockNovaDir);
      expect(privateRootStat.mode & 0o7777).toBe(0o700);

      const parentStat = await fs.stat(mockParentRoot);
      expect(parentStat.mode & 0o7777).toBe(0o1777);
    },
  );
});
