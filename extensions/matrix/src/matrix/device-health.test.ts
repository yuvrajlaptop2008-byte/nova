// Matrix tests cover device health plugin behavior.
import { describe, expect, it } from "vitest";
import { isNovaManagedMatrixDevice, summarizeMatrixDeviceHealth } from "./device-health.js";

describe("matrix device health", () => {
  it("detects Nova-managed device names", () => {
    expect(isNovaManagedMatrixDevice("Nova Gateway")).toBe(true);
    expect(isNovaManagedMatrixDevice("Nova Debug")).toBe(true);
    expect(isNovaManagedMatrixDevice("Element iPhone")).toBe(false);
    expect(isNovaManagedMatrixDevice(null)).toBe(false);
  });

  it("summarizes stale Nova-managed devices separately from the current device", () => {
    const summary = summarizeMatrixDeviceHealth([
      {
        deviceId: "du314Zpw3A",
        displayName: "Nova Gateway",
        current: true,
      },
      {
        deviceId: "BritdXC6iL",
        displayName: "Nova Gateway",
        current: false,
      },
      {
        deviceId: "G6NJU9cTgs",
        displayName: "Nova Debug",
        current: false,
      },
      {
        deviceId: "phone123",
        displayName: "Element iPhone",
        current: false,
      },
    ]);

    expect(summary).toEqual({
      currentDeviceId: "du314Zpw3A",
      currentNovaDevices: [
        {
          deviceId: "du314Zpw3A",
          displayName: "Nova Gateway",
          current: true,
        },
      ],
      staleNovaDevices: [
        {
          deviceId: "BritdXC6iL",
          displayName: "Nova Gateway",
          current: false,
        },
        {
          deviceId: "G6NJU9cTgs",
          displayName: "Nova Debug",
          current: false,
        },
      ],
    });
  });
});
