// Focused runtime contract for memory CLI/UI helpers.

export { formatErrorMessage, withManager } from "./host/nova-runtime-cli.js";
export { formatHelpExamples } from "./host/nova-runtime-cli.js";
export { resolveCommandSecretRefsViaGateway } from "./host/nova-runtime-cli.js";
export { withProgress, withProgressTotals } from "./host/nova-runtime-cli.js";
export { defaultRuntime } from "./host/nova-runtime-cli.js";
export { formatDocsLink } from "./host/nova-runtime-cli.js";
export { colorize, isRich, theme } from "./host/nova-runtime-cli.js";
export { isVerbose, setVerbose } from "./host/nova-runtime-cli.js";
export { shortenHomeInString, shortenHomePath } from "./host/nova-runtime-cli.js";
