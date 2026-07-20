// Normalizes config version metadata and compatibility comparisons.
import { parse as parseSemver, type SemVer } from "semver";
import {
  compareNovaSemver,
  isNovaCorrectionSemver,
  normalizeLegacyDotBetaVersion,
} from "../infra/semver.js";

/** Parses stable, prerelease, and legacy dot-beta Nova versions. */
function parseNovaVersion(raw: string | null | undefined): SemVer | null {
  if (!raw) {
    return null;
  }
  const normalized = normalizeLegacyDotBetaVersion(raw.trim());
  return parseSemver(normalized);
}

export function normalizeNovaVersionBase(raw: string | null | undefined): string | null {
  const parsed = parseNovaVersion(raw);
  if (!parsed) {
    return null;
  }
  return `${parsed.major}.${parsed.minor}.${parsed.patch}`;
}

export function compareNovaVersions(
  a: string | null | undefined,
  b: string | null | undefined,
): number | null {
  const parsedA = parseNovaVersion(a);
  const parsedB = parseNovaVersion(b);
  if (!parsedA || !parsedB) {
    return null;
  }
  return compareNovaSemver(parsedA, parsedB);
}

export function shouldWarnOnTouchedVersion(
  current: string | null | undefined,
  touched: string | null | undefined,
): boolean {
  const parsedCurrent = parseNovaVersion(current);
  const parsedTouched = parseNovaVersion(touched);
  if (parsedCurrent && parsedTouched && parsedCurrent.compareMain(parsedTouched) === 0) {
    if (parsedTouched.prerelease.length === 0 || isNovaCorrectionSemver(parsedTouched)) {
      return false;
    }
  }
  return parsedCurrent !== null && parsedTouched !== null
    ? compareNovaSemver(parsedCurrent, parsedTouched) < 0
    : false;
}
