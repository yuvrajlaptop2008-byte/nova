// Text format tests cover command-facing shortening helpers.
import { describe, expect, it } from "vitest";
import { shortenText } from "./text-format.js";

describe("shortenText", () => {
  it("returns original text when it fits", () => {
    expect(shortenText("nova", 16)).toBe("nova");
  });

  it("truncates and appends ellipsis when over limit", () => {
    expect(shortenText("nova-status-output", 10)).toBe("nova-…");
  });

  it("returns an empty string for non-positive limits", () => {
    expect(shortenText("nova", 0)).toBe("");
    expect(shortenText("nova", -1)).toBe("");
  });

  it("counts multi-byte characters correctly", () => {
    expect(shortenText("hello🙂world", 7)).toBe("hello🙂…");
  });
});
