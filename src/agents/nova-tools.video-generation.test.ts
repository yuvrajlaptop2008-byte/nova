// Verifies video-generation tool registration through the shared generation harness.
import { describeNovaGenerationToolRegistration } from "./nova-tools.generation.test-support.js";

describeNovaGenerationToolRegistration({
  suiteName: "nova tools video generation registration",
  toolName: "video_generate",
  toolLabel: "a video-generation tool",
});
