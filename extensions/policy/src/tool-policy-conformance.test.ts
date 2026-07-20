import { describe, expect, it } from "vitest";
import { POLICY_TOOL_GROUPS } from "./tool-policy-conformance.js";

describe("policy tool group conformance", () => {
  it("keeps computer control in both node and Nova policy groups", () => {
    expect(POLICY_TOOL_GROUPS["group:nodes"]).toContain("computer");
    expect(POLICY_TOOL_GROUPS["group:nova"]).toContain("computer");
  });
});
