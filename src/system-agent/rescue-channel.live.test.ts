// Nova live rescue channel tests cover live-channel rescue message delivery.
import fs from "node:fs/promises";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import type { CommandContext } from "../auto-reply/reply/commands-types.js";
import { clearConfigCache } from "../config/config.js";
import type { NovaConfig } from "../config/types.nova.js";
import { resetPluginStateStoreForTests } from "../plugin-state/plugin-state-store.js";
import { withTempDir } from "../test-helpers/temp-dir.js";
import { deleteTestEnvValue, setTestEnvValue } from "../test-utils/env.js";
import { listSystemAgentAuditEntriesForTests } from "./audit.test-support.js";
import { runSystemAgentRescueMessage } from "./rescue-message.js";

const originalStateDir = process.env.NOVA_STATE_DIR;
const originalConfigPath = process.env.NOVA_CONFIG_PATH;

function truthy(value: string | undefined): boolean {
  return /^(1|true|yes|on)$/i.test(value?.trim() ?? "");
}

const runLive =
  truthy(process.env.NOVA_LIVE_TEST) && truthy(process.env.NOVA_LIVE_SYSTEM_AGENT_RESCUE_CHANNEL);
const describeLive = runLive ? describe : describe.skip;

function commandContext(channel = process.env.NOVA_LIVE_SYSTEM_AGENT_CHANNEL ?? "whatsapp") {
  return {
    surface: channel,
    channel,
    channelId: channel,
    ownerList: ["user:owner"],
    senderIsOwner: true,
    isAuthorizedSender: true,
    senderId: "user:owner",
    rawBodyNormalized: "/nova status",
    commandBodyNormalized: "/nova status",
    from: "user:owner",
    to: "account:default",
  } satisfies CommandContext;
}

async function runRescue(params: { commandBody: string; cfg: NovaConfig; ctx?: CommandContext }) {
  const ctx = params.ctx ?? commandContext();
  return await runSystemAgentRescueMessage({
    cfg: params.cfg,
    command: { ...ctx, commandBodyNormalized: params.commandBody },
    commandBody: params.commandBody,
    isGroup: false,
  });
}

describeLive("Nova live rescue channel smoke", () => {
  afterEach(() => {
    resetPluginStateStoreForTests();
    clearConfigCache();
    if (originalStateDir === undefined) {
      deleteTestEnvValue("NOVA_STATE_DIR");
    } else {
      setTestEnvValue("NOVA_STATE_DIR", originalStateDir);
    }
    if (originalConfigPath === undefined) {
      deleteTestEnvValue("NOVA_CONFIG_PATH");
    } else {
      setTestEnvValue("NOVA_CONFIG_PATH", originalConfigPath);
    }
  });

  it("handles /nova status and a persistent approval roundtrip", async () => {
    await withTempDir({ prefix: "nova-live-rescue-" }, async (tempDir) => {
      const configPath = path.join(tempDir, "nova.json");
      setTestEnvValue("NOVA_STATE_DIR", tempDir);
      setTestEnvValue("NOVA_CONFIG_PATH", configPath);
      await fs.writeFile(
        configPath,
        JSON.stringify(
          {
            meta: { lastTouchedVersion: "live-test", lastTouchedAt: new Date(0).toISOString() },
            agents: { defaults: {} },
            tools: { exec: { security: "full", ask: "off" } },
          },
          null,
          2,
        ),
      );

      const cfg: NovaConfig = {
        systemAgent: { rescue: { enabled: true } },
        tools: { exec: { security: "full", ask: "off" } },
      };

      await expect(runRescue({ commandBody: "/nova status", cfg })).resolves.toContain(
        "[nova] done: status.check",
      );
      await expect(
        runRescue({ commandBody: "/nova set default model openai/gpt-5.5", cfg }),
      ).resolves.toContain("Reply /nova yes to apply");
      await expect(runRescue({ commandBody: "/nova yes", cfg })).resolves.toContain(
        "Default model: openai/gpt-5.5",
      );

      const config = JSON.parse(await fs.readFile(configPath, "utf8")) as NovaConfig;
      const defaultModel = config.agents?.defaults?.model;
      if (!defaultModel || typeof defaultModel !== "object") {
        throw new Error("expected default model object");
      }
      expect(defaultModel.primary).toBe("openai/gpt-5.5");
      expect(
        listSystemAgentAuditEntriesForTests().some(
          (entry) => entry.value.operation === "config.setDefaultModel",
        ),
      ).toBe(true);
    });
  });
});
