import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { LearningJournal } from "../../scripts/learning-journal.mjs";

let dir;
beforeEach(async () => {
  dir = await fs.mkdtemp(path.join(os.tmpdir(), "nova-learn-"));
});
afterEach(async () => {
  await fs.rm(dir, { recursive: true, force: true });
});

describe("LearningJournal", () => {
  it("records an event and persists it", async () => {
    const j = await LearningJournal.open(dir);
    const ev = await j.record({ type: "command", value: "nova skills workshop" });
    expect(ev.count).toBe(1);
    expect(ev.weight).toBeGreaterThan(0);
    expect(ev.key).toBe("command:nova skills workshop");
  });

  it("dedupes by key and grows weight on repeat", async () => {
    const j = await LearningJournal.open(dir);
    await j.record({ type: "command", value: "git status" });
    const a = await j.record({ type: "command", value: "git status" });
    const b = await j.record({ type: "command", value: "git status" });
    expect(a.count).toBe(2);
    expect(b.count).toBe(3);
    // weight grows but with diminishing returns
    expect(b.weight).toBeGreaterThan(a.weight);
    // only one stored key for the repeated command
    expect(j.stats().events).toBe(1);
  });

  it("survives reload from disk (append-only JSONL)", async () => {
    const j1 = await LearningJournal.open(dir);
    await j1.record({ type: "correction", value: "use pnpm not npm" });
    await j1.record({ type: "command", value: "nova run" });

    const j2 = await LearningJournal.open(dir);
    expect(j2.stats().events).toBe(2);
    expect(j2.byType("correction").length).toBe(1);
  });

  it("ranks top signals by weight so reflection prioritizes real usage", async () => {
    const j = await LearningJournal.open(dir);
    // rarely used
    await j.record({ type: "command", value: "obscure-cmd" });
    // used a lot
    for (let i = 0; i < 5; i++) await j.record({ type: "command", value: "frequent-cmd" });
    const top = j.topSignals(1);
    expect(top[0].value).toBe("frequent-cmd");
    expect(top[0].weight).toBeGreaterThan(1);
  });

  it("rejects records without type or value", async () => {
    const j = await LearningJournal.open(dir);
    await expect(j.record({ type: "x" })).rejects.toThrow();
  });
});
