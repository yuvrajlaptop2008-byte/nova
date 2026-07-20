import { describe, expect, it } from "vitest";
import { NovaSchema } from "./zod-schema.js";

describe("NovaSchema cron triggers", () => {
  it("accepts the strict trigger gate", () => {
    expect(NovaSchema.parse({ cron: { triggers: { enabled: true } } }).cron?.triggers).toEqual({
      enabled: true,
    });
  });

  it("rejects invalid and unknown trigger settings", () => {
    expect(
      NovaSchema.safeParse({ cron: { triggers: { enabled: true, extra: true } } }).success,
    ).toBe(false);
  });
});
