// Error output tests cover program-level error display and exit messaging.
import { describe, expect, it } from "vitest";
import { formatCliParseErrorOutput } from "./error-output.js";

describe("formatCliParseErrorOutput", () => {
  it("explains unknown commands with root help and plugin hints", () => {
    const output = formatCliParseErrorOutput("error: unknown command 'wat'\n", {
      argv: ["node", "nova", "wat"],
    });

    expect(output).toBe(
      'Nova does not know the command "wat".\nTry: nova --help\nPlugin command? nova plugins list\nDocs: https://docs.nova.ai/cli\n',
    );
  });

  it("suggests close known commands for unknown commands", () => {
    const output = formatCliParseErrorOutput("error: unknown command 'upate'\n", {
      argv: ["node", "nova", "upate"],
    });

    expect(output).toBe(
      'Nova does not know the command "upate".\nDid you mean this?\n  nova update\nTry: nova --help\nPlugin command? nova plugins list\nDocs: https://docs.nova.ai/cli\n',
    );
  });

  it("suggests explicit aliases for common adjacent terminology", () => {
    const output = formatCliParseErrorOutput("error: unknown command 'upgrade'\n", {
      argv: ["node", "nova", "upgrade"],
    });

    expect(output).toContain("Did you mean this?\n  nova update\n");
  });

  it("preserves active profile context in command suggestions", () => {
    const originalProfile = process.env.NOVA_PROFILE;
    process.env.NOVA_PROFILE = "work";
    try {
      const output = formatCliParseErrorOutput("error: unknown command 'doctr'\n", {
        argv: ["node", "nova", "doctr"],
      });

      expect(output).toContain("Did you mean this?\n  nova --profile work doctor\n");
    } finally {
      if (originalProfile === undefined) {
        delete process.env.NOVA_PROFILE;
      } else {
        process.env.NOVA_PROFILE = originalProfile;
      }
    }
  });

  it("points unknown options at the active command help", () => {
    const output = formatCliParseErrorOutput("error: unknown option '--wat'\n", {
      argv: ["node", "nova", "channels", "status", "--wat"],
    });

    expect(output).toBe(
      'Nova does not recognize option "--wat".\nTry: nova channels status --help\n',
    );
  });

  it("points missing required arguments at command help", () => {
    const output = formatCliParseErrorOutput("error: missing required argument 'name'\n", {
      argv: ["node", "nova", "plugins", "install"],
    });

    expect(output).toBe('Missing required argument "name".\nTry: nova plugins install --help\n');
  });
});
