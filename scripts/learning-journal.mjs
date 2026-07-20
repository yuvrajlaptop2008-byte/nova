// Learning journal: a persistent, confidence-weighted, deduped record of how the
// user actually uses Nova. This is the storage layer behind the `nova-learn` skill.
//
// Design (KISS/DRY):
// - One JSONL file per workspace: <dataDir>/nova-learn/journal.jsonl
// - Each event has a stable `key` (dedupe) + `weight` that grows with repetition.
// - Queries return the highest-value signals so reflection proposes the right skills.
//
// Usage (library):
//   import { LearningJournal } from "./learning-journal.mjs";
//   const j = await LearningJournal.open(dataDir);
//   await j.record({ type: "command", value: "nova skills workshop", note: "ran often" });
//   const top = j.topSignals(10);
//
// Usage (CLI):
//   node learning-journal.mjs record --type command --value "nova skills workshop"
//   node learning-journal.mjs top --limit 10
//   node learning-journal.mjs stats

import fs from "node:fs/promises";
import path from "node:path";

const DEFAULT_DATA_DIR =
  process.env.NOVA_LEARN_DIR || path.join(process.env.HOME || ".", ".nova", "learn");

function keyFor(type, value) {
  return `${type}:${String(value).trim().toLowerCase()}`;
}

function nowIso() {
  return new Date().toISOString();
}

export class LearningJournal {
  constructor(file) {
    this.file = file;
    /** @type {Map<string, object>} */
    this.index = new Map();
  }

  static async open(dataDir = DEFAULT_DATA_DIR) {
    const file = path.join(dataDir, "nova-learn", "journal.jsonl");
    const j = new LearningJournal(file);
    await j.load();
    return j;
  }

  async load() {
    try {
      const raw = await fs.readFile(this.file, "utf8");
      for (const line of raw.split("\n")) {
        const t = line.trim();
        if (!t) continue;
        try {
          const ev = JSON.parse(t);
          this.index.set(ev.key, ev);
        } catch {
          // skip corrupt lines; journal is append-tolerant
        }
      }
    } catch (err) {
      if (err.code !== "ENOENT") throw err;
      // fresh journal
    }
  }

  /**
   * Record a usage signal. Repeats increase weight + bump lastSeen.
   * @returns {{key:string,created:string,lastSeen:string,count:number,weight:number,type:string,value:string,note?:string}}
   */
  async record({ type, value, note }) {
    if (!type || value == null) {
      throw new Error("record requires { type, value }");
    }
    const key = keyFor(type, value);
    const existing = this.index.get(key);
    const ev = existing || {
      key,
      type,
      value: String(value),
      created: nowIso(),
      count: 0,
      weight: 0,
    };
    ev.count += 1;
    // diminishing-returns growth: each repeat adds less, but compounds.
    ev.weight = Math.round((ev.weight + 1 + 1 / (1 + ev.count)) * 100) / 100;
    ev.lastSeen = nowIso();
    if (note) ev.note = note;
    this.index.set(key, ev);
    await this.persist(ev);
    // Return a clone so later mutations of the live index entry do not
    // retroactively change a previously returned snapshot.
    return structuredClone(ev);
  }

  /** Top signals by weight; lets reflection prioritize what the user actually does. */
  topSignals(limit = 10) {
    return [...this.index.values()]
      .sort((a, b) => b.weight - a.weight)
      .slice(0, limit)
      .map((e) => structuredClone(e));
  }

  /** Signals of a given type, highest weight first. */
  byType(type, limit = 10) {
    return this.topSignals(Infinity)
      .filter((e) => e.type === type)
      .slice(0, limit);
  }

  stats() {
    const byType = {};
    let total = 0;
    for (const e of this.index.values()) {
      byType[e.type] = (byType[e.type] || 0) + 1;
      total += e.count;
    }
    return { events: this.index.size, totalObservations: total, byType };
  }

  async persist(ev) {
    await fs.mkdir(path.dirname(this.file), { recursive: true });
    // Append-only keep it simple + crash-safe; rewrite file on prune only.
    await fs.appendFile(this.file, JSON.stringify(ev) + "\n", "utf8");
  }
}

// CLI
async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  const opt = (name) => {
    const i = rest.indexOf(`--${name}`);
    return i >= 0 ? rest[i + 1] : undefined;
  };
  const dataDir = opt("dir") || DEFAULT_DATA_DIR;

  if (cmd === "record") {
    const j = await LearningJournal.open(dataDir);
    const ev = await j.record({
      type: opt("type") || "event",
      value: opt("value") || "",
      note: opt("note"),
    });
    process.stdout.write(JSON.stringify(ev) + "\n");
    return;
  }
  if (cmd === "top") {
    const j = await LearningJournal.open(dataDir);
    process.stdout.write(JSON.stringify(j.topSignals(Number(opt("limit") || 10)), null, 2) + "\n");
    return;
  }
  if (cmd === "stats") {
    const j = await LearningJournal.open(dataDir);
    process.stdout.write(JSON.stringify(j.stats(), null, 2) + "\n");
    return;
  }
  process.stderr.write(
    "usage: learning-journal.mjs <record|top|stats> [--type t] [--value v] [--limit n] [--dir d]\n",
  );
  process.exitCode = 2;
}

// Run CLI only when invoked directly (not when imported as a library).
const isMain = import.meta.url === `file://${process.argv[1]}`;
if (isMain) {
  main().catch((err) => {
    process.stderr.write(`learning-journal error: ${err.message}\n`);
    process.exitCode = 1;
  });
}
