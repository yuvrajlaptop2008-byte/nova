// Exposes regular-file IO helpers with fs-safe defaults.
import "./fs-safe-defaults.js";

// Regular-file IO helpers reject symlinks and non-file targets before reads or
// appends touch user-controlled paths.
export {
  appendRegularFileSync,
  readRegularFile,
  readRegularFileSync,
} from "@nova/fs-safe/advanced";
