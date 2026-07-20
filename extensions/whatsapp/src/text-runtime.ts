// Whatsapp plugin module implements text runtime behavior.
export {
  convertMarkdownTables,
  sanitizeAssistantVisibleText,
  sanitizeAssistantVisibleTextWithProfile,
  stripToolCallXmlTags,
} from "nova/plugin-sdk/text-chunking";
export { normalizeE164, resolveUserPath } from "nova/plugin-sdk/text-utility-runtime";
export {
  assertWebChannel,
  isSelfChatMode,
  jidToE164,
  markdownToWhatsApp,
  resolveEquivalentWhatsAppDirectChatJids,
  resolveJidToE164,
  toWhatsappJid,
  toWhatsappJidWithLid,
  type JidToE164Options,
  type WebChannel,
} from "./targets-runtime.js";
