import { pluginRegistrationContractCases } from "nova/plugin-sdk/plugin-test-contracts";
import { describePluginRegistrationContract } from "nova/plugin-sdk/plugin-test-contracts";

describePluginRegistrationContract(pluginRegistrationContractCases.parallel);
