# Filenames

`sanitizeUntrustedFileName(name, fallback)` reduces a filename string from an untrusted source to a single, control-character-free path segment. Use it as a thin first pass before storing user-supplied names; pair with [`safeDirName`](install-path.md#safedirname) when you need stricter directory-name handling.

```ts
import { sanitizeUntrustedFileName } from "@nova/fs-safe";

const safe = sanitizeUntrustedFileName(req.body.fileName, "upload");
await fs.write(`uploads/${safe}`, body);
```

## Signature

```ts
function sanitizeUntrustedFileName(fileName: string, fallbackName: string): string;
```

## What it does

In order:

1. **Trim** whitespace. If the result is empty, return `fallbackName`.
2. **Strip path components.** Apply `path.posix.basename` then `path.win32.basename` so neither `foo/bar.txt` nor `foo\bar.txt` survives — only the final segment remains.
3. **Strip control characters.** Anything below `0x20` (NUL, newlines, tabs, ESC, …) and `0x7f` (DEL) is removed.
4. **Trim again.**
5. If the result is empty, `"."`, or `".."`, return `fallbackName`.
6. **Truncate.** If the cleaned segment is longer than 200 characters, take the first 200.

That's it. The function is intentionally minimal — it gives you a name that won't traverse and won't carry control bytes, without trying to second-guess what your destination filesystem accepts.

## Examples

```ts
sanitizeUntrustedFileName("notes.txt", "untitled"); // "notes.txt"
sanitizeUntrustedFileName("../../etc/passwd", "upload"); // "passwd"
sanitizeUntrustedFileName("foo\\bar.png", "upload"); // "bar.png"
sanitizeUntrustedFileName("a�b	c", "upload"); // "abc"
sanitizeUntrustedFileName("   ", "fallback"); // "fallback"
sanitizeUntrustedFileName(".", "fallback"); // "fallback"
sanitizeUntrustedFileName("..", "fallback"); // "fallback"
sanitizeUntrustedFileName("a".repeat(300), "x"); // 200-char "aaa..."
```

## What it does **not** do

The function is deliberately narrow. It will not:

- Replace special characters like `: * ? " < > |` (Windows-reserved). On Windows-only deployments, do an extra pass yourself.
- Reject Windows reserved names (`CON`, `PRN`, `AUX`, `NUL`, `COM1..9`, `LPT1..9`).
- Replace leading dots (so a name like `.config` stays hidden on POSIX systems).
- Trim trailing dots or spaces (Windows tolerates them silently).
- Add an extension or change case.
- Validate file _content_. To enforce an extension allow-list, check after sanitization.
- Deduplicate against existing files. Append a random suffix if you need uniqueness.

If your domain needs stricter handling, layer it on top:

```ts
const trimmed = sanitizeUntrustedFileName(input, "upload");
const noWindowsReserved = /^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\..+)?$/i.test(trimmed)
  ? "upload"
  : trimmed;
const stripWindowsSpecial = noWindowsReserved.replace(/[<>:"|?*]/g, "_");
```

## Common patterns

### Make a unique filename

```ts
import { sanitizeUntrustedFileName } from "@nova/fs-safe";
import { randomUUID } from "node:crypto";

const base = sanitizeUntrustedFileName(req.body.fileName, "upload");
const unique = `${randomUUID()}-${base}`;
await fs.write(`uploads/${unique}`, body);
```

### Restrict to a known set of extensions

```ts
const safe = sanitizeUntrustedFileName(req.body.fileName, "upload");
const ext = path.extname(safe).toLowerCase();
if (![".png", ".jpg", ".webp"].includes(ext)) return reply(400, "unsupported extension");
```

### Sanitize, then write through a `Root`

```ts
const safe = sanitizeUntrustedFileName(req.body.fileName, "upload");
await fs.write(`uploads/${safe}`, body); // fs is a Root() handle; rejects traversal too
```

## See also

- [Install path helpers](install-path.md) — `safeDirName`, `safePathSegmentHashed` for directory-segment sanitization.
- [`root()`](root.md) — the boundary you'll write into after sanitizing.
