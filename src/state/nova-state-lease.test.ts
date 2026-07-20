import { afterEach, describe, expect, it } from "vitest";
import { executeSqliteQuerySync, getNodeSqliteKysely } from "../infra/kysely-sync.js";
import { withNovaTestState } from "../test-utils/nova-test-state.js";
import { closeNovaAgentDatabasesForTest } from "./nova-agent-db.js";
import type { DB as NovaStateKyselyDatabase } from "./nova-state-db.generated.js";
import { closeNovaStateDatabaseForTest, runNovaStateWriteTransaction } from "./nova-state-db.js";
import { withNovaStateLease } from "./nova-state-lease.js";

type LeaseDatabase = Pick<NovaStateKyselyDatabase, "state_leases">;

afterEach(() => {
  closeNovaAgentDatabasesForTest();
  closeNovaStateDatabaseForTest();
});

describe("Nova state lease", () => {
  it("rechecks exact ownership inside the caller's write transaction", async () => {
    await withNovaTestState({ label: "core-state-lease" }, async () => {
      await expect(
        withNovaStateLease(
          {
            scope: "core:test",
            key: "credential-write",
            database: { scope: "shared" },
            leaseMs: 1_000,
            waitMs: 0,
          },
          async (lease) => {
            runNovaStateWriteTransaction(({ db }) => {
              lease.assertOwnedInTransaction(db);
              executeSqliteQuerySync(
                db,
                getNodeSqliteKysely<LeaseDatabase>(db)
                  .updateTable("state_leases")
                  .set({ owner: "successor" })
                  .where("scope", "=", "core:test")
                  .where("lease_key", "=", "credential-write"),
              );
              expect(() => lease.assertOwnedInTransaction(db)).toThrowError(
                expect.objectContaining({ code: "NOVA_STATE_LEASE_LOST" }),
              );
            });
          },
        ),
      ).rejects.toMatchObject({ code: "NOVA_STATE_LEASE_LOST" });
    });
  });
});
