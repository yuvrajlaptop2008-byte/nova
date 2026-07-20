// QR terminal tests cover text normalization and terminal render calls.
import { beforeEach, describe, expect, it, vi } from "vitest";

const { create, toString } = vi.hoisted(() => ({
  create: vi.fn(() => ({
    modules: {
      data: [1, 0, 0, 1],
      size: 2,
    },
  })),
  toString: vi.fn(async () => "ASCII-QR"),
}));

vi.mock("qrcode", () => ({
  default: {
    create,
    toString,
  },
}));

import { renderQrTerminal } from "./qr-terminal.ts";

describe("renderQrTerminal", () => {
  beforeEach(() => {
    create.mockClear();
    toString.mockClear();
  });

  it("delegates terminal rendering to qrcode", async () => {
    await expect(renderQrTerminal("nova")).resolves.toBe("ASCII-QR");
    expect(toString).toHaveBeenCalledWith("nova", {
      small: false,
      type: "terminal",
    });
  });

  it("renders compact QR output without qrcode terminal small mode", async () => {
    const rendered = await renderQrTerminal("nova", { small: true });
    expect(rendered).toContain("▄");
    expect(create).toHaveBeenCalledWith("nova");
    expect(toString).not.toHaveBeenCalled();
  });
});
