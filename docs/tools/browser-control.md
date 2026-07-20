---
summary: "Nova browser control API, CLI reference, and scripting actions"
read_when:
  - Scripting or debugging the agent browser via the local control API
  - Looking for the `nova browser` CLI reference
  - Adding custom browser automation with snapshots and refs
title: "Browser control API"
---

For setup, configuration, and troubleshooting, see [Browser](/tools/browser).
This page is the reference for the local control HTTP API, the `nova browser`
CLI, and scripting patterns (snapshots, refs, waits, debug flows).

## Control API (optional)

For local integrations only, the Gateway exposes a small loopback HTTP API.
This standalone server is opt-in — set the environment variable
`NOVA_EAGER_BROWSER_CONTROL_SERVER=1` in the gateway service environment
and restart the gateway before the HTTP endpoints become available. Without
this variable the browser control runtime still works through the CLI and
agent tools, but nothing listens on the loopback control port.

- Status/start/stop: `GET /`, `GET /doctor`, `POST /start`, `POST /stop`, `POST /reset-profile`
- Profiles: `GET /profiles`, `POST /profiles/create`, `DELETE /profiles/:name`
- Tabs: `GET /tabs`, `POST /tabs/open`, `POST /tabs/focus`, `DELETE /tabs/:targetId`, `POST /tabs/action`
- Snapshot/screenshot: `GET /snapshot`, `POST /screenshot`
- Actions: `POST /navigate`, `POST /act`
- Hooks: `POST /hooks/file-chooser`, `POST /hooks/dialog`
- Downloads: `POST /download`, `POST /wait/download`
- Permissions: `POST /permissions/grant`
- Debugging: `GET /console`, `POST /pdf`
- Debugging: `GET /errors`, `GET /requests`, `GET /dialogs`, `POST /trace/start`, `POST /trace/stop`, `POST /highlight`
- Network: `POST /response/body`
- State: `GET /cookies`, `POST /cookies/set`, `POST /cookies/clear`
- State: `GET /storage/:kind`, `POST /storage/:kind/set`, `POST /storage/:kind/clear`
- Settings: `POST /set/offline`, `POST /set/headers`, `POST /set/credentials`, `POST /set/geolocation`, `POST /set/media`, `POST /set/timezone`, `POST /set/locale`, `POST /set/device`

`POST /tabs/action` is the batched form the CLI uses internally for
`browser tab` subcommands (`{"action":"new"|"label"|"select"|"close"|"list", ...}`);
prefer the single-purpose tab routes above when scripting directly.

All endpoints accept `?profile=<name>`. `POST /start?headless=true` requests a
one-shot headless launch for local managed profiles without changing persisted
browser config; attach-only, remote CDP, and existing-session profiles reject
that override because Nova does not launch those browser processes.

For tab endpoints, `targetId` is the compatibility field name. Prefer passing
`suggestedTargetId` from `GET /tabs` or `POST /tabs/open`; labels and `tabId`
handles such as `t1` are also accepted. Raw CDP target ids and unique raw
target-id prefixes still work, but they are volatile diagnostic handles.

If shared-secret gateway auth is configured, browser HTTP routes require auth too:

- `Authorization: Bearer <gateway token>`
- `x-nova-password: <gateway password>` or HTTP Basic auth with that password

Notes:

- This standalone loopback browser API does **not** consume trusted-proxy or
  Tailscale Serve identity headers.
- If `gateway.auth.mode` is `none` or `trusted-proxy`, these loopback browser
  routes do not inherit those identity-bearing modes; keep them loopback-only.

### `/act` error contract

`POST /act` uses a structured error response for route-level validation and
policy failures:

```json
{ "error": "<message>", "code": "ACT_*" }
```

Current `code` values:

- `ACT_KIND_REQUIRED` (HTTP 400): `kind` is missing or unrecognized.
- `ACT_INVALID_REQUEST` (HTTP 400): action payload failed normalization or validation.
- `ACT_SELECTOR_UNSUPPORTED` (HTTP 400): `selector` was used with an unsupported action kind.
- `ACT_EVALUATE_DISABLED` (HTTP 403): `evaluate` (or `wait --fn`) is disabled by config.
- `ACT_TARGET_ID_MISMATCH` (HTTP 403): top-level or batched `targetId` conflicts with request target.
- `ACT_EXISTING_SESSION_UNSUPPORTED` (HTTP 501): action is not supported for existing-session profiles.

Other runtime failures may still return `{ "error": "<message>" }` without a
`code` field.

### Playwright requirement

Some features (navigate/act/AI snapshot/role snapshot, element screenshots,
PDF) require Playwright. If Playwright isn't installed, those endpoints return
a clear 501 error.

What still works without Playwright:

- ARIA snapshots
- Role-style accessibility snapshots (`--interactive`, `--compact`,
  `--depth`, `--efficient`) when a per-tab CDP WebSocket is available. This is
  a fallback for inspection and ref discovery; Playwright remains the primary
  action engine.
- Page screenshots for the managed `nova` browser when a per-tab CDP
  WebSocket is available
- Page screenshots for `existing-session` / Chrome MCP profiles
- `existing-session` ref-based screenshots (`--ref`) from snapshot output

What still needs Playwright:

- `navigate`
- `act`
- AI snapshots that depend on Playwright's native AI snapshot format
- CSS-selector element screenshots (`--element`)
- full browser PDF export

Element screenshots also reject `--full-page`; the route returns `fullPage is
not supported for element screenshots`.

If you see `Playwright is not available in this gateway build`, the packaged
Gateway is missing the core browser runtime dependency. Reinstall or update
Nova, then restart the gateway. For Docker, also install the Chromium
browser binaries as shown below.

#### Docker Playwright install

If your Gateway runs in Docker, avoid `npx playwright` (npm override conflicts).
For custom images, bake Chromium into the image:

```bash
NOVA_INSTALL_BROWSER=1 ./scripts/docker/setup.sh
```

For an existing image, install through the bundled CLI instead:

```bash
docker compose run --rm nova-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

To persist browser downloads, set `PLAYWRIGHT_BROWSERS_PATH` (for example,
`/home/node/.cache/ms-playwright`) and make sure `/home/node` is persisted via
`NOVA_HOME_VOLUME` or a bind mount. Nova auto-detects the persisted
Chromium on Linux. See [Docker](/install/docker).

## How it works (internal)

A small loopback control server accepts HTTP requests and connects to Chromium-based browsers via CDP. Advanced actions (click/type/snapshot/PDF) go through Playwright on top of CDP; when Playwright is missing, only non-Playwright operations are available. The agent sees one stable interface while local/remote browsers and profiles swap freely underneath.

## CLI quick reference

All commands accept `--browser-profile <name>` to target a specific profile, and `--json` for machine-readable output.

<AccordionGroup>

<Accordion title="Basics: status, tabs, open/focus/close">

```bash
nova browser status
nova browser doctor
nova browser doctor --deep    # add a live snapshot probe
nova browser start
nova browser start --headless # one-shot local managed headless launch
nova browser stop            # also clears emulation on attach-only/remote CDP
nova browser reset-profile   # moves the profile's browser data to Trash
nova browser tabs
nova browser tab             # shortcut for current tab
nova browser tab new
nova browser tab new --label research
nova browser tab label abcd1234 research
nova browser tab select 2
nova browser tab close 2
nova browser open https://example.com
nova browser focus abcd1234
nova browser close abcd1234
```

</Accordion>

<Accordion title="Profiles: list, create, delete">

```bash
nova browser profiles
nova browser create-profile --name research --color "#0066CC"
nova browser create-profile --name attach --driver existing-session --cdp-url http://127.0.0.1:9222
nova browser delete-profile --name research
```

</Accordion>

<Accordion title="Inspection: screenshot, snapshot, console, errors, requests">

```bash
nova browser screenshot
nova browser screenshot --full-page
nova browser screenshot --ref 12        # or --ref e12
nova browser screenshot --labels
nova browser snapshot
nova browser snapshot --format aria --limit 200
nova browser snapshot --interactive --compact --depth 6
nova browser snapshot --efficient
nova browser snapshot --labels
nova browser snapshot --urls
nova browser snapshot --selector "#main" --interactive
nova browser snapshot --frame "iframe#main" --interactive
nova browser snapshot --out snapshot.txt
nova browser console --level error
nova browser errors --clear
nova browser requests --filter api --clear
nova browser pdf
nova browser responsebody "**/api" --max-chars 5000
```

</Accordion>

<Accordion title="Actions: navigate, click, type, drag, wait, evaluate">

```bash
nova browser navigate https://example.com
nova browser resize 1280 720
nova browser click 12 --double           # or e12 for role refs
nova browser click-coords 120 340        # viewport coordinates
nova browser type 23 "hello" --submit
nova browser press Enter
nova browser hover 44
nova browser scrollintoview e12
nova browser drag 10 11
nova browser select 9 OptionA OptionB
nova browser download e12 report.pdf
nova browser waitfordownload report.pdf
nova browser upload /tmp/nova/uploads/file.pdf
nova browser upload /tmp/nova/uploads/file.pdf --ref e12
nova browser upload media://inbound/file.pdf
nova browser fill --fields '[{"ref":"1","type":"text","value":"Ada"}]'
nova browser dialog --accept
nova browser dialog --dismiss --dialog-id d1
nova browser wait --text "Done"
nova browser wait "#main" --url "**/dash" --load networkidle --fn "window.ready===true"
nova browser evaluate --fn '(el) => el.textContent' --ref 7
nova browser evaluate --fn 'const title = document.title; return title;'
nova browser evaluate --timeout-ms 30000 --fn 'async () => { await window.ready; return true; }'
nova browser highlight e12
nova browser trace start
nova browser trace stop
```

</Accordion>

<Accordion title="State: cookies, storage, offline, headers, geo, device">

```bash
nova browser cookies
nova browser cookies set session abc123 --url "https://example.com"
nova browser cookies clear
nova browser storage local get
nova browser storage local set theme dark
nova browser storage session clear
nova browser set offline on
nova browser set headers --headers-json '{"X-Debug":"1"}'
nova browser set credentials user pass            # --clear to remove
nova browser set geo 37.7749 -122.4194 --origin "https://example.com"
nova browser set media dark
nova browser set timezone America/New_York
nova browser set locale en-US
nova browser set device "iPhone 14"
```

</Accordion>

</AccordionGroup>

Notes:

- The agent-facing `browser` tool exposes `action=download` (required `ref` and
  `path`) and `action=waitfordownload` (optional `path`). Both return the saved
  download URL, suggested filename, and guarded local path. Explicit download
  interception is available for managed Playwright profiles; existing-session
  profiles return an unsupported-operation error.
- Prefer atomic chooser uploads: pass the trigger `--ref` with the upload so Nova arms and clicks in one request. Paths-only `upload` remains supported when a later trigger is intentional. Use `--input-ref` or `--element` to set a file input directly. `dialog` is an arming call; run it before the click/press that triggers the dialog. If an action opens a modal, the action response includes `blockedByDialog` and `browserState.dialogs.pending`; pass that `dialogId` to respond directly. Dialogs handled outside Nova appear under `browserState.dialogs.recent`.
- `click`/`type`/etc require a `ref` from `snapshot` (numeric `12`, role ref `e12`, or actionable ARIA ref `ax12`). CSS selectors are intentionally not supported for actions. Use `click-coords` when the visible viewport position is the only reliable target.
- Download and trace paths are constrained to Nova temp roots: `/tmp/nova{,/downloads}` (fallback: `${os.tmpdir()}/nova/...`).
- `upload` accepts files from the Nova temp uploads root and
  Nova-managed inbound media. Managed inbound media can be referenced as
  `media://inbound/<id>`, sandbox-relative `media/inbound/<id>`, or a resolved
  path inside the managed inbound media directory. Nested media refs,
  traversal, symlinks, hardlinks, and arbitrary local paths are still rejected.
- `upload` can also set file inputs directly via `--input-ref` or `--element`.

Stable tab ids and labels survive Chromium raw-target replacement when Nova
can prove the replacement tab, such as a unique old/new pair for the same URL or
a single old tab becoming a single new tab after form submission. Ambiguous
duplicate-URL replacements receive fresh handles. Raw target ids are still
volatile; prefer `suggestedTargetId` from `tabs` in scripts.

Snapshot flags at a glance:

- `--format ai` (default with Playwright): AI snapshot with numeric refs (`aria-ref="<n>"`).
- `--format aria`: accessibility tree with `axN` refs. When Playwright is available, Nova binds refs with backend DOM ids to the live page so follow-up actions can use them; otherwise treat the output as inspection-only.
- `--efficient` (or `--mode efficient`): compact role snapshot preset. Set `browser.snapshotDefaults.mode: "efficient"` to make this the default (see [Gateway configuration](/gateway/configuration-reference#browser)).
- `--interactive`, `--compact`, `--depth`, `--selector` force a role snapshot with `ref=e12` refs. `--frame "<iframe>"` scopes role snapshots to an iframe.
- With Playwright, `--labels` adds a screenshot with overlayed ref labels
  (prints `MEDIA:<path>`) plus an `annotations` array with each ref's bounding
  box. On `screenshot`, Playwright-backed labels work with `--full-page`,
  `--ref`, and `--element`; on `snapshot`, the accompanying screenshot remains
  viewport-only. Existing-session/chrome-mcp profiles render overlay labels on
  page screenshots but do not return `annotations` or use the Playwright
  full-page/ref/element projection helper. Without Playwright or chrome-mcp,
  labeled screenshots are not available.
- `--urls` appends discovered link destinations to AI snapshots.

## Snapshots and refs

Nova supports two "snapshot" styles:

- **AI snapshot (numeric refs)**: `nova browser snapshot` (default; `--format ai`)
  - Output: a text snapshot that includes numeric refs.
  - Actions: `nova browser click 12`, `nova browser type 23 "hello"`.
  - Internally, the ref is resolved via Playwright's `aria-ref`.

- **Role snapshot (role refs like `e12`)**: `nova browser snapshot --interactive` (or `--compact`, `--depth`, `--selector`, `--frame`)
  - Output: a role-based list/tree with `[ref=e12]` (and optional `[nth=1]`).
  - Actions: `nova browser click e12`, `nova browser highlight e12`.
  - Internally, the ref is resolved via `getByRole(...)` (plus `nth()` for duplicates).
  - Add `--labels` to include a screenshot with overlayed `e12` labels. On
    Playwright-backed profiles this also returns per-ref bounding-box metadata
    (`annotations[]`).
  - Add `--urls` when link text is ambiguous and the agent needs concrete
    navigation targets.

- **ARIA snapshot (ARIA refs like `ax12`)**: `nova browser snapshot --format aria`
  - Output: the accessibility tree as structured nodes.
  - Actions: `nova browser click ax12` works when the snapshot path can bind
    the ref through Playwright and Chrome backend DOM ids.
- If Playwright is unavailable, ARIA snapshots can still be useful for
  inspection, but refs may not be actionable. Re-snapshot with `--format ai`
  or `--interactive` when you need action refs.
- Docker proof for the raw-CDP fallback path: `pnpm test:docker:browser-cdp-snapshot`
  starts Chromium with CDP, runs `browser doctor --deep`, and verifies role
  snapshots include link URLs, cursor-promoted clickables, and iframe metadata.

Ref behavior:

- Refs are **not stable across navigations**; if something fails, re-run `snapshot` and use a fresh ref.
- `/act` returns the current raw `targetId` after action-triggered replacement
  when it can prove the replacement tab. Keep using stable tab ids/labels for
  follow-up commands.
- If the role snapshot was taken with `--frame`, role refs are scoped to that iframe until the next role snapshot.
- Unknown or stale `axN` refs fail fast instead of falling through to
  Playwright's `aria-ref` selector. Run a fresh snapshot on the same tab when
  that happens.

## Wait power-ups

You can wait on more than just time/text:

- Wait for URL (globs supported by Playwright):
  - `nova browser wait --url "**/dash"`
- Wait for load state:
  - `nova browser wait --load networkidle`
  - Supported on managed `nova` and raw/remote CDP profiles. Profiles using the `existing-session` driver (including the default `user` profile) reject `networkidle`; use `--url`, `--text`, a selector, or `--fn` waits there.
- Wait for a JS predicate:
  - `nova browser wait --fn "window.ready===true"`
- Wait for a selector to become visible:
  - `nova browser wait "#main"`

These can be combined:

```bash
nova browser wait "#main" \
  --url "**/dash" \
  --load networkidle \
  --fn "window.ready===true" \
  --timeout-ms 15000
```

## Debug workflows

When an action fails (e.g. "not visible", "strict mode violation", "covered"):

1. `nova browser snapshot --interactive`
2. Use `click <ref>` / `type <ref>` (prefer role refs in interactive mode)
3. If it still fails: `nova browser highlight <ref>` to see what Playwright is targeting
4. If the page behaves oddly:
   - `nova browser errors --clear`
   - `nova browser requests --filter api --clear`
5. For deep debugging: record a trace:
   - `nova browser trace start`
   - reproduce the issue
   - `nova browser trace stop` (prints `TRACE:<path>`)

## JSON output

`--json` is for scripting and structured tooling.

Examples:

```bash
nova browser --json status
nova browser --json snapshot --interactive
nova browser --json requests --filter api
nova browser --json cookies
```

Role snapshots in JSON include `refs` plus a small `stats` block (lines/chars/refs/interactive) so tools can reason about payload size and density.

## State and environment knobs

These are useful for "make the site behave like X" workflows:

- Cookies: `cookies`, `cookies set`, `cookies clear`
- Storage: `storage local|session get|set|clear`
- Offline: `set offline on|off`
- Headers: `set headers --headers-json '{"X-Debug":"1"}'` (or the positional form `set headers '{"X-Debug":"1"}'`)
- HTTP basic auth: `set credentials user pass` (or `--clear`)
- Geolocation: `set geo <lat> <lon> --origin "https://example.com"` (or `--clear`)
- Media: `set media dark|light|no-preference|none`
- Timezone / locale: `set timezone ...`, `set locale ...`
- Device / viewport:
  - `set device "iPhone 14"` (Playwright device presets)
  - `set viewport 1280 720`

## Security and privacy

- The nova browser profile may contain logged-in sessions; treat it as sensitive.
- `browser act kind=evaluate` / `nova browser evaluate` and `wait --fn`
  execute arbitrary JavaScript in the page context. Prompt injection can steer
  this. Disable it with `browser.evaluateEnabled=false` if you do not need it.
- `nova browser evaluate --fn` accepts a function source, an expression, or
  a statement body. Statement bodies are wrapped as async functions, so use
  `return` for the value you want back. Use `--timeout-ms <ms>` when the
  page-side function may need longer than the default evaluate timeout.
- For logins and anti-bot notes (X/Twitter, etc.), see [Browser login + X/Twitter posting](/tools/browser-login).
- Keep the Gateway/node host private (loopback or tailnet-only).
- Remote CDP endpoints are powerful; tunnel and protect them.

Strict-mode example (block private/internal destinations by default):

```json5
{
  browser: {
    ssrfPolicy: {
      dangerouslyAllowPrivateNetwork: false,
      hostnameAllowlist: ["*.example.com", "example.com"],
      allowedHostnames: ["localhost"], // optional exact allow
    },
  },
}
```

## Related

- [Browser](/tools/browser) - overview, configuration, profiles, security
- [Browser login](/tools/browser-login) - signing in to sites
- [Browser Linux troubleshooting](/tools/browser-linux-troubleshooting)
- [Browser WSL2 troubleshooting](/tools/browser-wsl2-windows-remote-cdp-troubleshooting)
