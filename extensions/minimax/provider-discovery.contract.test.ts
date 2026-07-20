// Minimax tests cover provider discovery.contract plugin behavior.
import { describeMinimaxProviderDiscoveryContract } from "nova/plugin-sdk/provider-test-contracts";

describeMinimaxProviderDiscoveryContract(() => import("./index.js"));
