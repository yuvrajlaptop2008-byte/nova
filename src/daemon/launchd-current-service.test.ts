// Launchd current service tests cover resolving active macOS service labels.
import { describe, expect, it } from "vitest";
import { isCurrentProcessLaunchdServiceLabel } from "./launchd-current-service.js";

describe("isCurrentProcessLaunchdServiceLabel", () => {
  it("matches launchd-provided service labels", () => {
    expect(
      isCurrentProcessLaunchdServiceLabel("ai.nova.gateway", {
        LAUNCH_JOB_LABEL: "ai.nova.gateway",
      }),
    ).toBe(true);
  });

  it("falls back to Nova service markers when XPC_SERVICE_NAME is inherited", () => {
    expect(
      isCurrentProcessLaunchdServiceLabel("ai.nova.gateway", {
        XPC_SERVICE_NAME: "0",
        NOVA_SERVICE_MARKER: "nova",
        NOVA_SERVICE_KIND: "gateway",
        NOVA_LAUNCHD_LABEL: "ai.nova.gateway",
      }),
    ).toBe(true);
  });

  it("preserves label-only fallback when launchd exposes no label variables", () => {
    expect(
      isCurrentProcessLaunchdServiceLabel("ai.nova.gateway", {
        NOVA_LAUNCHD_LABEL: "ai.nova.gateway",
      }),
    ).toBe(true);
  });

  it("can require service markers for label-only fallback", () => {
    expect(
      isCurrentProcessLaunchdServiceLabel(
        "ai.nova.gateway",
        {
          NOVA_LAUNCHD_LABEL: "ai.nova.gateway",
        },
        { allowConfiguredLabelFallback: false },
      ),
    ).toBe(false);
  });

  it("does not treat unrelated inherited launchd labels as current services", () => {
    expect(
      isCurrentProcessLaunchdServiceLabel("ai.nova.gateway", {
        XPC_SERVICE_NAME: "0",
        NOVA_LAUNCHD_LABEL: "ai.nova.gateway",
      }),
    ).toBe(false);
  });
});
