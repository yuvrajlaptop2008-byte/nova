// Failure output tests cover CLI error formatting and failure summaries.
import { describe, expect, it } from "vitest";
import { formatCliFailureLines } from "./failure-output.js";

describe("formatCliFailureLines", () => {
  it("shows a concise reason and recovery commands by default", () => {
    const lines = formatCliFailureLines({
      title: "Could not start the CLI.",
      error: new Error("config file is invalid"),
      argv: ["node", "nova", "status"],
      env: {},
    });

    expect(lines).toEqual([
      "[nova] Could not start the CLI.",
      "[nova] Reason: config file is invalid",
      "[nova] Debug: set NOVA_DEBUG=1 to include the stack trace.",
      "[nova] Try: nova doctor",
      "[nova] Help: nova --help",
    ]);
  });

  it("prints stack details when debug output is requested", () => {
    const lines = formatCliFailureLines({
      title: "The CLI command failed.",
      error: new Error("boom"),
      env: { NOVA_DEBUG: "1" },
    });

    expect(lines.slice(0, 4)).toEqual([
      "[nova] The CLI command failed.",
      "[nova] Reason: boom",
      "[nova] Stack:",
      "[nova] Error: boom",
    ]);
    expect(lines.join("\n")).toContain("Error: boom");
  });
});
