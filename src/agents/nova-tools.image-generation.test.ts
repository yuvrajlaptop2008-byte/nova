// Verifies image-generation tool registration through the shared generation harness.
import { describeNovaGenerationToolRegistration } from "./nova-tools.generation.test-support.js";

describeNovaGenerationToolRegistration({
  suiteName: "nova tools image generation registration",
  toolName: "image_generate",
  toolLabel: "an image-generation tool",
});
