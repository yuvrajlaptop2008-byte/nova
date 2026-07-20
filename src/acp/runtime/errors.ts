/** ACP runtime error exports wired to Nova secret redaction. */
import { configureAcpErrorRedactor } from "@nova/acp-core";
import { redactSensitiveText } from "../../logging/redact.js";

// Ensure ACP-core runtime errors use Nova's secret redaction before re-export.
configureAcpErrorRedactor(redactSensitiveText);

export * from "@nova/acp-core/runtime/errors";
