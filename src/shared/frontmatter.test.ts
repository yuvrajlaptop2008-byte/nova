// Frontmatter tests cover shared Markdown frontmatter parsing helpers.
import { describe, expect, it, test } from "vitest";
import {
  applyNovaManifestInstallCommonFields,
  getFrontmatterString,
  normalizeStringList,
  parseFrontmatterBool,
  parseNovaManifestInstallBase,
  resolveNovaManifestBlock,
  resolveNovaManifestInstall,
  resolveNovaManifestOs,
  resolveNovaManifestRequires,
} from "./frontmatter.js";

function expectInstallBase(
  parsed: ReturnType<typeof parseNovaManifestInstallBase>,
): NonNullable<ReturnType<typeof parseNovaManifestInstallBase>> {
  if (parsed === undefined) {
    throw new Error("Expected manifest install base");
  }
  return parsed;
}

describe("shared/frontmatter", () => {
  test("normalizeStringList handles strings, arrays, and non-list values", () => {
    expect(normalizeStringList("a, b,,c")).toEqual(["a", "b", "c"]);
    expect(normalizeStringList([" a ", "", "b", 42])).toEqual(["a", "b", "42"]);
    expect(normalizeStringList(null)).toStrictEqual([]);
  });

  test("getFrontmatterString extracts strings only", () => {
    expect(getFrontmatterString({ a: "b" }, "a")).toBe("b");
    expect(getFrontmatterString({ a: 1 }, "a")).toBeUndefined();
  });

  test("parseFrontmatterBool respects explicit values and fallback", () => {
    expect(parseFrontmatterBool("true", false)).toBe(true);
    expect(parseFrontmatterBool("false", true)).toBe(false);
    expect(parseFrontmatterBool(undefined, true)).toBe(true);
    expect(parseFrontmatterBool("maybe", false)).toBe(false);
  });

  test("resolveNovaManifestBlock reads current manifest keys and custom metadata fields", () => {
    expect(
      resolveNovaManifestBlock({
        frontmatter: {
          metadata: "{ nova: { foo: 1, bar: 'baz' } }",
        },
      }),
    ).toEqual({ foo: 1, bar: "baz" });

    expect(
      resolveNovaManifestBlock({
        frontmatter: {
          pluginMeta: "{ nova: { foo: 2 } }",
        },
        key: "pluginMeta",
      }),
    ).toEqual({ foo: 2 });
  });

  test("resolveNovaManifestBlock reads legacy manifest keys", () => {
    expect(
      resolveNovaManifestBlock({
        frontmatter: {
          metadata: "{ clawdbot: { requires: { bins: ['op'] }, install: [] } }",
        },
      }),
    ).toEqual({ requires: { bins: ["op"] }, install: [] });
  });

  test("resolveNovaManifestBlock prefers current manifest keys over legacy keys", () => {
    expect(
      resolveNovaManifestBlock({
        frontmatter: {
          metadata:
            "{ nova: { requires: { bins: ['current'] } }, clawdbot: { requires: { bins: ['legacy'] } } }",
        },
      }),
    ).toEqual({ requires: { bins: ["current"] } });
  });

  test("resolveNovaManifestBlock returns undefined for invalid input", () => {
    expect(resolveNovaManifestBlock({ frontmatter: {} })).toBeUndefined();
    expect(resolveNovaManifestBlock({ frontmatter: { metadata: "not-json5" } })).toBeUndefined();
    expect(resolveNovaManifestBlock({ frontmatter: { metadata: "123" } })).toBeUndefined();
    expect(resolveNovaManifestBlock({ frontmatter: { metadata: "[]" } })).toBeUndefined();
    expect(
      resolveNovaManifestBlock({ frontmatter: { metadata: "{ nope: { a: 1 } }" } }),
    ).toBeUndefined();
  });

  it("normalizes manifest requirement and os lists", () => {
    expect(
      resolveNovaManifestRequires({
        requires: {
          bins: "bun, node",
          anyBins: [" ffmpeg ", ""],
          env: ["NOVA_TOKEN", " NOVA_URL "],
          config: null,
        },
      }),
    ).toEqual({
      bins: ["bun", "node"],
      anyBins: ["ffmpeg"],
      env: ["NOVA_TOKEN", "NOVA_URL"],
      config: [],
    });
    expect(resolveNovaManifestRequires({})).toBeUndefined();
    expect(resolveNovaManifestOs({ os: [" darwin ", "linux", ""] })).toEqual(["darwin", "linux"]);
  });

  it("parses and applies install common fields", () => {
    const parsed = parseNovaManifestInstallBase(
      {
        type: " Brew ",
        id: "brew.git",
        label: "Git",
        bins: [" git ", "git"],
      },
      ["brew", "npm"],
    );

    expect(parsed).toEqual({
      raw: {
        type: " Brew ",
        id: "brew.git",
        label: "Git",
        bins: [" git ", "git"],
      },
      kind: "brew",
      id: "brew.git",
      label: "Git",
      bins: ["git", "git"],
    });
    expect(parseNovaManifestInstallBase({ kind: "bad" }, ["brew"])).toBeUndefined();
    expect(
      applyNovaManifestInstallCommonFields<{
        extra: boolean;
        id?: string;
        label?: string;
        bins?: string[];
      }>({ extra: true }, expectInstallBase(parsed)),
    ).toEqual({
      extra: true,
      id: "brew.git",
      label: "Git",
      bins: ["git", "git"],
    });
  });

  it("prefers explicit kind, ignores invalid common fields, and leaves missing ones untouched", () => {
    const parsed = parseNovaManifestInstallBase(
      {
        kind: " npm ",
        type: "brew",
        id: 42,
        label: null,
        bins: [" ", ""],
      },
      ["brew", "npm"],
    );

    expect(parsed).toEqual({
      raw: {
        kind: " npm ",
        type: "brew",
        id: 42,
        label: null,
        bins: [" ", ""],
      },
      kind: "npm",
    });
    expect(
      applyNovaManifestInstallCommonFields({ id: "keep", label: "Keep", bins: ["bun"] }, parsed!),
    ).toEqual({
      id: "keep",
      label: "Keep",
      bins: ["bun"],
    });
  });

  it("maps install entries through the parser and filters rejected specs", () => {
    expect(
      resolveNovaManifestInstall(
        {
          install: [{ id: "keep" }, { id: "drop" }, "bad"],
        },
        (entry) => {
          if (
            typeof entry === "object" &&
            entry !== null &&
            (entry as { id?: string }).id === "keep"
          ) {
            return { id: "keep" };
          }
          return undefined;
        },
      ),
    ).toEqual([{ id: "keep" }]);
  });
});
