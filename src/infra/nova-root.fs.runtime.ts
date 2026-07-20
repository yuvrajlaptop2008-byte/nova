// Nova root resolution imports fs through this facade so tests can replace
// filesystem behavior without mocking node:fs globally.
export { default as novaRootFsSync } from "node:fs";
export { default as novaRootFs } from "node:fs/promises";
