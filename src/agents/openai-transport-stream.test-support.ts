import "./openai-completions-transport.js";
import "./openai-responses-transport.js";

const completionsTesting = globalThis.novaOpenAICompletionsTransportTestApi;
const responsesTesting = globalThis.novaOpenAIResponsesTransportTestApi;
if (!completionsTesting || !responsesTesting) {
  throw new Error("OpenAI transport test APIs are unavailable outside test mode");
}

export const testing = {
  ...responsesTesting,
  ...completionsTesting,
};
