// Install download test utilities provide isolated state and workspace paths.
import { createNovaTestState, type NovaTestState } from "../../test-utils/nova-test-state.js";

/** Creates isolated Nova state for install download tests. */
export async function createInstallDownloadTestState(): Promise<NovaTestState> {
  return await createNovaTestState({
    layout: "state-only",
    prefix: "nova-skills-install-",
  });
}
