// STT live audio tests validate live speech-to-text audio fixtures.
import {
  expectNovaLiveTranscriptMarker,
  normalizeTranscriptForMatch,
  NOVA_LIVE_TRANSCRIPT_MARKER_RE,
} from "nova/plugin-sdk/provider-test-contracts";
import { describe, expect, it } from "vitest";

describe("normalizeTranscriptForMatch", () => {
  it("normalizes punctuation and common Nova live transcription variants", () => {
    expect(normalizeTranscriptForMatch("Open-Claw integration OK")).toBe("novaintegrationok");
    expect(normalizeTranscriptForMatch("Testing OpenFlaw realtime transcription")).toMatch(
      /open(?:claw|flaw)/,
    );
    expect(normalizeTranscriptForMatch("OpenCore xAI realtime transcription")).toMatch(
      NOVA_LIVE_TRANSCRIPT_MARKER_RE,
    );
    expect(normalizeTranscriptForMatch("OpenCL xAI realtime transcription")).toMatch(
      NOVA_LIVE_TRANSCRIPT_MARKER_RE,
    );
    expectNovaLiveTranscriptMarker("OpenClar integration OK");
  });
});
