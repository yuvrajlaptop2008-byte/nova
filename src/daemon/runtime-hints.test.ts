// Daemon runtime hint tests cover platform-specific daemon guidance.
import { describe, expect, it } from "vitest";
import { buildPlatformRuntimeLogHints, buildPlatformServiceStartHints } from "./runtime-hints.js";

describe("buildPlatformRuntimeLogHints", () => {
  it("renders launchd log hints on darwin", () => {
    expect(
      buildPlatformRuntimeLogHints({
        platform: "darwin",
        env: {
          HOME: "/Users/test",
          NOVA_STATE_DIR: "/tmp/nova-state",
          NOVA_LOG_PREFIX: "gateway",
        },
        systemdServiceName: "nova-gateway",
        windowsTaskName: "Nova Gateway",
      }),
    ).toEqual([
      "Launchd stdout (if installed): /Users/test/Library/Logs/nova/gateway.log",
      "Launchd stderr (if installed): suppressed",
      "Restart attempts: /tmp/nova-state/logs/gateway-restart.log",
    ]);
  });

  it("renders systemd and windows hints by platform", () => {
    expect(
      buildPlatformRuntimeLogHints({
        platform: "linux",
        env: {
          NOVA_STATE_DIR: "/tmp/nova-state",
        },
        systemdServiceName: "nova-gateway",
        windowsTaskName: "Nova Gateway",
      }),
    ).toEqual([
      "Logs: journalctl --user -u nova-gateway.service -n 200 --no-pager",
      "Restart attempts: /tmp/nova-state/logs/gateway-restart.log",
    ]);
    expect(
      buildPlatformRuntimeLogHints({
        platform: "win32",
        env: {
          NOVA_STATE_DIR: "/tmp/nova-state",
        },
        systemdServiceName: "nova-gateway",
        windowsTaskName: "Nova Gateway",
      }),
    ).toEqual([
      'Logs: schtasks /Query /TN "Nova Gateway" /V /FO LIST',
      "Restart attempts: /tmp/nova-state/logs/gateway-restart.log",
    ]);
  });
});

describe("buildPlatformServiceStartHints", () => {
  it("builds platform-specific service start hints", () => {
    expect(
      buildPlatformServiceStartHints({
        platform: "darwin",
        installCommand: "nova gateway install",
        startCommand: "nova gateway",
        launchAgentPlistPath: "~/Library/LaunchAgents/com.nova.gateway.plist",
        systemdServiceName: "nova-gateway",
        windowsTaskName: "Nova Gateway",
      }),
    ).toEqual([
      "nova gateway install",
      "nova gateway",
      "launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.nova.gateway.plist",
    ]);
    expect(
      buildPlatformServiceStartHints({
        platform: "linux",
        installCommand: "nova gateway install",
        startCommand: "nova gateway",
        launchAgentPlistPath: "~/Library/LaunchAgents/com.nova.gateway.plist",
        systemdServiceName: "nova-gateway",
        windowsTaskName: "Nova Gateway",
      }),
    ).toEqual([
      "nova gateway install",
      "nova gateway",
      "systemctl --user start nova-gateway.service",
    ]);
  });
});
