# Changelog

Docs: https://docs.nova.ai

## Unreleased

### Changes

- **Control UI sender identity polish:** attributed user messages show the author's real avatar in an always-visible gutter on identity-resolving gateways, sender labels drop the opaque profile-UUID suffix (new and historical transcripts), and profile-id senders resolve avatars through the canonical gateway route.
- **Control UI who's-online roster:** click the sidebar footer facepile to open a scrollable roster of everyone online, showing each person's avatar, name, and email with your own entry pinned first.
- **Discord and Slack native login:** register `/login` in native command menus while keeping pairing-code issuance limited to private chats and the Web UI.
- **Control UI user profiles:** let trusted-proxy users manage their own display name and avatar, resolve attributed chat and presence identities through uploaded avatars or a private cached Gravatar proxy, and keep other users' profiles admin-only.
- **Trusted-proxy browser pairing:** optionally auto-approve new Control UI and WebChat devices from allowlisted proxy identities with non-admin scope caps, while keeping existing-device upgrades manual.
- **Channel plugin ingress monitors:** add a shared plugin SDK monitor for durable admission, polling, pruning, claim identity validation, adoption handoff, and shutdown, and migrate IRC, Synology Chat, and Google Chat to the shared lifecycle.
- **Dashboard MCP apps:** pin originating-session MCP app views as living dashboard widgets, renew their sandboxed view leases, and keep tool interactivity behind revision-bound grants with graceful stale-state recovery.
- **External gateway supervision:** add `NOVA_SUPERVISOR_MODE=external` for lifecycle owners such as OCM, preserving verified restart and deferral behavior without exposing native service authority, blocking native service mutation and self-update, and providing a versioned atomic restart-handoff consume contract. Thanks @shakkernerd.
- **ClickClack guided setup:** configure ClickClack from `nova onboard` or `nova channels add clickclack` with URL, token, and workspace prompts, default-account env fallback, nonfatal live connection validation, and gateway-aware next steps that connect automatically when Nova is already running. Thanks @shakkernerd.
- **ClickClack command menus:** publish each bot's native Nova commands to ClickClack composer autocomplete at gateway startup, with per-account opt-out and nonfatal compatibility handling for older tokens and servers. Thanks @shakkernerd.
- **Skill Workshop approvals:** run agent-initiated apply, reject, and quarantine actions without an additional approval prompt by default while preserving `skills.workshop.approvalPolicy: "pending"` as an opt-in approval gate. Thanks @shakkernerd.
- **TUI fuzzy selectors:** delegate list matching to pi-tui, adding slash-token and alpha-number matching while removing the local matcher fork.
- **macOS paired-node terminals:** advertise duplex Codex and Claude terminal resume commands from the embedded node host and forward interactive input and cancellation through the native app bridge. (#107335)
- **Control UI catalog terminals:** open eligible Codex and Claude Code sessions in the native CLI on their Gateway or paired-node host, with viewer-versus-terminal preferences, validated resume commands, and an interactive PTY relay. (#107086)
- **Skill Workshop history review:** add a manual, newest-first session scan that progressively searches older substantial work for conservative skill ideas, stores only SQLite cursor metadata, and leaves up to three results as pending proposals even when autonomous self-learning is disabled. (#106182)
- **SQLite snapshots:** add `nova backup sqlite create|list|verify|restore` for compact, verified global and per-agent database artifacts with fresh-target-only restore. (#94805) Thanks @giodl73-repo.
- **GPT-5.6 Ultra and runtime switching:** support Sol, Terra, and Luna across Nova and Codex engines; keep model, runtime, and thinking selection atomic through `/model` and fallback; and add live matrix coverage for both harnesses. (#98021) Thanks @anyech.
- **OpenAI GPT-5.6 defaults:** use `openai/gpt-5.6` (Sol alias) for fresh API-key setup and exact `openai/gpt-5.6-sol` for fresh Codex/OAuth setup, default Sol to medium reasoning across both runtimes, and preserve existing primaries, fallbacks, aliases, and explicit GPT-5.5 selections. (#103234)
- **Meta provider:** add bundled `muse-spark-1.1` model support with Responses API streaming, tool calls, encrypted reasoning replay, onboarding, and standalone npm/ClawHub distribution. (#102873) Thanks @HamidShojanazeri.
- **Android chat agent selector:** switch the active agent directly from the live chat screen while keeping chat, Talk mode, and home canvas on the same canonical session. (#80422) Thanks @bcperry.
- **Gateway host status:** show the connected Gateway's host, network address, OS, runtime, uptime, CPU, memory, and disk details in Control UI Settings. (#100478)
- **iOS offline chat:** pre-paint recent sessions and canonical transcripts from a protected, bounded per-gateway cache, keep sending disabled offline, and purge cached conversation text when pairing is reset. (#100194)
- **Slack progress indicators:** use Slack's native assistant thread status and rotating loading messages by default while keeping acknowledgement reactions static; lifecycle reaction updates now require `messages.statusReactions.enabled: true`.
- **Control UI Talk controls:** keep voice, model, sensitivity, and other realtime defaults in Settings → Communications → Talk, and use the composer microphone caret to select any browser audio input. (#101046)
- **Control UI session workspace shortcut:** expand or collapse the active Chat pane's session workspace rail with ⇧⌘B without changing the main app sidebar or the separate detail and Canvas preview panel. Thanks @shakkernerd.
- **Control UI Settings shortcut:** open Settings with ⇧⌘, while leaving the browser-owned ⌘, shortcut unchanged. Thanks @shakkernerd.
- **Control UI chat layout:** center the transcript on the composer axis, keep assistant and tool output left and user bubbles right within the same readable frame, and preserve custom message-width overrides. (#104474) Thanks @shakkernerd.
- **Control UI composer footer:** center the chat settings chip and model controls between the divider and the card edge instead of pinning them to the divider. (#105866)
- **Control UI assistant actions:** keep assistant name and time first while placing hover actions beside them on the left instead of at the far edge. Thanks @shakkernerd.
- **Cron model selection:** choose an agent-turn model in Control UI Quick Create and show configured or default models in cron job rows and details. (#95341) Thanks @ly85206559.
- **Control UI GitHub previews:** show issue and pull request state, title, author, activity, comments, and change statistics in hover and keyboard-focus cards. (#100434)
- **Logbook work journal:** add a disabled-by-default bundled plugin that turns paired-node screen snapshots into a private timeline, daily standup, and timeline-grounded Q&A in a plugin-contributed Control UI tab. (#99930)
- **Control UI message context:** reveal per-message token, context, and model details from the timestamp on hover or activation instead of showing a separate Context button.
- **Control UI session titles:** reveal truncated recent-session names with a reduced-motion-safe hover animation.
- **Control UI sidebar navigation:** show a small customizable pinned destination set, keep the remaining pages under More, move Settings to the footer, and persist sidebar customization in the browser. (#100296)
- **Control UI sidebar usage:** remove the provider usage quota row from the expanded sidebar while keeping usage details available in the chat composer and Usage page. Thanks @shakkernerd.
- **Android chat code highlighting:** render fenced Kotlin, Swift, TypeScript, JavaScript, Python, Bash, and JSON blocks with bounded, theme-aware syntax colors while preserving plain rendering for unknown, partial, or oversized blocks. (#100217)
- **Gateway TTS playback:** add an operator-scoped `tts.speak` RPC that returns configured-provider speech as inline whole-clip audio for remote clients. (#100708, #100770)
- **Workboard dispatch cap:** add a request-scoped `--max-starts` override while preserving the default cap, sequential starts, and one-card-per-owner guard. (#100174) Thanks @souvikDevloper.
- **Plugin install provenance warnings:** require explicit `--force` acknowledgement for arbitrary executable plugin sources in CLI and chat installs, keep trusted ClawHub, bundled, official-catalog, and tracked-update flows frictionless, and restrict Crestodian installs to trusted sources. (#102197) Thanks @jesse-merhi.

### Fixes

- **Standalone plugin files:** let manifestless files explicitly listed in `plugins.load.paths` pass config validation and load independently when several files share a directory.
- **Control UI terminal error messages:** preserve message-only assistant output beginning with `Error:` or a warning marker instead of treating text prefixes as synthetic failures. Thanks @shakkernerd.
- **Channel outbound echo suppression:** drop recently emitted platform message and source identities at shared inbound admission and migrate Discord thread unbinds off channel-local expiry state, preventing delayed webhook copies from re-entering agents.
- **Reef startup reconciliation:** contain retryable relay failures during startup without supervisor restart loops, while preserving definitive-error and cancellation handling. Thanks @Yigtwxx.
- **Codex stale-session replies:** stop model fallback after another gateway supersedes a Codex session generation and deliver a safe retry notice instead of abandoning the message silently.
- **Bounded input and provider responses:** cap pasted auth/config input and enforce wall-clock deadlines across generated-media downloads, polling JSON, and failed response details so oversized or slow-drip streams cannot exceed resource budgets (thanks @Pick-cat).
- **LINE durable inbound media:** retry transient content preparation, network, and response-stream failures through durable ingress so media-only messages are not acknowledged before their attachment is saved. (#110921) Thanks @edenfunf.
- **Cloud worker derived workspace caches:** exclude Python caches, dependency trees, and macOS metadata symmetrically from outbound sync and inbound reconciliation so local cache rewrites cannot fence later cloud results or worker reclaim.
- **Codex model status diagnostics:** report a configured Codex route as unavailable when its harness plugin is disabled, missing, or quarantined, while preserving the separate credential result and making `models status --check` fail instead of silently treating fallback execution as healthy. Thanks @shakkernerd.
- **Gateway control-plane rate limiting:** use per-method buckets with a 30-per-minute budget so interactive admin writes remain responsive while retaining runaway-loop protection.
- **External supervisor restart health:** accept device-identity policy closes only when the replacement gateway lock and listener PID agree, preventing OCM-managed restarts from timing out after a successful handoff. Thanks @shakkernerd.
- **ACPX cleanup process inspection:** bound host process-table reads so stalled `ps` calls cannot hang gateway startup or session cleanup while retaining fail-closed ownership checks. Thanks @Alix-007.
- **Cron lifecycle conflict retries:** preserve execution-phase retry decisions across scheduled, manual, and startup-recovered runs so post-execution claim conflicts cannot replay completed messages or tools. Fixes #108428. Thanks @yetval.
- **Discord gateway metadata deadline:** carry the existing lookup deadline through DNS and proxy preflight, request headers, and response bodies so stalled gateway startup aborts cleanly. (#104580) Thanks @hugenshen.
- **Control UI cloud session thinking:** expose reasoning level in the New Session model picker and persist the selected level before cloud dispatch.
- **iOS fresh-install setup:** atomically redact spent setup credentials before Keychain cleanup so a deferred item deletion no longer disconnects a successfully paired device. Fixes #107591. Thanks @dagmarjeeves-lab.
- **Tlon SSE connect cleanup:** disarm opening deadlines after failed HTTP responses and rejected stream opens so reconnect attempts cannot leave stale timers behind. (#104585) Thanks @hugenshen.
- **LINE reply-token media kinds:** honor video and audio metadata on inbound replies, share the canonical media builder with proactive sends, and fail visibly instead of recording empty media-only deliveries. (#106515) Thanks @edenfunf.
- **Mattermost websocket connection deadlines:** bound opening handshakes so stalled TCP peers cannot hang channel startup indefinitely and reconnect control resumes after timeout. (#105553) Thanks @hugenshen.
- **Queued TTS retries:** copy local outbound media into queue-owned storage before enqueueing so voice replies survive producer temp cleanup and restart recovery, retain referenced artifacts through retry backoff, and prune unreferenced spool files after one day. Fixes #108501. (#108502) Thanks @masatohoshino.
- **Feishu app registration deadlines:** bound OAuth device-registration requests to 10 seconds through the guarded fetch boundary so setup cannot hang indefinitely on stalled response headers. (#105549) Thanks @hugenshen.
- **LINE control-command mentions:** detect authorized slash commands before mention stripping so inline group and direct-message controls preserve the original ingress metadata. (#107230) Thanks @edenfunf.
- **Feishu document image reads:** bound remote document-image headers and stalled bodies with the selected account timeout, parse document Markdown through the plugin's MDAST pipeline, preserve image/block alignment, and reject failed upload input before creating empty image blocks. Thanks @Alix-007.
- **ClawHub registry reads:** retry bounded HTTP 500 responses alongside other transient gateway failures so multi-package release scans survive isolated registry errors.
- **Slack Socket Mode health:** report connected Socket Mode transports as degraded when `auth.test` fails or the configured bot token resolves to a user without `bot_id`, while preserving healthy enterprise-org installs. Thanks @zw-xysk.
- **Synology Chat response limits:** bound user-list response reads, stop oversized streams immediately, and retain stale cached identities when a NAS exceeds the supported envelope. Thanks @zw-xysk.
- **Usage date ranges:** exclude legacy transcript rows without timestamps from finite session ranges while preserving them in all-time totals, and rebuild older usage caches before serving the new semantics. Fixes #89709. Thanks @TurboTheTurtle.
- **LINE group history races:** retain ambient group messages received during an active mention turn for the next turn while consuming the pre-turn snapshot exactly once. (#107367) Thanks @edenfunf.
- **Mattermost progress command details:** accept the documented `streaming.preview.commandText` and `streaming.progress.commandText` modes in channel config validation and bundled metadata. Thanks @shakkernerd.
- **1Password authorization handoff:** persist nonce-bound pending approvals in shared plugin state so hook and tool execution across broker instances remain single-use and fail closed.
- **Control UI chat transcripts:** preserve loaded history across session and pane returns, bound automatic backscroll loading, virtualize long transcripts, retain hidden native run boundaries, and keep prepends, streaming, and responsive layouts from flickering or jumping. Thanks @shakkernerd.
- **Codex dynamic tool outcomes:** use the shared tool-result failure contract for arbitrary lifecycle metadata, preventing successful Skill Workshop results from being displayed and persisted as failed calls. Fixes #107684. Thanks @shakkernerd.
- **Codex `/status` context freshness:** consume exact per-response usage from Codex app servers that emit `rawResponse/completed`; when exact usage is unavailable or omitted, keep context unknown instead of reusing cumulative lifetime totals. (#107813) Thanks @wuqxuan.
- **Codex resumed permissions:** apply stored per-session approval and sandbox overrides to primary resumed harness turns so `/codex permissions` survives later messages and gateway restarts.
- **Nested resource ignores:** honor slash-free patterns and escaped literal exclamation marks in nested ignore files during skill and resource discovery. Thanks @moguangyu5-design.
- **Proxy bypass precedence:** honor blank lower-case `no_proxy` values shadowing upper-case `NO_PROXY` consistently with Undici, and reuse the canonical matcher for Telegram fallback selection.
- **Tokenjuice exec compaction:** avoid retaining raw command output inside compacted middleware metadata, preventing large successful compactions from failing the middleware details-size guard.
- **Agent git package identities:** strip refs before hosted-repository parsing and reject traversal segments so GitLab branch refs resolve to the canonical managed install path.
- **Tlon custom S3 uploads:** pass storage endpoints through the AWS SDK's native parser so custom S3-compatible uploads no longer fail before presigning.
- **Signal active-run controls:** keep authorized stop, status, approval, and queue-read controls responsive during active turns while preserving ordinary and stateful turns in canonical session admission, and cancel every pending group sender lane on stop. (#107422) Thanks @arduano.
- **Agent auth storage locks:** surface normal release failures while avoiding redundant release attempts after `proper-lockfile` reports a compromised lock.
- **Paired-node session catalogs:** authorize bundled Anthropic and Codex catalog requests to invoke their read-only node commands from Control UI read flows, restoring remote Claude/Codex rows and terminal resume availability. Fixes #107406.
- **Sandbox recreate confirmation:** treat Clack cancellation as a decline so Ctrl-C cannot proceed with container removal.
- **Microsoft Teams HTML text:** decode HTML5 entities consistently in quoted and Graph-fetched messages while preserving literal escaped entity text.
- **ClawHub plugin API ranges:** delegate each supported comparator to `semver` so tilde, partial-wildcard, and prerelease caret bounds are correct while preserving Nova version normalization and the existing restricted range grammar. (#106877)
- **Web Readability relative links:** seed parsed documents with the request URL so article links resolve correctly while removing the plugin's duplicate lazy-loader facade. (#106860)
- **Browser auto-routing:** fall back to the Gateway host when an implicitly selected browser node reports that its control host is unreachable, while preserving explicit node pins and ambiguous action failures.
- **Discord voice participant context:** maintain the live Gateway voice-state roster and include current channel participants in authorized voice agent turns so agents can answer who is present.
- **OC Path JSONC insertion:** patch object and array insertions through `jsonc-parser` so comments, trailing commas, and CRLF formatting survive. (#106847)
- **Windows winget installs:** continue in the current PowerShell session when winget installs Node.js before the machine PATH update becomes visible, avoiding a false `Node.js not found` failure. (#106862)
- **Control UI realtime Talk feedback:** request browser echo cancellation, noise suppression, and automatic gain control for every microphone transport, and keep PCM capture processors connected through zero-gain sinks so microphone input cannot play locally.
- **Agent source-reply recovery:** preserve current-chat delivery evidence for message sends executed through Code Mode, preventing successful replies from triggering a redundant retry and misleading delivery-failure diagnostic.
- **Gateway in-process restarts:** clear stale SIGUSR1 restart state and resume prepared host suspensions before rebuilding runtime admission, preventing restart cooldowns or paused scheduling from leaking into the next lifecycle.
- **ClickClack durable media delivery:** route media replies through required delivery, reuse owner-scoped upload and message nonces across retries, repair persisted attachment state without rereading source media, fail closed when an older ClickClack server cannot prove an unknown send, and use the selected provider and model's runtime output budget instead of a channel-level token cap. Thanks @jjjhenriksen and @shakkernerd.
- **Deepgram realtime custom endpoints:** validate Voice Call streaming base URLs with secret-safe errors, preserve explicit `ws://` and `wss://` endpoints, and map HTTP schemes to their matching WebSocket transport for dedicated and self-hosted deployments. (#105334) Thanks @dwc1997.
- **Control UI New Session reconnects:** rediscover agents, nodes, repository branches, and folder-browser state, refresh derived workspaces, gate unvalidated devices, and block ambiguous retries after Gateway client replacement while preserving the typed task and explicit choices. Fixes #106372.
- **macOS remote node readiness:** take the main-session key from the node hello snapshot instead of opening an operator connection during node admission, preventing remote tunnel recovery from leaving Computer Use and node exec stuck in lifecycle transition.
- **Claude CLI context budgets:** honor Anthropic model and per-agent `contextTokens` limits by passing the effective limit to Claude Code's native auto-compactor and persisting the same prepared budget in Nova session state. Fixes #80933. (#93198) Thanks @mushuiyu886.
- **Transcript read failures:** propagate permission and I/O failures from streaming JSONL session reads instead of treating unreadable transcripts as empty. (#106412) Thanks @zenglingbiao.
- **Restart sentinel diagnostics:** report SQLite read/write and legacy-file cleanup failures while preserving best-effort restart recovery behavior. (#106385) Thanks @zenglingbiao and @wendy-chsy.
- **Native app connection and relay reliability:** keep Android disconnects stopped across Activity recreation, fail remote camera commands without opening permission prompts, refresh mobile node registration after capability changes, surface iOS onboarding connection failures, cancel stale Talk owners on session switches, reject invalid Watch acknowledgments, preserve Watch events received during startup, and prevent older agent overview requests from replacing newer gateway state.
- **Gateway source watch:** hand the configured port off from the installed service before starting the tmux watcher, preserve failed panes for attach/capture, and keep explicit alternate-port watches side by side with the managed Gateway.
- **Claude CLI max-turn diagnostics:** preserve terminal max-turn results with Nova and Claude session context, warn when tool actions may already have run, and stop unsafe auth-profile or model replay for potentially side-effecting turns. (#94130) Thanks @zhangguiping-xydt.
- **Provider network retries:** align provider read/poll/download and agent-wait recovery for transient connection errors, retry bounded provider `ENOTFOUND` failures while leaving gateway `ENOTFOUND` and non-idempotent create operations fail-fast. (#101496) Thanks @xialonglee.
- **Session retry classification:** stop permanent provider errors whose identifiers or payload details merely contain 429/5xx digit sequences from re-sending full context, and share bounded rate-limit-window parsing across retry paths. (#105258) Thanks @destire-mio.
- **LINE directive templates:** suppress confirms and buttons with blank required fields or unlabeled actions while preserving valid titleless buttons and surrounding reply text. (#105520) Thanks @edenfunf.
- **SQLite maintenance schema validation:** reject current-version global and agent databases with missing or drifted canonical tables, constraints, indexes, triggers, or table options before compaction, while accepting supported additive-migration layouts.
- **Matrix bootstrap diagnostics:** preserve complete UTF-8 code points in bounded stdout and stderr tails so crypto dependency failures do not show replacement characters at retention boundaries. (#105475) Thanks @qingminlong.
- **iOS Watch relay commands:** allow paired iPhone nodes to advertise and invoke `watch.status` and `watch.notify` through the default Gateway policy while preserving the direct watchOS node's fixed minimal command surface.
- **Swabble status config:** honor the global `--config` path when reading service status instead of silently using the default configuration.
- **Gradium TTS credential egress:** reject non-HTTPS, foreign-host, and hostname-lookalike base URLs before dispatching API keys, and pin guarded transport to Gradium's documented API hostname. (#101280) Thanks @zhangguiping-xydt.
- **ClawHub retry timing:** reject fractional delay-seconds and calendar-normalized invalid Retry-After dates so runtime and release reads stay on their bounded fallback schedule. (#105479) Thanks @qingminlong.
- **Gateway command SecretRefs:** preserve authoritative active-snapshot values when another command secret remains unresolved, falling back locally only for missing paths instead of emitting a per-turn `secrets.resolve` failure. (#96661) Thanks @SunnyShu0925.
- **Cron delivery status:** keep successful isolated agent turns at `status=ok` when downstream delivery fails, while preserving the send failure separately in delivery state and run logs. (#95419) Thanks @Alix-007.
- **Channel ingress recovery:** tombstone and scrub malformed durable ingress payloads without letting corrupt rows hide or starve later valid messages. (#98402) Thanks @Pick-cat.
- **Discord thread archive defaults:** inherit each parent channel's configured auto-archive duration for binding-created threads instead of forcing 60 minutes, while preserving explicit overrides. (#103413) Thanks @wings1029.
- **Installed plugin loading:** make native-module fallback use jiti's transform path instead of retrying the same synchronous ESM load, preventing Node 24 startup races when official plugins import SDK contract modules.
- **QA profile channel execution:** partition mixed Crabline channel scenarios into one aggregate host suite so taxonomy-backed profile commands and evidence workflows no longer abort before execution.
- **Plugin SDK API baseline:** cover every public entrypoint, preserve complete declaration shapes without source-line churn, and run baseline and export-surface guards from changed-file validation.
- **Official plugin beta compatibility:** keep the exact beta.5 session-store helper imports working over SQLite through the documented deprecation window, preventing installed Codex and Feishu plugins from failing during package acceptance and upgrades. (#105287) Thanks @vincentkoc.
- **SQLite terminal session recovery:** track physical transcript mutation time in the agent database so killed or timed-out main sessions rotate when transcript writes outlive the registry update, while preserving legacy transcript mtimes during doctor import.
- **Gateway chat typecheck:** import chat event types from their owning protocol schema after the retired aggregate type module was removed, restoring full project typechecks.
- **Packaged Crabbox commands:** include the lease-freshness helper imported by the published wrapper so `crabbox:*` commands do not fail with `ERR_MODULE_NOT_FOUND` in npm installs.
- **Plugin session catalogs:** reject unknown catalog filters, report catalogs as plugin capabilities, and preserve them in SDK registration captures instead of silently returning empty results or classifying catalog-only plugins as capability-free.
- **Gateway service audit:** treat POSIX shell `-c` wrappers as opaque for the gateway-subcommand check, avoiding false missing-command warnings for shell-wrapped macOS LaunchAgents without parsing inner commands or ports. Fixes #81751. (#81778) Thanks @liaoandi.
- **Memory filename search:** index paths separately from chunk bodies so exact full-path, basename, and stem queries rank the intended memory file first without changing body BM25 scores, snippets, or embeddings. (#96052, #94102) Thanks @Pick-cat.
- **Outbound channel bootstrap:** suppress repeated failed plugin activation for the same channel, config, and registry generation while retrying after config or registry reloads. (#100377) Thanks @xialonglee.
- **OpenAI Realtime client-secret deadlines:** bound voice and transcription secret acquisition to 30 seconds through the guarded fetch boundary while preserving authentication and bounded response parsing. (#102860) Thanks @Alix-007.
- **Gateway client watchdog:** keep transport-stall detection active for unbounded and mixed pending requests so dead sockets reject pending requests, reconnect, and never replay rejected requests. (#103407) Thanks @NianJiuZst.
- **iOS Share Extension drafts:** preserve legitimate shared text beginning with scaffold-like prefixes, remove only exact legacy scaffold lines, avoid treating scheme-like prose as a URL, and deduplicate host-mirrored content. (#103453) Thanks @lin-hongkuan.
- **Telegram reasoning previews:** reposition split reasoning previews through deferred deletion so prior preview messages do not remain stale while preserving client scroll position. (#97828) Thanks @ly-wang19.
- **Feishu native-card threading:** normalize whitespace reply targets once and reuse the shared reply mode for card and media parts so native-card topic replies stay in their thread. (#102804) Thanks @sunlit-deng.
- **Plain-text XML tool calls:** repair zero-argument calls and keep byte/character-bounded stream normalization from leaking incomplete or oversized tool syntax while preserving visible suffix text. (#98984, #102240, #102933, #102975, #103220, #103585) Thanks @wangyan2026, @qingminglong, @wuqxuan, and @ZOOWH.
- **QQBot token requests:** bound token acquisition with the shared 30-second guarded-fetch deadline so stalled singleflight callers fail together, clean up, and can retry. (#102897) Thanks @maweibin.
- **Canvas A2UI validation:** reject malformed or unsupported JSONL at CLI, agent-tool, and final node-invoke boundaries while preserving native v0.8 dispatch. (#103713) Thanks @qingminglong.
- **Twilio RCS inbound routing:** normalize RCS consumer addresses only after signed webhook validation so sender matching and sessions work without changing outbound RCS semantics. (#102373) Thanks @clawSean.
- **ClickClack output sanitization:** strip internal tool and XML scaffolding at the sender boundary, suppress scaffold-only sends, and preserve optional modern delivery IDs. (#103142) Thanks @masatohoshino.
- **CLI installer cleanup:** remove Node staging directories and pnpm workspace-rewrite temporary files on failure. (#103725) Thanks @SebTardif.
- **Agent-core truncation:** avoid empty-output crashes when head truncation receives negative line or byte ceilings. (#103425) Thanks @qingminglong.
- **Windows Node resolution:** preserve the current executable when resolving bare case-insensitive `node.exe` entries under hostile `PATH` values. (#103907) Thanks @soldforaloss.
- **Codex runtime switching:** accept the bundled Codex runtime for both `codex/*` and `openai/*` model routes while keeping unsupported provider/runtime pairs rejected. (#103762)
- **Agent abort cleanup:** serialize prompt lock reacquisition with terminal cleanup so canceled embedded runs do not self-contend on session locks for up to 60 seconds.
- **Chutes OAuth deadlines:** bound token exchange, profile lookup, and refresh requests, and keep issued tokens when optional userinfo enrichment stalls. (#102026) Thanks @Alix-007.
- **Control UI workspace avatars:** inline validated agent avatar files in bootstrap and identity responses so Personal card images render without unauthenticated avatar-route requests, while preserving configured emoji precedence. (#102892, #97602) Thanks @LZY3538.
- **Exec safe-bin flags:** auto-approve curated read-only boolean flags for default stdin-only filters while keeping unknown flags, tail follow/retry modes, file operands, and custom profiles fail-closed. (#88953) Thanks @yetval.
- **iOS session mutations:** scope rename, archive, pin, delete, and fork requests to the selected agent, preserving the parent agent for forked sessions so multi-agent chat actions cannot mutate or create sessions under the wrong agent. (#103366, #103415) Thanks @lin-hongkuan and @harjothkhara.
- **Model pin hot reload and fallback:** keep explicit `/model` selections authoritative across Telegram config reloads and model fallback, capture one live config snapshot per assembled turn, and leave fallback candidates turn-local instead of persisting them over the user's pin. (#103324, #103417) Thanks @obviyus.
- **Swift protocol initializers:** default every schema-optional generated initializer parameter to `nil` so additive protocol fields no longer break SDK construction call sites.
- **Telegram DM conversation context:** correlate rendered outbound messages with stable transcript identities across chunked, rich-fallback, media, and streamed delivery, preventing Markdown replies from appearing twice while retaining the full transcript when a cached multipart projection is incomplete. (#100333, #102257, #102259, #102469) Thanks @crabkun, @consoleaf, and @chenyangjun-xy.
- **OpenCode Go MiMo catalog:** stop exposing the deprecated `mimo-v2-omni` and `mimo-v2-pro` aliases that reject agent requests, and keep release validation on the active MiMo V2.5 routes. (#103311, #103329) Thanks @krissding.
- **Audit time filters:** reject impossible calendar dates for `nova audit --after` and `--before` instead of rolling them into unintended intervals, while preserving timezone-less timestamp semantics. (#103433) Thanks @qingminglong.
- **OpenAI-compatible streamed tool calls:** execute complete native tool calls from streams that end with SSE `data: [DONE]` but omit `finish_reason`, while keeping transport EOF and visible-text cases fail-closed. (#98124, #97994) Thanks @SunnyShu0925.
- **xAI provider aliases:** preserve Grok 4.3 and Grok 4.5 thinking profiles, fast-model routing, and encrypted reasoning replay when models use the shipped `x-ai` provider alias instead of clamping valid thinking requests to `minimal`. (#103315)
- **Doctor state isolation:** prevent automated update and Gateway watch repair from importing and archiving default-home exec or plugin-binding approvals when `NOVA_STATE_DIR` points elsewhere, keep implicit CLI preflight notice-only, and reserve cross-state imports for direct operator doctor runs. (#103247, #103317)
- **Doctor clean-state guidance:** stop suggesting `nova doctor --fix` after a clean run with no config changes while preserving targeted repair hints. (#103233)
- **Google music generation:** retry one unblocked Lyria response that omits its contractually required audio while keeping prompt blocks and terminal generation stops non-retryable. (#103318)
- **OpenCode Zen model catalog:** refresh the provider-owned static seed for Claude Sonnet 5, Grok 4.5, Hy3 Free, Kimi K2.7 Code, and MiniMax M3 with verified routing, pricing, limits, and input capabilities, remove retired free-tier rows, and expose the same catalog through unauthenticated model listing. (#103184)
- **Managed browser launch:** surface asynchronous Chrome bootstrap and runtime spawn failures as browser errors while keeping Gateway alive, and retain process error handling through later lifecycle failures.
- **Browser node-proxy downloads:** transfer every action-produced download to the Gateway media store, align a 10 MiB per-file and 16 MiB aggregate transport budget, and rewrite plural download paths to Gateway-local files without traversing page-controlled result data.
- **Gateway startup migrations:** release the shared migration lease before exiting when the selected config changes during startup, allowing immediate retries instead of blocking readiness until the five-minute lease expires. (#103145)
- **Apple timeout recovery:** return promptly from shared operation deadlines and caller cancellation even when platform work ignores cancellation, while isolating late Gateway handshakes and cleaning up location and permission waiters. (#103066) Thanks @NianJiuZst.
- **Claude CLI warm sessions:** preserve managed stdio continuity when Claude writes no native transcript, fall back to bounded Nova history only when the exact live child disappears or changes, and keep stateless runs from persisting CLI bindings. (#96841) Thanks @bradreaves.
- **CLI plugin listing:** skip state-migration runtime loading when no legacy inputs exist, reducing packaged cold-start memory while preserving migrations for legacy plugin indexes and configured session stores.
- **Unicode-safe bounded text:** preserve complete UTF-16 surrogate pairs when shortening previews, prompts, diagnostics, labels, session keys, link metadata, and identity values across Control UI, CLI, Gateway, plugins, QA, memory, and Android surfaces. (#102625, #102626, #102627, #102656, #102816, #102823, #102833, #102877, #102949, #102963, #102969, #102988, #103010, #103034, #103210, #103341, #103487, #103543, #103580, #103646) Thanks @zhangguiping-xydt, @wings1029, @wangyan2026, @Pandah97, @MoerAI, @SunnyShu0925, @zhangqueping, @zw-xysk, @cxbAsDev, @lzyyzznl, @coder-master-0915, @LeonidasLux, @mushuiyu886, @ly85206559, @Simon-XYDT, and @lsr911.
- **Cron list table:** sanitize and size bounded cells by terminal display width so CJK, emoji, combining marks, and terminal-control input cannot corrupt alignment or output. (#103616) Thanks @mushuiyu886.
- **CLI model tables:** sanitize, truncate, and pad model-list cells by rendered terminal width so emoji, CJK, and other wide graphemes keep columns aligned. (#102819) Thanks @Kevin23-design and @vincentkoc.
- **Skills prompt compaction:** preserve every included skill identity before using the remaining prompt budget for shortened, UTF-16-safe descriptions, retaining trigger guidance without exceeding the hard limit. (#88426) Thanks @abel-zer0.
- **Channel Markdown code tables:** size columns by rendered display width so CJK, emoji, and mixed-width cells stay aligned across shared Telegram and Discord output. (#55596, #55512) Thanks @sparkyrider.
- **QQ Bot approval previews:** wrap long sanitized commands and metadata at grapheme boundaries with visible continuation markers and safe fences, keeping desktop QQ reviews readable without changing command content. (#102119, #101979) Thanks @Bartok9.
- **Codex computer control:** publish fixed-length coordinate pairs as homogeneous array schemas so Codex app-server can start threads with the `computer` tool instead of rejecting tuple-valued `items`.
- **Google Chat request deadlines:** bound control calls to 30 seconds while giving media transfers size-aware total budgets and a separate 30-second stalled-body guard, preventing hung Chat API requests without breaking large attachment uploads. (#102227) Thanks @hugenshen.
- **Google Gemini prefixed model IDs:** recognize `google/gemini-*` and `models/gemini-*` when selecting multimodal function-response behavior, preserving the Gemini 2 image fallback without regressing Gemini 3 inline image responses. (#102382) Thanks @LiLan0125.
- **Generated provider model catalogs:** keep MiniMax and NVIDIA catalog rows when they advertise audio or video metadata while projecting runtime model inputs to text/image, preventing configured multimodal primaries from being dropped and falling back. (#97858, #97048) Thanks @ly-wang19 and @zackchiutw.
- **DeepSeek catalog metadata:** align V4 Flash and Pro pricing with DeepSeek's current cache-hit, cache-miss, and output rates; refresh exact catalog metadata written by older onboarding flows; and document the July 24 retirement of the legacy `deepseek-chat` and `deepseek-reasoner` compatibility names. (#103192)
- **CLI audio transcript files:** treat inferred Whisper and Parakeet text files as authoritative so empty or missing output cannot expose progress/status stdout as user speech. (#87393, #87384) Thanks @kesslerio.
- **Browser actions on Node 24:** keep browser request cancellation bound to the client and response lifetime instead of Node 24.16+'s prematurely aborted body-stream signal, preventing valid POST actions from failing after JSON parsing. Thanks @obviyus and @vincentkoc.
- **SecretRef model credentials:** keep resolved provider secrets behind process-local sentinels through auth storage, stream setup, SDK configuration, and managed local-provider probing, then inject plaintext only at the final network or provider-plugin boundary while retaining exact-value log redaction. (#102008, #102009)
- **Lean local model shell access:** keep `exec` directly visible beside the default structured Tool Search controls so coding-tuned local models can use their shell fallback instead of searching for missing domain tools. (#87587) Thanks @vincentkoc.
- **OAuth refresh contention diagnostics:** keep local lock paths out of user-facing refresh failures and avoid duplicate failure prefixes while preserving structured provider and profile classification. (#83383) Thanks @vincentkoc.
- **Exec approval prompts:** keep background-disabled fallback warnings out of pending gateway/node approvals and show them only after a command actually runs in the foreground. (#78184) Thanks @vincentkoc.
- **Direct poll delivery:** route direct and hybrid channel polls through the owning outbound adapter while preserving gateway-mode routing and channel option checks. (#99950) Thanks @NianJiuZst.
- **Agent wait hard-timeout snapshots:** preserve canonical hard-timeout phase and timestamps when the outer `agent.wait` timer wins the retry-grace race, while leaving queue, draining, and restart-cancelled waits correctable. (#89367) Thanks @Pick-cat.
- **Control UI typed approvals:** send `/approve` commands immediately through the authorized Gateway command path while an agent run is blocked instead of queueing the command behind that run. (#77672) Thanks @vincentkoc.
- **Microsoft Teams Graph response bounds:** cap successful file-upload and chat JSON reads so oversized Microsoft Graph responses cannot be buffered without limit. (#97784) Thanks @Alix-007.
- **Packaged speech runtime:** stop treating package-backed `speech-core` as a bundled plugin sidecar, restoring TTS startup in npm installs while release checks keep true activation-bypassing facades package-complete. (#89899, #89425) Thanks @zhangguiping-xydt.
- **Codex app-server protocol:** require app-server 0.142 or newer, remove pre-0.142 wire-shape compatibility, and teach Codex to retrieve deferred native `spawn_agent` through `tool_search` so native subagent task mirroring works on search-capable models. (#101221)
- **Android hardware keyboard chat:** send with unmodified Enter on physical keyboards while preserving Shift+Enter and other modified Enter combinations for multiline input. (#101239) Thanks @3ninyt3nin-creator.
- **CJK Markdown emphasis:** render adjacent Chinese, Japanese, and Korean emphasis punctuation through the shared Markdown pipeline instead of leaking literal markers across channels. (#101230, #101120) Thanks @nicknmorty.
- **Backup retry cleanup:** close partial archive output handles and isolate each retry path after live-write failures, preventing Windows `EBUSY` locks from cascading across attempts or leaving stale temp archives. (#101397, #101449) Thanks @ZOOWH and @LiLan0125.
- **Codex yielded native subagents:** keep the parent app-server subscription and shared client alive until yielded native subagent completion delivery settles, preventing lost wakeups and leaked one-shot cleanup.
- **Delivery recovery pacing:** pace eligible outbound and restart-continuation replays after gateway startup so outage backlogs do not burst into channel rate limits, while preserving the wall-clock recovery budget. (#101118, #101058) Thanks @ZengWen-DT.
- **Outbound pre-connect recovery:** clear stale platform-send evidence atomically when a connect or DNS failure proves no request was sent, allowing queued Discord and other channel messages to replay after connectivity returns without weakening the unknown-send duplicate guard. (#101024, #100979) Thanks @SunnyShu0925.
- **Discord streamed finals:** send completion replies as fresh messages so inactive channels become unread, while preserving targeted mentions without escalating `@everyone` or `@here`. (#99711, #99662) Thanks @davelutztx.
- **OpenAI-compatible SSE parsing:** recognize event streams mislabeled as JSON without prepending a second `data:` prefix, preserving valid streamed responses from non-conforming providers. (#96503) Thanks @ZengWen-DT.
- **LM Studio embedding preload:** honor model- and provider-level context-window limits when preloading embedding models, preventing avoidable GPU out-of-memory failures. (#100750) Thanks @zak-li, @ZOOWH, and @hxz398.
- **Provider overload messaging:** keep rate-limited responses classified for retry and fallback behavior while using overload wording when the provider supplies no explicit retry detail. (#98165) Thanks @SunnyShu0925.
- **Microsoft Teams attachment metadata:** bound Bot Framework `attachmentInfo` JSON reads and cancel oversized streams before they can exhaust Gateway memory. (#99125) Thanks @ly85206559.
- **Agent auth copy order:** preserve the source agent's portable auth-profile precedence when copying credentials to a new agent while excluding skipped profiles and transient auth state. (#100833) Thanks @machine3at.
- **Memory session repair:** keep daily dreaming ingestion bookkeeping outside session-corpus audit and repair so `memory status --fix` preserves healthy daily state. (#93389) Thanks @Alix-007 and @vincentkoc.
- **Remote browser CDP policy:** allow the configured CDP control host through an existing hostname allowlist without widening page navigation policy, while keeping strict-policy discovery bound to the configured control authority. (#100986, #100819) Thanks @NianJiuZst.
- **Config unset diagnostics:** explain when an inherited or default configuration value cannot be unset instead of reporting a misleading successful deletion. (#96557) Thanks @moeghashim.
- **Crestodian command probes:** contain stdout and stderr stream failures while keeping child-process close and spawn errors authoritative, preventing unhandled probe crashes. (#100741) Thanks @lsr911.
- **Feishu mention forwarding:** fail closed when the bot Open ID is unavailable so group messages cannot be misclassified as explicit bot mentions. (#100891) Thanks @zhangguiping-xydt.
- **Cron edit delivery:** preserve each job's implicit delivery mode when applying partial delivery updates, so disabling best-effort delivery no longer turns detached job announcements off. (#100846) Thanks @machine3at.
- **Control UI session creation:** keep newly created sessions at the front of the stable sidebar order after selecting another session. Thanks @shakkernerd.
- **Control UI file previews:** keep large Skill Workshop files responsive with cached, offscreen-contained text chunks while preserving wrapped content, stable file switching, full-file copy, and clean focus behavior. (#101319) Thanks @xianshishan and @shakkernerd.
- **FTS-only memory startup:** skip plugin capability discovery when `memorySearch.provider` is explicitly `none`, avoiding an unnecessary cold-start scan.
- **Control UI agent model labels:** show each selected agent's effective model in the Default picker option instead of the global model. (#100719, #77690, #77440) Thanks @hyspacex.
- **Control UI inbound image previews:** render canonical inbound media references through the authenticated ticket route after chat-history reloads. (#100725, #90172, #89591) Thanks @sweetcornna.
- **Small-context compaction:** cap the effective reserve against the known model context window so small local models do not enter compaction from the first token. (#100621) Thanks @vincentkoc.
- **Detail-less provider failures:** keep opaque upstream failures from cooling API-key auth profiles while preserving WHAM-backed OpenAI OAuth health checks and configured model fallback. (#100600, #100617) Thanks @fengjikui.
- **Plugin install diagnostics:** suppress the misleading hook-pack fallback after plugin install failures only when the hook manifest is absent, while preserving actionable malformed hook-pack errors. (#100554) Thanks @vincentkoc.
- **Config validation diagnostics:** emit each unchanged sanitized validation-warning payload once per config path, reset deduplication after a clean validation, and preserve the warning fingerprint across transient invalid reads and failed refreshes. (#100569, #25574) Thanks @vincentkoc.
- **Config size-drop guard:** compare writes against canonical bytes for parseable object configs instead of raw BOM and indentation overhead, while preserving raw audit telemetry and the conservative malformed-input fallback. (#100591, #71865) Thanks @vincentkoc.
- **Control UI coalesced updates:** show a clear queued-restart completion banner when an update joins an already-running Gateway restart. (#93082) Thanks @goutamadwant.
- **Control UI connection errors:** preserve structured pairing and authentication failures for pending RPC callers while keeping generic disconnect behavior unchanged. (#54758) Thanks @ruanrrn.
- **iOS embedded terminal:** open the terminal-only Control surface directly while native Gateway authentication connects instead of exposing the Web UI login screen.
- **TUI startup status:** show `starting up` during post-connect initialization without overwriting active-run or reconnect state. (#93999) Thanks @ml12580.
- **Control UI restart recovery:** recover stale bundle pages through a bounded whole-document refresh after Gateway updates or restarts. (#99111) Thanks @ZengWen-DT.
- **TUI active Gateway ports:** follow the verified active local Gateway port when no explicit URL, port, or remote target is configured. (#73338, #42461) Thanks @haishmg and @vincentkoc.
- **Apple chat run recovery:** restore active responses from canonical Gateway history after reconnects, foreground resumes, and event gaps, while preserving gateway user-turn identity across Codex and Copilot transcript mirrors to prevent duplicate rows. (#100277)
- **Claude CLI streamed replies:** preserve assistant text already received from Claude CLI when its terminal result envelope is empty, preventing false empty-response failover after a complete streamed answer. (#90450) Thanks @totobusnello.
- **Phone identity normalization:** canonicalize stray plus signs, preserve non-phone iMessage handles, and reject digit-free Signal identities across shared channel routing. (#100467) Thanks @morluto.
- **Tlon scry response bounds:** cap successful Urbit scry JSON reads and cancel oversized streams instead of buffering unbounded peer responses. (#100376) Thanks @hugenshen.
- **Source build portability:** keep tsdown configuration self-contained so builds do not depend on resolving the tsdown package from unrun's temporary module directory.
- **Agent tool-call decoding:** preserve surrogate-range numeric HTML entities as literal text while still decoding valid supplementary-plane values, preventing malformed model output from injecting lone UTF-16 surrogates into tool arguments. (#99564) Thanks @mikasa0818.
- **Gateway event dispatch:** catch and log lazy subscriber setup and handler failures instead of leaking unhandled promise rejections. (#100401) Thanks @cxbAsDev.
- **Ollama fallback routing:** classify incomplete native streams through the Ollama provider hook so configured model fallbacks can advance. (#100482) Thanks @TurboTheTurtle.
- **Diffs rendering:** render viewer and image output from one SSR preload, preserve language-pack highlighting through hydration, normalize language hints case-insensitively, skip identical before/after inputs with an explicit `changed` result, report truthful file-render and input errors, cache hash-pinned viewer runtimes, and prefer canonical file settings over stale aliases. (#100487)
- **Remote browser reliability:** bound persistent Playwright tab enumeration by the existing remote CDP timeout budget and retire timed-out connection attempts so late completions cannot restore a stuck connection. (#80147, #58968) Thanks @HemantSudarshan and @KeaneYan.
- **Browser tab adoption:** preserve the prior implicit tab and stable aliases when new MCP, Playwright, or CDP targets fail final safety validation, abort after creation, or cannot be rediscovered; validate labels before creating tabs and limit managed cleanup to adopted targets. (#105301) Thanks @hugenshen.
- **Browser attachment downloads:** return managed URL, filename, and path metadata when direct Playwright navigation starts an attachment download, while validating final URLs before saving bytes and preserving single-owner explicit downloads. (#48045, #89416) Thanks @zhangguiping-xydt.
- **Browser action downloads:** return managed URL, filename, and path metadata when agent actions trigger downloads, while preserving explicit ownership, validating final URLs before saving bytes, and quarantining policy-denied tabs without closing them. (#93250, #93307) Thanks @sunlit-deng.
- **Managed browser cookie persistence:** initialize new isolated macOS headless profiles with a non-interactive encryption key while preserving existing profile keys, and close Chromium through CDP before bounded signal fallback so persistent logins survive graceful browser and Gateway restarts. (#96704, #98284) Thanks @TurboTheTurtle.
- **MCP OAuth response bounds:** reject body-less foreign error bodies without calling their inherently unbounded `text()` fallback, while preserving HTTP status and headers for safe SDK diagnostics. (#98143) Thanks @Pick-cat.
- **Tlon image upload bounds:** cap remote image fetches before upload and fail closed on oversized or stalled responses instead of buffering them without a limit. (#100374) Thanks @hugenshen.
- **Mattermost block streaming:** preserve complete, non-duplicated text and tool blocks in draft preview mode, and honor normal block streaming when preview streaming is disabled. (#87449) Thanks @yetval.
- **Control UI approval prompts:** keep stale resolve failures and busy-state cleanup from leaking across newer approvals or Gateway reconnects. (#98394) Thanks @haruaiclone-droid.
- **macOS service SecretRefs:** preserve generated env-file values for SecretRefs that remain in config when stale Gateway LaunchAgents are repaired or reinstalled without those variables in the invoking shell. (#99124) Thanks @mushuiyu886.
- **Anthropic OAuth callbacks:** keep the provider-required `localhost` redirect URI stable while allowing the local callback listener to bind an explicit loopback host. (#96917) Thanks @xialonglee.
- **Prompt-release media delivery:** accept active-leaf-preserving side appends while an embedded run temporarily releases its session lock, so successive message-tool media replies merge without a false session-takeover failure. (#100033, #100490) Thanks @scotthuang.
- **Control UI Skills filters:** align agent and search controls, use translated labels, and preserve native checkbox and radio sizing. (#100526, #99996) Thanks @evan-YM.
- **Control UI completed-run state:** bind active and completed updates to run identities so stale completions keep Send available while newer runs remain active. (#100527, #91680) Thanks @tiffanychum.
- **Control UI context usage:** keep stale cached totals visible as approximate without triggering warning styling or Compact actions. (#89772) Thanks @bladin.
- **Control UI file previews:** remove the duplicate Escape header hint while retaining the Close-button shortcut hint and Escape behavior. (#100528, #99029) Thanks @xianshishan.
- **Control UI autonomous tool failures:** preserve an earlier Tool error outcome across later autonomous recovery turns. (#100514, #98888) Thanks @qingminglong.
- **Agent empty replies:** surface a visible failure when a completed interactive turn has no deliverable reply, including queued follow-ups, while preserving explicit silence, pending continuations, and committed side effects, honoring queued send policies, and treating compaction notices as progress. (#100456) Thanks @mushuiyu886.
- **Child process output safety:** prevent stdout/stderr pipe failures from crashing agent exec sessions, local TUI shell commands, and bounded process execution. (#100407, #100406, #100410) Thanks @cxbAsDev.
- **Docker sandbox command output:** fail and terminate Docker sandbox operations when stdout/stderr capture breaks instead of returning success with incomplete output. (#100523) Thanks @cxbAsDev.
- **Background refresh isolation:** keep remote skill-bin refreshes running when one node fails, and contain periodic subagent-sweeper failures without hiding errors from direct callers. (#100393, #100390) Thanks @cxbAsDev.
- **Skill scan diagnostics:** report directory enumeration failures through the existing resource diagnostics instead of silently dropping affected skills. (#100380) Thanks @wendy-chsy.
- **Exec output sanitization:** remove complete ANSI sequences and render residual C0/C1 controls as visible escapes instead of silently discarding output bytes. (#100327) Thanks @LavyaTandel.
- **Assistant visible text:** unwrap leaked standalone `<parameter>` tags while preserving their content and literal code/XML examples. (#100302) Thanks @nankingjing.
- **Android microphone capture:** treat negative `AudioRecord.read` results as fatal shared-session errors so both transcription and Talk capture stop cleanly after device loss. (#100028) Thanks @NianJiuZst.
- **Android push-to-talk lifecycle:** serialize gateway PTT preparation with app foreground and Manual Mic ownership so stale background or retry work cannot restart, replace, or tear down a newer capture. (#99840) Thanks @xialonglee.
- **Lean local-model tools:** trim media generation, TTS, and PDF tools from lean agent surfaces while preserving explicit config and runtime opt-ins. (#88881) Thanks @vincentkoc.
- **iOS development app identity:** keep the development app labeled Nova while using its distinct debug icon to differentiate it from release builds.
- **Android chat recovery:** preserve optimistic user messages and locally owned runs while reconnect and sequence-gap history snapshots catch up, preventing sent messages from disappearing or stale runs from taking ownership. (#100197)
- **iOS QR gateway handoff:** stop VisionKit before delivering scanned setup codes, and keep deferred auth, approval, Watch, and foreground-node work bound to its originating gateway across reconnects. (#99572) Thanks @PollyBot13.
- **Agent terminal failures:** surface a safe interactive reply when an agent run ends without visible output, while preserving completed message-tool delivery and heartbeat-specific guidance. (#99304) Thanks @moeedahmed.
- **MCP loopback tool results:** preserve schema-valid text, image, and embedded-resource content through HTTP tool calls while rendering malformed or protocol-incompatible blocks as safe text. (#100336) Thanks @tzy-17.
- **Control UI tool-result images:** render direct image content blocks from Gateway history and make the delayed-send scroll E2E setup deterministic. (#100295) Thanks @lzyyzznl.
- **Control UI live tool ordering:** keep assistant stream text before its matching tool card when browser and Gateway timestamps disagree. (#93184) Thanks @Pick-cat.
- **Plugin approval diagnostics:** distinguish request validation rejections, expired wait decisions, and unavailable Gateways while keeping approval failures fail-closed. (#100337) Thanks @tzy-17.
- **IRC Unicode messages:** split outbound PRIVMSG payloads on UTF-16 code-point boundaries so emoji cannot be cut into lone surrogates. (#96572) Thanks @llagy009.
- **OpenAI realtime voice greetings:** prevent server VAD from creating a second outbound greeting while an explicit greeting response owns the turn, without disabling caller interruption. (#86285) Thanks @giodl73-repo.
- **Realtime voice tools:** filter malformed tool names at each OpenAI, Azure, and Google realtime payload boundary while preserving provider-specific valid names. (#89175) Thanks @vincentkoc.
- **Discord voice status:** treat Discord error 10065 as a normal disconnected state while preserving unrelated REST failures. (#90969) Thanks @asock.
- **Discord voice accounts:** isolate `@discordjs/voice` connections by Discord account and recover auto-join when gateway readiness predates listener registration. (#87530) Thanks @geekhuashan.
- **iOS Voice Wake cleanup:** avoid initializing the microphone audio pipeline while disabling inactive Voice Wake, preventing simulator launch aborts and unnecessary audio setup.
- **Cron duration validation:** reject positive durations that truncate below one millisecond instead of silently scheduling a zero-duration interval. (#100311) Thanks @qingminglong.
- **Skill workshop proposals:** preserve the terminal newline in generated proposal Markdown while still rejecting blank raw content. (#100293) Thanks @anyech.
- **Agent tool inputs and LSP startup:** treat blank optional integer arguments as absent, and fail embedded LSP startup immediately when its child process cannot spawn. (#100273, #99922) Thanks @snotty and @cxbAsDev.
- **Gateway and memory diagnostics:** report failed start-session persistence and close-time memory work instead of silently discarding those failures. (#100313, #100308) Thanks @masatohoshino and @lin-hongkuan.
- **Unicode and plugin package verification:** match native slice semantics for reversed UTF-16 bounds, and reject published plugin packages that omit `nova.plugin.json`. (#100014, #99904) Thanks @Simon-XYDT and @849261680.
- **Android invoke cancellation:** preserve coroutine cancellation through camera handlers and the Gateway invoke boundary so cancelled work cannot emit a stale result. (#99916) Thanks @xialonglee.
- **Codex native hook relay diagnostics:** avoid bridge registry writes before the local relay server begins listening. (#100300) Thanks @nankingjing.
- **Voice Call completed status:** resolve finalized calls from the full retained event store across Gateway, tool, and CLI status paths while preserving active-call lookup performance. (#99797) Thanks @Darren2030.
- **Agent stop recovery:** prevent late-aborting prompts from reacquiring orphaned session locks after teardown, so `/stop` leaves the conversation ready for the next turn.
- **Message delivery status:** report failed and partially failed best-effort channel delivery instead of returning a success-shaped message-tool result. (#99928) Thanks @masatohoshino.
- **WhatsApp credential recovery:** restore malformed primary auth state from a valid backup during startup. (#99070) Thanks @LeonidasLux.
- **WhatsApp quoted replies:** preserve bot-authored outbound quote metadata so replies to those messages keep their reply bubble in WhatsApp Desktop. (#94879) Thanks @Bartok9.
- **WhatsApp reconnect catch-up:** admit recently missed Baileys `append` messages during a bounded reconnect window while preserving startup stale-history guards. (#80642) Thanks @VishalJ99.
- **WhatsApp restart recovery:** stop automatic restart loops after logged-out or connection-replaced disconnects until the account reconnects. (#78511) Thanks @openperf.
- **Local Gateway CLI auth:** keep loopback CLI token/password calls off durable device scopes so read probes cannot block later write/admin commands behind a stale pairing baseline. (#95997) Thanks @vincentkoc.
- **Plugin module identity:** keep Nova package chunks on Node's native module graph when jiti transforms plugin entries, preventing duplicate evaluation and class identity drift. (#88384) Thanks @vincentkoc.
- **Shell completion repair:** generate core-only caches during doctor and update repair while preserving full plugin command completion for onboarding and explicit user rebuilds. (#76235)
- **MCP schema diagnostics:** attribute draft-2020-12 compiler failures to the external MCP schema so malformed patterns produce actionable setup errors. Thanks @vincentkoc.
- **Windows Scheduled Task recovery:** keep clean early exits inside the existing bounded launch poll, falling back only when neither the task process nor Gateway listener becomes observable. (#76245)
- **iMessage group warnings:** suppress the false drop-all startup warning when an effective group sender allowlist can admit groups, and point true empty-allowlist configurations at the correct remedy. (#100046)
- **Control UI mobile login:** keep Gateway recovery guidance visible after connection failures, make the disconnected gate scroll safely on constrained screens, and improve mobile keyboard and tap-target behavior. (#100208)
- **TUI streaming:** render delta-only assistant events in live Gateway and embedded TUI sessions instead of waiting for the final response. (#83000) Thanks @flashosophy.
- **Model aliases:** resolve provider-qualified aliases during session and chat-command model switches without collisions when providers share a display alias. (#100209) Thanks @sahilsatralkar.
- **TUI new-session hooks:** create `/new` sessions through the shared Gateway lifecycle so command and session hooks receive the completed parent transcript in both Gateway and embedded modes, while preventing rollover during an active turn. (#100241, #49918) Thanks @BingqingLyu.
- **TUI abort diagnostics:** show sanitized tool argument-validation summaries for aborted runs in both Gateway and local TUI modes without exposing raw model arguments. (#91002) Thanks @wsyjh8.
- **iOS Watch replies:** persist queued quick replies in the gateway-scoped chat outbox and submit them through idempotent chat delivery, preventing losses, duplicates, and cross-gateway sends after reconnects. (#100031) Thanks @NianJiuZst.
- **iOS Gateway auth retry:** restrict stored device-token retry to parsed loopback hosts and reject wildcard bind addresses, preventing remote lookalike hostnames from receiving trusted retry credentials. (#99859) Thanks @ly85206559.
- **Amazon Bedrock control-plane deadlines:** bound model discovery and application inference-profile lookups, preserve caller cancellation, and close short-lived SDK clients after each request path. Thanks @Alix-007.
- **Bedrock Mantle discovery:** bound model-catalog fetch time and response size, and release rejected response bodies so stalled, oversized, or failed provider responses fall back safely. (#99961) Thanks @zhangguiping-xydt.
- **Discord thread-title prompts:** truncate generated-title message and channel context on UTF-16 boundaries so emoji cannot leave malformed model prompt text. (#101551) Thanks @Alix-007.
- **Task state migration:** canonicalize legacy `not-requested` delivery statuses during sidecar import and existing shared-database open so upgraded task registries and linked TaskFlows recover without manual SQL, and surface rejected persisted values in compact console diagnostics. (#103946) Thanks @bek91.
- **Reply pre-delivery recovery:** bound each pre-delivery callback with an owner-overridable deadline, release serialized reply lanes after hung plugin work, and preserve durable final-delivery retry state only when transport never started. (#104256) Thanks @NianJiuZst.
- **Signal native quote replies:** preserve the active inbound message as a native quote across agent, explicit, durable, and chunked sends while keeping reply-mode policy inside the Signal plugin. (#105347) Thanks @jesse-merhi.
- **Media-store remote downloads:** bound response-header waits and stalled bodies, close abandoned redirect and error responses, and remove partial temp files so hung sources cannot pin callers. (#104624) Thanks @hugenshen.
- **Cron llama.cpp tool schemas:** keep the model-facing cron declaration schema compatible with llama.cpp while retaining gateway and runtime nonblank validation. Fixes #107449. (#108360) Thanks @lee-xydt.

## 2026.7.1

Nova v2026.7.1 brings major Control UI and onboarding overhauls, major updates to the official iOS, Android, and macOS apps, expanded model and provider support including GPT-5.6 compatibility, Tencent Hy3, and Meta Muse Spark 1.1, and stronger Codex and connected coding-agent workflows. Telegram, Slack, Discord, and Apple Messages each receive substantial updates, while Gateway crash loops, scheduled work, remote browser control, workspace terminals, sessions, and goals also improve. There are also many general fixes and refinements throughout Nova.

[Full release notes](https://docs.nova.ai/releases/2026.7.1)

### Highlights

#### Control UI

The [Control UI](https://docs.nova.ai/web/control-ui) now works more like one browser workspace for conversations and parallel work. Chats receive clearer titles, recent sessions are easier to find, pin, group, rename, fork, archive, and mark read, and multiple sessions can sit in resizable panes that return after a reload. Drag-and-drop placement, a denser Sessions page, and a live Tasks view make it easier to move between active work without juggling browser tabs.

Chat controls are clearer while work is in progress. The composer keeps attachments, model choice, voice, reasoning, send and stop state, and message actions usable across screen sizes; Talk users can choose or refresh a microphone from settings and get readable permission guidance on narrow screens; quoted replies preserve the point being answered; and compact tool rows keep inputs, results, images, progress, errors, approvals, and steering available without overwhelming the conversation.

Usage information is easier to understand from both [status views](https://docs.nova.ai/cli/status) and the browser. The Usage page compares recent estimated spend and daily values without repeated reloads or hovering, shows each provider, model, agent, or channel's share, and can include provider-reported plans, quotas, balances, budgets, and Anthropic or OpenAI billing details. Seven-, thirty-, and ninety-day charts now keep zero-activity days visible, large all-agent reports limit concurrent work to reduce slowdowns and memory pressure, and chat-level context panels and completed-message details show the active model, tokens, cache use, context pressure, and estimated cost.

Mobile pairing, Gateway health, desktop-node approvals, linked GitHub work, workspace files, scheduled jobs, worktrees, Workboard items, and background tasks are now available closer to the conversation. Their status, permissions, and next steps are also clearer.

The rework also strengthens the paths underneath those controls. Dashboard connects and reconnects use less temporary Gateway memory, reducing false pressure warnings, while temporary Gateway restarts and stale assets recover more cleanly. Path-routed Gateways keep the right destination and credentials, saved choices survive refreshes, and authentication, protocol, update, and pairing failures show more useful next steps instead of leaving the page stuck or ambiguous.

Responsive layouts keep chat history and controls usable on phones, tablets, short landscape screens, and large desktops. Keyboard and focus behavior, contrast, assistive labels, copying, scrolling, and touch targets are more consistent, while navigation, pairing, voice, schedule, and status text reaches more supported languages.

- New Control UI chats now receive concise sidebar titles from their first message, and operators can route dashboard, Telegram topic, and Discord thread title generation through a smaller `utilityModel`. [#87643](https://github.com/nova/nova/pull/87643) Thanks @juliangsm, @zhangguiping-xydt.
- Paired administrators can now create a mobile setup QR or copyable code from Control UI Nodes and use it to connect an official iOS or Android app. [#94672](https://github.com/nova/nova/pull/94672) Thanks @bkudiess, @douhualili.
- Control UI now makes conversations easier to create, find, and switch from a populated session sidebar, while keeping context pressure and provider quota information close at hand. [#99289](https://github.com/nova/nova/pull/99289) Related [#99288](https://github.com/nova/nova/issues/99288).
- The Control UI sidebar now focuses on sessions and a few default destinations while letting users pin their preferred pages and keep those choices across reloads. [#100296](https://github.com/nova/nova/pull/100296)
- The redesigned Control UI composer keeps attachments, provider and model selection, voice, run state, and message actions clearer and more stable across mobile and desktop layouts. [#100461](https://github.com/nova/nova/pull/100461) Thanks @fuller-stack-dev.
- Control UI Talk users can choose and refresh a microphone on narrow screens and read clear permission guidance when browser access is blocked. [#101377](https://github.com/nova/nova/pull/101377) Thanks @fuller-stack-dev.
- Control UI chat can now show multiple resizable sessions side by side or stacked, preserve the pane layout across reloads, and keep the active pane usable on narrow screens. [#100754](https://github.com/nova/nova/pull/100754)
- The Control UI now has a live Tasks page where operators can inspect active and recent background work, open its session, refresh details, and cancel queued or running tasks when authorized. [#100789](https://github.com/nova/nova/pull/100789)
- Session lists across web and mobile now support pinned and custom groups, shared read and unread status, background-output indicators, transcript forking, and in-place rename, archive, move, and delete actions. [#100814](https://github.com/nova/nova/pull/100814)
- The Control UI Sessions page now fits more useful status and actions on a typical screen, with row details opening to reveal labels, tuning controls, and checkpoint history instead of forcing routine sideways scrolling. [#100943](https://github.com/nova/nova/pull/100943)
- Control UI users can drag a session directly into the current pane or onto any side to create a split, with a preview showing where it will land. [#101191](https://github.com/nova/nova/pull/101191)
- Operators can configure token or full per-reply usage footers once with `messages.responseUsage`, while users can turn them off or reset a session to the inherited default. [#89762](https://github.com/nova/nova/pull/89762) Thanks @marvinthebored, @obviyus, @peetiegonzalez.
- The Control UI Usage page now makes recent estimated costs, daily values, and each provider, model, agent, or channel's share easier to compare without repeated reloads or hovering. [#100432](https://github.com/nova/nova/pull/100432)
- The Usage page now shows provider-reported plans, quotas, reset times, balances, spending, and budgets alongside Nova session analysis, including OpenRouter and Venice coverage. [#100520](https://github.com/nova/nova/pull/100520)
- Control UI Usage can now show Anthropic and OpenAI daily spend, tokens, requests, top models, and billing categories for today, seven days, and thirty days when admin credentials are configured. [#100672](https://github.com/nova/nova/pull/100672)
- Daily token and cost charts now include zero-activity days across bounded date ranges, so 7-day, 30-day, and 90-day views show the full calendar period instead of shrinking around active days. [#81467](https://github.com/nova/nova/pull/81467) Thanks @adapepper.
- All-agent cost reports on large installations now limit concurrent Gateway work so the dashboard is less likely to slow down, time out, or add memory pressure. [#101589](https://github.com/nova/nova/pull/101589) Thanks @vincentkoc, @zw-xysk.
- Hovering or keyboard-focusing a public GitHub issue or pull request in Control UI chat now previews its status, title, author, activity, comments, and change size without leaving the conversation. [#100434](https://github.com/nova/nova/pull/100434)
- File paths in Control UI chats are now clickable, opening a searchable syntax-highlighted preview at the cited line with options to reveal, copy, or open the file in a supported editor. [#100679](https://github.com/nova/nova/pull/100679)
- Control UI connection failures now show actionable messages such as "Pairing required" instead of replacing them with a generic gateway disconnect. [#54758](https://github.com/nova/nova/pull/54758) Thanks @ruanrrn.
- Control UI sessions using full verbose output now open tool inputs and results by default, reducing repeated clicks during debugging and review. [#74398](https://github.com/nova/nova/pull/74398) Thanks @samrusani.
- The Control UI context indicator now remains visible with an approximate cached total while a response is active, without using stale data for urgent warnings or the Compact action. [#89772](https://github.com/nova/nova/pull/89772) Thanks @bladin.
- Control UI and WebChat no longer let a non-terminal internal tool failure dominate the transcript with a red error banner after the assistant has already produced a normal final answer. [#90122](https://github.com/nova/nova/pull/90122) Thanks @harjothkhara.
- A default agent selected in the Control UI now remains selected after refresh without saving unrelated unfinished settings. [#91457](https://github.com/nova/nova/pull/91457) Thanks @zengwen-dt.
- Segmented streaming replies in Control UI WebChat now stay under one assistant avatar and footer instead of appearing as several separate responses. [#92063](https://github.com/nova/nova/pull/92063) Related [#63956](https://github.com/nova/nova/issues/63956). Thanks @contentfree, @harjothkhara.
- Dashboard WebChat users can right-click a completed message and reply with visible quote context instead of manually copying and formatting it. [#92654](https://github.com/nova/nova/pull/92654) Thanks @programmingwtf, @vincentkoc.
- After an update installs, the Control UI now says when a Gateway restart is already in progress instead of making the Update button appear unresponsive. [#93082](https://github.com/nova/nova/pull/93082) Thanks @goutamadwant.
- Live tool-using replies in Control UI WebChat now keep the assistant's introduction ahead of the tool card, even when browser and Gateway clocks differ. [#93184](https://github.com/nova/nova/pull/93184) Thanks @pick-cat.
- Control UI Quick Create now lets users choose a model for an agent-turn cron job and shows whether existing jobs use that model or the default. [#95341](https://github.com/nova/nova/pull/95341) Thanks @ly85206559.
- Control UI WebChat can now show Codex preamble and commentary while tools are running, with a choice to hide or retain that progress after the final answer. [#95708](https://github.com/nova/nova/pull/95708) Thanks @obviyus, @ragesaq.
- Long reply IDs containing emoji or other supplementary characters now remain valid when shortened for WebChat and Gateway reply directives instead of being cut into malformed text. [#96938](https://github.com/nova/nova/pull/96938) Thanks @ly-wang19.
- Long tool activity details now remain readable when shortened for chat, UI, or logs, even when an emoji or other supplementary character falls at the cutoff. [#96958](https://github.com/nova/nova/pull/96958) Thanks @bartok9, @ly-wang19, @vincentkoc.
- WebChat now shows long provider and model names together with the selected reasoning level in the composer, while narrow screens retain a sensible overflow limit. [#96990](https://github.com/nova/nova/pull/96990) Thanks @maweibin, @xiayingren123.
- Agents can use targetless `message.send` for progress or intermediate updates in the current WebChat without an explicit destination. [#97167](https://github.com/nova/nova/pull/97167) Related [#96840](https://github.com/nova/nova/issues/96840). Thanks @mantiscartography, @zhangguiping-xydt.
- New Control UI chats now use the selected model's current context window instead of inheriting an outdated, smaller limit from a parent session. [#97332](https://github.com/nova/nova/pull/97332) Thanks @galiniliev.
- WebChat stays on the newest reply when assistant audio or video finishes loading, while respecting readers who intentionally scrolled upward. [#97575](https://github.com/nova/nova/pull/97575) Thanks @turbotheturtle.
- Control UI pages for multiple Gateways on one domain now stay connected to the Gateway named by their path instead of reusing a sibling page's saved destination. [#97665](https://github.com/nova/nova/pull/97665) Thanks @alix-007.
- `/pair qr` now delivers a scannable code in Telegram and Control UI or a readable code in the TUI without storing the one-time setup secret in chat history. [#97933](https://github.com/nova/nova/pull/97933) Thanks @joshavant.
- Expired `/pair qr` cards in Control UI now clearly say the code is unusable and direct users to generate a fresh one. [#98049](https://github.com/nova/nova/pull/98049) Related [#98039](https://github.com/nova/nova/issues/98039). Thanks @ooiuuii.
- Expired mobile-pairing codes now explain how to run `/pair qr` again in the selected language. Sources: [bb4afe4](https://github.com/nova/nova/commit/bb4afe40ae6dbd1c711d22cdaee0b36cf404e5f8), [da9308d](https://github.com/nova/nova/commit/da9308ddb73113b54c860eafe8d8c2a81b860e41), [dfaec18](https://github.com/nova/nova/commit/dfaec1888d7ab3f5464ddd5a4a0b6f9fa9cfdb68), [6b7986e](https://github.com/nova/nova/commit/6b7986e14e00978e4a0b30faf324b3a21f35c717), [21af6e7](https://github.com/nova/nova/commit/21af6e7b19bfcea5da47316bac973eeb2d211ce8), [4e62124](https://github.com/nova/nova/commit/4e621240e8da1783657b87ea0c53a750274ea377), [6cd0106](https://github.com/nova/nova/commit/6cd0106bbc20b9d42a3d714f09e3ced3607fb208), [a72a641](https://github.com/nova/nova/commit/a72a64136ea047a05a0558f41760b57480ae5e5e), [a143ae4](https://github.com/nova/nova/commit/a143ae4e7dfea84b209948cd26044b8d8aec77e3), [cd30b1c](https://github.com/nova/nova/commit/cd30b1c3eeef9eb1b20b858aebb805698cded6f2), [f69e27a](https://github.com/nova/nova/commit/f69e27afa2b4fb99e169c51a49f39c3fb7e09c21), [ccddbee](https://github.com/nova/nova/commit/ccddbeea6a104fdf292a9d6ba2e8cca60dd21631), [9ed03df](https://github.com/nova/nova/commit/9ed03df44d812ccb14b2e69897be7e3209b65770), [f84243f](https://github.com/nova/nova/commit/f84243fe3fb4d83adb97e88baf607329ab9e9aa2), [3d06ee9](https://github.com/nova/nova/commit/3d06ee9ed78e946cc02d5b7af9e974c331e60e96), [9bd071e](https://github.com/nova/nova/commit/9bd071ead3d14e533e619acac075dba2c40bc9ec), [405b7a5](https://github.com/nova/nova/commit/405b7a52c159f996fc9a7dfc3bc899e2f3411ba0), [1a160ce](https://github.com/nova/nova/commit/1a160cec093e48141912e8b2f92a5c5ea007e6b5).
- Control UI now shows channel-triggered agent runs as in progress, so users can tell that messages from channels such as Weixin are actively being handled. [#98257](https://github.com/nova/nova/pull/98257) Thanks @scotthuang.
- The Control UI workspace rail now gives long Project files lists their own scrollbar so files remain browsable without spilling off screen. [#98646](https://github.com/nova/nova/pull/98646) Related [#98566](https://github.com/nova/nova/issues/98566). Thanks @645648406-max, @wuqxuan.
- Session Workspace file paths can now be copied from Chat even when the Control UI runs over plain HTTP or another context without the standard Clipboard API. [#98764](https://github.com/nova/nova/pull/98764) Related [#98759](https://github.com/nova/nova/issues/98759). Thanks @adinballew, @zengwen-dt.
- Tool-heavy Control UI chats now use compact expandable activity rows, so commands and results take less space while full details stay one click away. [#99763](https://github.com/nova/nova/pull/99763)
- The Control UI now stays fixed during trackpad overscroll on Mac and desktop browsers while chat threads and lists continue scrolling normally. [#99830](https://github.com/nova/nova/pull/99830)
- Control UI chat is easier to scan with quieter composer controls, a Faster-to-Smarter reasoning slider, and connection status that no longer competes with persistent version text. [#99838](https://github.com/nova/nova/pull/99838) Related [#99837](https://github.com/nova/nova/issues/99837).
- Mounted deep links, Set Default, authenticated avatars, cron alerts, and Workboard scrolling now behave correctly again across the Control UI. [#100106](https://github.com/nova/nova/pull/100106)
- Administrators can now open mobile pairing from any Control UI page or Quick Settings, while non-admin operators continue to see the action disabled with an access explanation. [#100157](https://github.com/nova/nova/pull/100157)
- The Control UI now shows a ready mobile-pairing QR code immediately even when the pending-device list is slow, then adds approval requests when they arrive. [#100179](https://github.com/nova/nova/pull/100179)
- Control UI users can select and copy tool activity without toggling its row, and failed tools no longer repeat redundant error indicators. [#100199](https://github.com/nova/nova/pull/100199) Thanks @steipete-oai.
- The Gateway Dashboard login now fits and behaves better on phones and short windows, with larger touch targets, easier URL entry, and reachable recovery help. [#100208](https://github.com/nova/nova/pull/100208)
- Control UI users can organize large session lists by custom group, channel, kind, agent, or date, with persistent assignments and drag-and-drop management. [#100262](https://github.com/nova/nova/pull/100262)
- Users can open the Control UI context ring to inspect exact context use, the latest input and output token counts, and the active model without leaving chat. [#100264](https://github.com/nova/nova/pull/100264)
- Images returned by tools such as `read` now appear directly in the Control UI conversation instead of only being mentioned in text. [#100295](https://github.com/nova/nova/pull/100295) Thanks @lzyyzznl, @pandah97, @rquinones84.
- Control UI tool activity now combines matching calls and results into one consistent row, removes repeated labels and categories, and keeps inputs, outputs, previews, and real errors accessible. [#100318](https://github.com/nova/nova/pull/100318)
- The Control UI context panel now shows the latest run's estimated total cost and available input, output, cache-read, and cache-write breakdowns beside the provider and model. [#100379](https://github.com/nova/nova/pull/100379)
- The Control UI sidebar now keeps all pinned chats visible alongside nine ordinary recent chats in a more compact, conversation-focused desktop and tablet layout. [#100386](https://github.com/nova/nova/pull/100386)
- The Control UI composer now shows reasoning level clearly, keeps Talk and its settings together, and preserves usable model controls on phone and landscape layouts. [#100445](https://github.com/nova/nova/pull/100445)
- Control UI Talk now starts from a simpler composer while administrators can set durable provider, transport, timing, and reasoning defaults in Settings. [#100453](https://github.com/nova/nova/pull/100453)
- Temporary Gateway disconnects no longer replace an authenticated Control UI page with the login screen, preserving dashboard context while automatic reconnection continues. [#100479](https://github.com/nova/nova/pull/100479)
- The Control UI Cron Jobs page now uses compact summaries, clear status cues, expandable details, and an overflow menu so large job lists are faster to review. [#100646](https://github.com/nova/nova/pull/100646)
- The Control UI sidebar now keeps recent chats in place while switching, combines search entry points, supports touch session actions, and reduces unnecessary chrome. [#100648](https://github.com/nova/nova/pull/100648)
- Images received through Telegram, iMessage, and other channels now reappear inline when users revisit Control UI chat history after a reload. [#100725](https://github.com/nova/nova/pull/100725) Thanks @sweetcornna, @vergissberlin.
- The Control UI goal pill now supports pause, resume, clear, inspection, and edit preparation with live timing and token details, while command and TUI users can reword a goal without resetting its budget. [#100736](https://github.com/nova/nova/pull/100736)
- The Control UI keeps Overview, Workboard, Agents, and More visible while allowing the session list to use available height and scroll independently. [#100742](https://github.com/nova/nova/pull/100742)
- Assistant documents downloaded from the Control UI now keep recognizable original filenames instead of exposing UUID-suffixed staging names. [#100743](https://github.com/nova/nova/pull/100743)
- Copying code from a long Control UI reply now keeps the chat at the same reading position instead of jumping upward. [#100807](https://github.com/nova/nova/pull/100807) Thanks @jvlegod.
- Desktop Control UI users can choose whether Enter sends or inserts a new line, with Command+Enter or Ctrl+Enter available as the send shortcut and the choice retained for that Gateway. [#100810](https://github.com/nova/nova/pull/100810) Thanks @moomx, @vincentkoc.
- Switching Control UI chats no longer unexpectedly moves the selected session to the top, and users can choose stable creation order or recently updated order for the sidebar. [#100927](https://github.com/nova/nova/pull/100927) Thanks @shakkernerd, @vyctorbrzezowski.
- Control UI Settings now use consistent `/settings/...` paths while old bookmarks continue to work, making reloads and links more reliable on hosted or reverse-proxied installations. [#100928](https://github.com/nova/nova/pull/100928) Thanks @vyctorbrzezowski.
- Control UI navigation now places branding, search, and sidebar controls where desktop and mobile users expect them, with clearer active sessions, compact timestamps, and easier terminal access. [#101017](https://github.com/nova/nova/pull/101017) Thanks @shakkernerd, @vyctorbrzezowski.
- The Control UI sidebar collapse control now sits in the sidebar it affects instead of looking like an unrelated topbar or terminal button. [#101038](https://github.com/nova/nova/pull/101038)
- Control UI Talk users can choose the system default or any browser-visible microphone beside the Talk button and receive a clear message when a saved device is unavailable. [#101100](https://github.com/nova/nova/pull/101100)
- Sidebar session groups can now be renamed, removed without deleting sessions, created while empty, or disabled to restore one flat recent-session list. [#101117](https://github.com/nova/nova/pull/101117)
- The Control UI now shows Workboard navigation only when Workboard is enabled and presents a cleaner collapsed sidebar with clearer icons and status spacing. [#101123](https://github.com/nova/nova/pull/101123)
- The Control UI now puts search, sidebar access, theme choice, and macOS branding in clearer, more predictable locations with accurate screen-reader labels. [#101497](https://github.com/nova/nova/pull/101497)
- Temporary Gateway drops no longer push Control UI content down with a full-width banner, so the dashboard stays in place while a compact Retry notice appears. [#101812](https://github.com/nova/nova/pull/101812)
- Temporary Gateway disconnects now use a calmer, dashboard-native reconnect pill with the same Retry and accessibility behavior. [#101844](https://github.com/nova/nova/pull/101844)
- Control UI commentary settings now use the selected language across the supported translations in this release. Sources: [34badde](https://github.com/nova/nova/commit/34badde1d983c247cd6b16ad8f5b4e1f9891c0f1), [a9cb866](https://github.com/nova/nova/commit/a9cb866f62fe9c2f7c8f9a8c3ef1a23cae556781), [ce9166d](https://github.com/nova/nova/commit/ce9166d1cd8404db51004bbdd5edc95d229788c8), [6b67ada](https://github.com/nova/nova/commit/6b67ada87ad934f6dd8afbda95830381b3767247), [006c2f7](https://github.com/nova/nova/commit/006c2f7a2b28433753521f2f9f729ba0032b51ff), [6bdffa5](https://github.com/nova/nova/commit/6bdffa501bcf8eb1b3b13122b6e2e76149693f07), [b4476ab](https://github.com/nova/nova/commit/b4476ab72f9d74a946ef0cc963e4d26dab280e45), [5b5c623](https://github.com/nova/nova/commit/5b5c6237c236b79a894c6d2c1dd4d3bd7e5188f3), [1520d09](https://github.com/nova/nova/commit/1520d0980741c85407c4e2037dfd5fb9d8f9d1c4), [6140326](https://github.com/nova/nova/commit/614032676d16bf2dd98030e7925f14ad52f5618e), [75bd44a](https://github.com/nova/nova/commit/75bd44a94bfb096010273ae14935b9cd90ccc2d3), [c1aeaf9](https://github.com/nova/nova/commit/c1aeaf9287ec25428ed1e673d869e193e930ba6b), [49edc0a](https://github.com/nova/nova/commit/49edc0a8af2f06cca21cd6df2abd81a7d99a574c), [cb69ce7](https://github.com/nova/nova/commit/cb69ce7ba84f7252acd3b87653a0a91b7442f41d), [bb0af61](https://github.com/nova/nova/commit/bb0af61d20277cf91205e6fe561dc7cccfc8e969), [0dcfbb0](https://github.com/nova/nova/commit/0dcfbb09d807800585219a4363eb67438b006f40), [db73ece](https://github.com/nova/nova/commit/db73ece2de77053433a767bcc587348d5a77fef1), [21e6fc9](https://github.com/nova/nova/commit/21e6fc948b1977b5702ab4c981dacf4d0b3b6de6).
- The All Sessions sidebar label now uses the selected language across the supported Control UI translations in this release. Sources: [b2c3dc2](https://github.com/nova/nova/commit/b2c3dc2d55f8bef05f2c8107b9c9b867653aec20), [61347a5](https://github.com/nova/nova/commit/61347a5054e6c4fce8dee39509c104521b087c7e), [a2674b6](https://github.com/nova/nova/commit/a2674b6aa4333a6c37ddb3cf7a4c7f52924c37c6), [bbabad4](https://github.com/nova/nova/commit/bbabad4031c3cab4f0e685fb0fcab183520291ab), [8909289](https://github.com/nova/nova/commit/89092893fea34eefecca09076d643a5b08f62498), [22552d6](https://github.com/nova/nova/commit/22552d6e667fa8c35ff236f85d3d3e1aa66872fb), [96e3615](https://github.com/nova/nova/commit/96e361558e7367f452a2b400fc8120c3a4f6fc72), [452351c](https://github.com/nova/nova/commit/452351cc7152abdd765445a2109726e5278b153f), [5e9a62c](https://github.com/nova/nova/commit/5e9a62cc1945850b72d7944e937fef969c9f8ed1), [0a9648b](https://github.com/nova/nova/commit/0a9648ba4766e0c5da87866d6c7299bb07ede4fa), [a803589](https://github.com/nova/nova/commit/a8035892b1f04b20f1b8e687094e6e7a18dee45c), [7c30ff8](https://github.com/nova/nova/commit/7c30ff8a60896a290de07af45d0176d2e30069e5), [e3d2878](https://github.com/nova/nova/commit/e3d2878af44f7095436d6754f73431b9add676b1), [620f2e3](https://github.com/nova/nova/commit/620f2e3112016622c59350e4aaf71a0e448d0c1a), [aa0f36c](https://github.com/nova/nova/commit/aa0f36cb0632ae283493f9d01f3d9819548b5107), [c336256](https://github.com/nova/nova/commit/c336256309956b18ff4c211ab62481c6dcd59d8b), [64dd688](https://github.com/nova/nova/commit/64dd68899e6b9f8b15c9a3c533e470ba6e36d7a5), [e2ecbc8](https://github.com/nova/nova/commit/e2ecbc85b7fe30b3096f86ba9cb189fb43807850).
- The Control UI mobile-pairing flow now appears in the selected language across 18 supported locales instead of mixing localized screens with English setup text. [c78b0d5](https://github.com/nova/nova/commit/c78b0d59f5a2becf7e3e0f0bb5d470f72e8526ed)
- A failed Control UI login or Gateway connection now immediately shows the error, recovery steps, and relevant documentation link instead of hiding them in a collapsed panel. [f9e194e](https://github.com/nova/nova/commit/f9e194e4a122f0c142c23f1bc9603466add7eb03)
- The web sidebar now reliably fills pinned and overflow navigation routes, keeping destinations such as Worktrees available. [55a0012](https://github.com/nova/nova/commit/55a0012c44b52af2f22982cc85568e6e5d0df5c7) Thanks @vincentkoc.
- Non-English Control UI users now see translated cron overflow-menu and "run if due" labels, including the assistive label for more actions. [2585d6b](https://github.com/nova/nova/commit/2585d6b2e8202149576f643259c932406a6f8294)
- The Control UI microphone-access warning for realtime voice input now appears in the user's selected language. [68c85ef](https://github.com/nova/nova/commit/68c85effcd1e0a1c65673397a206e53bf7d672ac)
- The Control UI sidebar now builds cleanly with session grouping and drag-to-split behavior intact after stray merge-conflict text was removed. [0e3ce24](https://github.com/nova/nova/commit/0e3ce24cc8cd16faa78d87b12b114fcf24a42d87)
- Hindi and Russian users can now receive matching Control UI translations, and documentation operators can generate those language editions through the existing locale workflow. [689baa5](https://github.com/nova/nova/commit/689baa5c1e48be2aa31564fd5c3fd21bf4dfb754) Thanks @vincentkoc.
- During device pairing, `/ pair qr` now follows the same authorized pairing flow as `/pair qr` without starting an agent turn or disrupting the existing Control UI route. [#98262](https://github.com/nova/nova/pull/98262) Thanks @brokemac79.
- Opening or reconnecting the Control UI dashboard now uses much less temporary Gateway memory, reducing false `rss_growth` warnings while preserving requested usage totals. [#100054](https://github.com/nova/nova/pull/100054) Thanks @nianjiuzst.
- Control UI Settings now shows a remote Gateway's host identity, address, operating system, runtime, uptime, CPU load, memory, and free disk space without requiring SSH. [#100478](https://github.com/nova/nova/pull/100478)
- The Control UI now shows execution approvals for supported desktop nodes and rejects pending, unsupported, or policy-blocked requests before they reach the node. [#100505](https://github.com/nova/nova/pull/100505) Thanks @vincentkoc.
- A configured `ui.seamColor` now changes Control UI buttons, highlights, selections, and focus rings, while invalid values fall back cleanly. [#93699](https://github.com/nova/nova/pull/93699) Thanks @dennis-lynch, @goutamadwant.
- QR codes and other half-block text art in the Control UI now preserve spacing, scroll when needed, and copy with enough padding to remain usable. [#93869](https://github.com/nova/nova/pull/93869) Thanks @emg110, @vincentkoc.
- Open Control UI tabs now switch to the active build after a service-worker update, reducing stale JavaScript, CSS, and protocol mismatch errors after upgrades. [#96141](https://github.com/nova/nova/pull/96141) Thanks @andrewccctechlink, @brokemac79.
- Chat clients can now match each pending user message to its exact Gateway-confirmed message, reducing duplicate or mismatched bubbles during interleaved turns. [#96273](https://github.com/nova/nova/pull/96273) Thanks @datus1982, @wyf027.
- Clicking a cron job's History button now gives immediate feedback and scrolls directly to that job's updated run history. [#96281](https://github.com/nova/nova/pull/96281) Thanks @wyf027, @yzhong52.
- Control UI token totals near one million now display as `1.0M` instead of the confusing `1000k`. [#96298](https://github.com/nova/nova/pull/96298) Thanks @ly-wang19.
- Usage Mosaic and usage summaries now show near-million token totals as `1.0M` instead of `1000.0K`. [#96450](https://github.com/nova/nova/pull/96450) Thanks @ly-wang19.
- The Voice, Model, and Sensitivity controls in Control UI Talk settings now align consistently in one row without duplicate selected-value text disturbing the layout. [#96925](https://github.com/nova/nova/pull/96925) Thanks @evan-ym.
- Control UI approval prompts no longer inherit failures from older requests or re-enable controls while the current decision is still being processed. [#98394](https://github.com/nova/nova/pull/98394) Thanks @haruaiclone-droid.
- Control UI now stops retrying after detecting an incompatible Gateway protocol and shows the update or reload guidance needed to reconnect. [#98414](https://github.com/nova/nova/pull/98414) Thanks @haruaiclone-droid.
- On phones and other short landscape screens, the Control UI composer now scrolls within a bounded area so chat history and all composing controls remain accessible. [#98683](https://github.com/nova/nova/pull/98683) Related [#98615](https://github.com/nova/nova/issues/98615). Thanks @jin-li, @qingminglong.
- The Control UI now retries after a temporary failed load during a Gateway restart or stale-asset transition instead of remaining stuck until the page is refreshed manually. [#99111](https://github.com/nova/nova/pull/99111) Thanks @zengwen-dt.
- Large pasted PNG screenshots can now be sent through Control UI webchat without failing during attachment processing. [#99213](https://github.com/nova/nova/pull/99213) Thanks @jincheng-xydt, @vincentkoc.
- The Control UI mobile-pairing flow is now fully localized for Hindi and Russian users, from setup-code creation through pending-device management. [#100040](https://github.com/nova/nova/pull/100040)
- The Control UI workspace rail now sits flush with the window and uses less space when collapsed, removing the empty strip without overlapping chat. [#100088](https://github.com/nova/nova/pull/100088)
- Control UI chat history now hides only exact duplicate final delivery mirrors, leaving legitimate repeated sends, forwards, and distinct replies visible. [#100136](https://github.com/nova/nova/pull/100136)
- Control UI chats now leave consistent space above the first message across phones, standard desktops, and tall windows. [#100144](https://github.com/nova/nova/pull/100144) Thanks @steipete-oai.
- Control UI Settings now offers a persistent Simple/Advanced switch, cleaner Appearance controls, and a Pending label only when a Context Profile change is actually staged. [#100147](https://github.com/nova/nova/pull/100147)
- Control UI tool-call bubbles and error badges now share clean right-edge alignment, so failed activity is easier to scan on phone-sized and desktop chats. [#100163](https://github.com/nova/nova/pull/100163) Thanks @steipete-oai.
- OpenAI users now see only the supported Standard and Fast choices in the Control UI speed picker, with inherited Fast mode shown correctly. [#100190](https://github.com/nova/nova/pull/100190)
- Short drafts in the Control UI composer no longer show an unnecessary scrollbar gutter, while long drafts still scroll when needed. [#100252](https://github.com/nova/nova/pull/100252)
- Clearing a session label now removes the old name promptly from other subscribed Control UI clients without requiring a full refresh. [#100266](https://github.com/nova/nova/pull/100266)
- Desktop Control UI users can hover a shortened recent-session name to reveal its hidden tail and distinguish similar conversations without opening each one. [#100276](https://github.com/nova/nova/pull/100276)
- The expanded Control UI sidebar no longer repeats provider quota information already available in chat, Overview, and Usage views. [#100356](https://github.com/nova/nova/pull/100356) Thanks @shakkernerd.
- Completed Control UI messages now use the timestamp to open token, cache, context, cost, and model details instead of adding a separate Context control to every footer. [#100391](https://github.com/nova/nova/pull/100391) Thanks @steipete-oai.
- Autonomous session history now keeps an earlier failed cron or scheduled turn marked as an error even after a later turn succeeds or the page reloads. [#100514](https://github.com/nova/nova/pull/100514) Thanks @qingminglong.
- The Control UI Skills page now shows readable Agent and Search labels with aligned filters and correctly sized selection controls. [#100526](https://github.com/nova/nova/pull/100526) Thanks @evan-ym.
- After a Control UI reply finishes, the composer now stays on Send despite delayed completed-run state, while a real new run still switches it to Stop. [#100527](https://github.com/nova/nova/pull/100527) Thanks @tiffanychum.
- Control UI and Skill Workshop file previews now show a single Escape shortcut hint while retaining Escape-to-close behavior. [#100528](https://github.com/nova/nova/pull/100528) Thanks @xianshishan.
- Expanded Control UI tool activity no longer repeats the tool name and icon, making completed and in-progress calls quicker to scan. [#100606](https://github.com/nova/nova/pull/100606)
- Clearing a Control UI session model override now shows the selected agent's own default model rather than the unrelated global default. [#100719](https://github.com/nova/nova/pull/100719) Thanks @hyspacex.
- Assistant-sent documents in WebChat now download with their original server-provided filename, including Unicode names, instead of opening as an unnamed browser document. [#100728](https://github.com/nova/nova/pull/100728) Thanks @lptrichor.
- The Control UI now accepts `/steer` guidance during an active run instead of incorrectly replying `No active run`. [#100803](https://github.com/nova/nova/pull/100803) Thanks @hackerismydream.
- New Control UI sessions now stay visible at the front of the sidebar after users switch to another chat, without requiring a page refresh. [#100981](https://github.com/nova/nova/pull/100981) Thanks @shakkernerd.
- Worktrees management now lives under Control UI Settings instead of occupying a top-level sidebar item, while existing deep links remain valid. [#100995](https://github.com/nova/nova/pull/100995)
- Long `/btw` answers in the desktop Control UI now stay within the browser window and scroll inside the result card, while mobile retains full-card scrolling. [#101169](https://github.com/nova/nova/pull/101169) Thanks @snoutfirst.
- Finished chats no longer remain stuck with a busy spinner in the Control UI sidebar, even when an older Gateway update arrives afterward. [#101293](https://github.com/nova/nova/pull/101293) Thanks @fuller-stack-dev.
- Large Skill Workshop support files now scroll, switch, filter, wrap, and copy without freezing or severely slowing the Control UI. [#101319](https://github.com/nova/nova/pull/101319) Thanks @shakkernerd, @xianshishan.
- Users can stay signed in to multiple path- or query-routed Control UI gateways on one HTTPS origin without one gateway overwriting another's device token. [#101352](https://github.com/nova/nova/pull/101352) Thanks @fuller-stack-dev.
- Control UI users can type `/approve` to release a waiting exec prompt without the decision getting queued behind the blocked chat run. [#101532](https://github.com/nova/nova/pull/101532) Thanks @vincentkoc.
- Control UI build errors now keep emoji and other supplementary characters intact when command output is shortened for display. [#101591](https://github.com/nova/nova/pull/101591) Thanks @maweibin.
- Workboard cards can now be edited, moved, archived, stopped, opened, or deleted directly from the detail drawer, while read-only viewers still see no mutation controls. [#101658](https://github.com/nova/nova/pull/101658) Thanks @momothemage, @princebansal.
- The Control UI microphone button is now visually quieter while idle and more distinct while recording, making the current voice state easier to recognize. [#101843](https://github.com/nova/nova/pull/101843)
- Users with saved working dashboard credentials no longer see the login screen flash briefly while Control UI reconnects. [#101849](https://github.com/nova/nova/pull/101849)
- Typing anywhere in the active Control UI chat now places the first character in the message composer without stealing input from the command palette. [#102210](https://github.com/nova/nova/pull/102210) Thanks @shakkernerd.

#### Setup and onboarding

[Onboarding](https://docs.nova.ai/cli/onboard) now offers clearer paths to a usable first chat. Fresh CLI installs enter guided setup, configured installs open the TUI, and conversational Crestodian setup remains optional. Android and macOS guide users through [pairing](https://docs.nova.ai/channels/pairing), permissions, local or remote setup, and recovery; macOS can also test detected Claude Code, Codex, Gemini CLI, API-key, and supported provider-catalog choices before saving them. Interrupted authentication or channel setup retains earlier choices, while users without a working model are guided through credential and model selection instead of being sent into an unusable chat. Owners and administrators can also renew an expired Codex or OpenAI login through private Telegram, Web UI, Discord, or Slack commands without SSH access.

Existing installations receive safeguards before their working state is changed. [Doctor](https://docs.nova.ai/cli/doctor) and updates refuse to replace an unreadable configuration, Doctor preserves model tuning while merging retired entries, and [extended-stable updates](https://docs.nova.ai/install/updating) retain the selected release channel. Container upgrades complete migrations and plugin repairs before reporting readiness, and unsafe runtimes are stopped before they can open Nova state databases.

- `nova doctor` and updates now refuse to replace an unreadable `nova.json`, preserving existing Gateway, agent, channel, and plugin settings instead of breaking the installation. [#96469](https://github.com/nova/nova/pull/96469) Thanks @obviyus, @yetval.
- `nova doctor --fix` now preserves aliases, parameters, streaming choices, runtime settings, and other model tuning when several retired model names merge into one current model, and reports any merge conflicts accurately. [#96544](https://github.com/nova/nova/pull/96544) Thanks @vincentkoc, @yetval.
- Owners and admins can now restore an expired Codex or OpenAI login from a browser through private Telegram, Web UI, Discord, or Slack commands without SSH access. [#98006](https://github.com/nova/nova/pull/98006) Thanks @100yenadmin, @jalehman, @obviyus.
- The CLI now guides fresh installs through setup, opens configured installs directly in the TUI, preserves existing choices on reruns, and finishes onboarding in a usable terminal chat. [#98218](https://github.com/nova/nova/pull/98218) Thanks @fuller-stack-dev.
- Package installs can now select and retain `nova update --channel extended-stable`, inspect its availability, and fail safely if its npm metadata is incomplete. [#99811](https://github.com/nova/nova/pull/99811) Thanks @kevinslin.
- Fresh installs can now complete conversational Crestodian setup, approve the proposed plan once, connect channels, and continue into the normal agent while classic and scripted onboarding remain available. [#99935](https://github.com/nova/nova/pull/99935)
- First-time onboarding now preserves earlier choices after authentication or pairing trouble and gives users an actionable model-configuration next step instead of opening an unusable first chat. [#100632](https://github.com/nova/nova/pull/100632)
- Container upgrades now finish required migrations and plugin repairs before reporting the Gateway ready, and failed repairs stop with actionable guidance instead of leaving a false-green service. [#101881](https://github.com/nova/nova/pull/101881) Thanks @sallyom.
- Crestodian setup now guides users who lack a usable model provider through masked credential entry and model selection, while deterministic setup and repair commands remain available until inference is configured. [#101887](https://github.com/nova/nova/pull/101887) Thanks @fuller-stack-dev.
- Nova now blocks unsafe runtimes before they can open SQLite-backed state, guides legacy Bun services to Node, and selects a WAL-safe Node runtime during setup and repair. [#106065](https://github.com/nova/nova/pull/106065) Thanks @vincentkoc.

#### Official apps

The official [iOS](https://docs.nova.ai/platforms/ios), [Android](https://docs.nova.ai/platforms/android), and [macOS](https://docs.nova.ai/platforms/macos) apps received substantial updates across setup, navigation, chat, voice, permissions, localization, files, scheduled work, native session controls, and Gateway recovery. Recent conversations remain useful through temporary disconnects: cached sessions and transcripts stay available for reading, supported text sends can wait for reconnection in the correct chat, and long conversations are easier to resume without losing the current place or mistaking an offline view for live history.

These improvements also bring the native clients closer together. Mobile queues survive app restarts, the [macOS](https://docs.nova.ai/platforms/macos) app gains fuller session and transcript tools, and each client refreshes the same conversation when the Gateway returns.

##### iOS and Android

- iOS and Android chats now preserve the reader's scroll position as new messages and tool activity arrive, with a clear way to return to the latest reply. [#98258](https://github.com/nova/nova/pull/98258) Related [#98255](https://github.com/nova/nova/issues/98255). Thanks @christopheraaronhogg.

##### iOS and iPadOS

- iPhone and iPad chat now opens with the last known conversation and lets users browse recent cached sessions while the Gateway is unavailable. [#100219](https://github.com/nova/nova/pull/100219)
- iOS users can queue chat messages while disconnected, keep them through app restarts, and send them in order after reconnection with clear retry and delete controls. [#100331](https://github.com/nova/nova/pull/100331)

##### Android

- Android chat now shows the last known transcript immediately and keeps recent cached conversations readable during a Gateway outage, then refreshes them after reconnection. [#100227](https://github.com/nova/nova/pull/100227)
- Android users can queue text while the Gateway is offline, keep it through an app restart, and send it in order after reconnection with Retry and Delete controls for failures. [#100290](https://github.com/nova/nova/pull/100290)

##### macOS

- Mac chat now restores recent sessions and transcripts immediately, remains browsable while disconnected, and queues offline sends for the correct Gateway identity. [#100275](https://github.com/nova/nova/pull/100275)
- The native macOS chat window now provides a full session sidebar, real new-session creation, slash-command completion, context and cost visibility, message copying, transcript export, and compact or clear-history actions. [#101103](https://github.com/nova/nova/pull/101103)

#### Models and providers

Nova [model selection](https://docs.nova.ai/concepts/models) expands across major hosted, managed, and local choices. Each supported [provider route](https://docs.nova.ai/concepts/model-providers) retains its own authentication, model limits, reasoning controls, tool behavior, image support, and usage reporting.

##### GPT-5.6 and Codex

Organizations with GPT-5.6 preview access can select Sol, Terra, or Luna through supported OpenAI and Codex routes with the expected context metadata, text and image input, reasoning levels, and cache-write accounting when OpenAI supplies it. Fresh OpenAI API-key and ChatGPT/Codex setups choose their intended GPT-5.6 defaults without replacing an explicit model choice. Supported Ultra choices remain aligned across Nova and native Codex, and [Codex supervision](https://docs.nova.ai/plugins/codex-supervision) records native Codex child agents as tasks and returns their results to the parent.

- GPT-5.6 users can now select supported Ultra modes consistently, keep model and thinking choices aligned across Nova surfaces, and receive native Codex child-agent results as tracked tasks. [#98021](https://github.com/nova/nova/pull/98021) Thanks @anyech.
- Organizations with GPT-5.6 preview access can select Sol, Terra, or Luna across supported OpenAI and Codex paths with correct reasoning controls, context metadata, and cache-write accounting. [#98333](https://github.com/nova/nova/pull/98333) Related [#98296](https://github.com/nova/nova/issues/98296). Thanks @steipete-oai.
- Legacy-state upgrades no longer stall repeatedly, while fresh OpenAI and ChatGPT/Codex setups select the intended GPT-5.6 defaults and use supported temperature and tool-call behavior. [#104656](https://github.com/nova/nova/pull/104656) Thanks @bdjben, @obviyus, @sallyom.

##### Tencent Hy3

Tencent Hunyuan Hy3 now has a complete setup path through TokenHub or TokenPlan, including first-class authentication choices, CLI onboarding, model discovery, and configuration validation. Existing TokenHub configurations retain access to `hy3-preview` alongside the stable `hy3` model.

- Tencent Hunyuan Hy3 now has a complete supported Nova setup path through TokenHub or TokenPlan, including first-class authentication, model discovery, configuration validation, CLI onboarding, and compatibility for existing `hy3-preview` setups. [#99076](https://github.com/nova/nova/pull/99076) Thanks @moncac.

##### Meta Model API and Muse Spark 1.1

Operators can configure Meta Model API with `MODEL_API_KEY` or the onboarding authentication choice, select `meta-model-api/muse-spark-1.1`, and use supported streaming, tool calling, image input, and reasoning-effort controls.

- Nova now supports Meta Model API setup and the Muse Spark 1.1 model, including streaming, tool calling, image input, and supported reasoning controls. [#102873](https://github.com/nova/nova/pull/102873) Thanks @davemorin, @hamidshojanazeri, @jalehman, @solvely-colin.

##### Claude models

Claude Sonnet 5 is selectable through direct Anthropic, Claude CLI, supported Vertex regions, Bedrock inference profiles, and Bedrock Mantle with its documented context, output, image, thinking, and pricing behavior. Users with Claude Mythos 5 access can select it through supported Anthropic-family routes with its required context, output, adaptive-thinking, caching, and replay behavior.

- Claude Sonnet 5 is now selectable across Anthropic, Claude CLI, supported Vertex regions, Bedrock inference profiles, and Bedrock Mantle with its documented context, output, image, thinking, and pricing behavior. [#98254](https://github.com/nova/nova/pull/98254) Thanks @vortexnova.
- Users with Claude Mythos 5 access can select it through Anthropic, Anthropic Vertex, Amazon Bedrock, or Bedrock Mantle with its required context, output, thinking, caching, and replay behavior. [#101238](https://github.com/nova/nova/pull/101238) Thanks @vincentkoc.

##### More provider options

Copilot sessions can explicitly use supported custom OpenAI, Azure OpenAI, Ollama-compatible, or Anthropic providers and start a compatible session when connection or credential settings change. Paired computers can run short tasks on eligible local Ollama models, while ClawRouter can expose the models granted to one managed key and report their usage and budget. Users can also claim active promotional models without replacing existing defaults, install LongCat-2.0 through its official provider, and continue Gemini latest tool-calling conversations across both supported Google transports.

- Copilot sessions can now use explicitly selected custom OpenAI, Azure OpenAI, Ollama-compatible, or Anthropic providers and restart cleanly when model, endpoint, credentials, headers, or token limits change. [#96345](https://github.com/nova/nova/pull/96345) Thanks @vincentkoc.
- Nova agents can now run short tasks on chat-capable Ollama models installed on paired macOS, Linux, or Windows nodes, with a separate control for disabling node inference. [#99234](https://github.com/nova/nova/pull/99234) Related [#99228](https://github.com/nova/nova/issues/99228).
- A single `CLAWROUTER_API_KEY` can now expose only its granted models across supported transports and show managed requests, tokens, spend, and monthly budget in normal status views. [#99658](https://github.com/nova/nova/pull/99658) Related [#99657](https://github.com/nova/nova/issues/99657).
- Users can discover active promotional models and claim them with `nova promos claim &lt;slug&gt;` without rerunning onboarding or unexpectedly replacing existing defaults and credentials. [#100236](https://github.com/nova/nova/pull/100236) Thanks @fuller-stack-dev.
- Hosted LongCat-2.0 can now be installed through the official LongCat plugin, configured with `LONGCAT_API_KEY` during onboarding, and selected as `longcat/LongCat-2.0` for multi-turn tool use. [#100501](https://github.com/nova/nova/pull/100501) Thanks @vincentkoc.
- Gemini latest aliases now continue tool-calling conversations across both supported Google transports instead of stopping with a missing-thought-signature HTTP 400. [#100605](https://github.com/nova/nova/pull/100605) Thanks @chenxiaoyu209, @guarismo.

#### Coding agents

Nova now works more cleanly with coding agents that live outside the current chat. `nova attach` can open Claude Code against the main or a selected Gateway session with temporary, revocable access instead of process-wide credentials. Codex app-server sessions can resume, delegate to native subagents, and return their results as tracked work, while Copilot sessions can use explicitly selected custom providers and restart when their connection settings change.

The surrounding session workflow is more durable too. Important conversations can be pinned, renamed, archived, restored, and monitored as ongoing work, while active goals remain part of working memory across later turns, compaction, queues, and interruptions.

- External tools can now receive session-scoped Gateway access without process-wide credentials or permission to impersonate another session, forming the secure base for `nova attach`. [#96351](https://github.com/nova/nova/pull/96351) Thanks @anagnorisis2peripeteia, @obviyus.
- `nova attach` now launches Claude Code with temporary access to the main or selected Gateway session, keeps credentials out of arguments, and revokes the grant when the session ends. [#96454](https://github.com/nova/nova/pull/96454) Thanks @anagnorisis2peripeteia, @obviyus.
- GPT-5.6 users can now select supported Ultra modes consistently, keep model and thinking choices aligned across Nova surfaces, and receive native Codex child-agent results as tracked tasks. [#98021](https://github.com/nova/nova/pull/98021) Thanks @anyech.
- Codex app-server agents can again list allowed agents, spawn Nova or connected subagents, and yield during delegated work without resumed heartbeats hitting incompatible tool definitions. [#99561](https://github.com/nova/nova/pull/99561) Related [#99464](https://github.com/nova/nova/issues/99464). Thanks @100yenadmin, @joshavant.
- Codex-native delegation from Nova threads now creates native task records again, while unsupported custom Codex app-server versions fail startup with a clear minimum-version error. [#101221](https://github.com/nova/nova/pull/101221)
- Copilot sessions can now use explicitly selected custom OpenAI, Azure OpenAI, Ollama-compatible, or Anthropic providers and restart cleanly when model, endpoint, credentials, headers, or token limits change. [#96345](https://github.com/nova/nova/pull/96345) Thanks @vincentkoc.
- Sessions can now be pinned, archived without losing transcripts, restored, renamed from chat surfaces, and monitored for active runs as durable conversation threads. [#98510](https://github.com/nova/nova/pull/98510) Thanks @maziyang2.
- An active `/goal` now keeps guiding later turns and survives compaction, queues, and interruptions until the goal is paused, completed, blocked, or limited. [#100468](https://github.com/nova/nova/pull/100468)

#### Telegram

[Telegram](https://docs.nova.ai/channels/telegram) received broad work across live progress, media, documents, topics, commands, retries, account routing, setup, and delivery. Albums reach the model with every available image, long replies remain easier to follow while they run, and temporary conflicts or network failures are less likely to block later messages or create duplicates.

Messages and actions also stay with the intended bot, topic, and conversation more consistently, while setup and account-health problems provide clearer ways to recover.

- Telegram photo albums now give the model every successfully downloaded image in order instead of only one photo and unusable file references, while failed items are omitted. [#97045](https://github.com/nova/nova/pull/97045) Thanks @nianjiuzst, @obviyus.
- Telegram's live progress view now keeps reasoning, commentary, formatting, and tool activity readable and stable, then leaves a concise completion summary instead of disappearing. [#98907](https://github.com/nova/nova/pull/98907) Thanks @marvinthebored, @peetiegonzalez.
- Telegram users should see fewer failed final replies or bot delivery sends during flaky network handshakes, without increasing duplicate-message risk for failures that may have happened after a request was sent. [#101258](https://github.com/nova/nova/pull/101258) Thanks @lzw112.

- Telegram PDFs and other documents now provide agents with a usable local path so normal runner tools can open the attachment. [#97647](https://github.com/nova/nova/pull/97647) Thanks @gallup007, @joshavant.
- Telegram timeout logs now hide bot tokens embedded in Bot API paths, including custom and proxy roots, while retaining useful endpoint context. [#99428](https://github.com/nova/nova/pull/99428) Related [#96982](https://github.com/nova/nova/issues/96982). Thanks @liuhaiyang14, @xialonglee.
- Telegram bot tokens now remain masked even when they cross internal boundaries inside very large logs or tool-error messages. [#103861](https://github.com/nova/nova/pull/103861) Thanks @vincentkoc.
- When a Telegram plugin approval cannot be routed, operators now receive practical Web UI, terminal UI, and configuration guidance instead of a generic failure or timeout. [#95973](https://github.com/nova/nova/pull/95973) Related [#95800](https://github.com/nova/nova/issues/95800). Thanks @chrisbot2026, @monkeyleet.
- Scheduled deliveries to numeric threads such as Telegram forum topics now return to the configured thread after Gateway restarts instead of falling back to the general chat. [#98699](https://github.com/nova/nova/pull/98699) Thanks @yetval.

#### Slack

[Slack](https://docs.nova.ai/channels/slack) threads retain their conversation history more consistently, interactive cards and progress stay in the right place, and accepted replies are less likely to be repeated after an uncertain confirmation. Long-running conversations also avoid more unnecessary waits before reaching the agent.

- Slack replies stay attached to the root thread's session history instead of accumulating separate, nearly empty child sessions. [#97168](https://github.com/nova/nova/pull/97168) Related [#96535](https://github.com/nova/nova/issues/96535). Thanks @gorkem2020, @liuwqgit.
- When Slack accepts a reply but the confirmation is lost, Nova can verify the existing post and avoid sending a duplicate. [#97480](https://github.com/nova/nova/pull/97480) Thanks @joeyfrasier.

- Slack and similar channel turns with context-injecting plugins now send each inbound system label to the model once instead of duplicating it. [#95349](https://github.com/nova/nova/pull/95349) Thanks @gorkem2020, @openperf, @vincentkoc.
- Slack rooms that require a mention no longer wake Nova for ordinary messages when the bot identity is missing or untrusted, and setup warnings point operators to a Bot User OAuth Token when needed. [#91584](https://github.com/nova/nova/pull/91584) Thanks @hiragram.

#### Discord

[Discord](https://docs.nova.ai/channels/discord) improves reply visibility, attachments, voice sessions, progress, reconnects, and multi-account behavior. Completed replies produce more useful unread cues, brief Gateway reconnects are less likely to lose outbound messages, and repeated session-resume failures can recover without taking the whole Gateway down.

- Completed partial-stream Discord replies now arrive as fresh messages that can trigger normal unread cues after a user leaves the channel. [#99711](https://github.com/nova/nova/pull/99711) Thanks @davelutztx.
- Discord replies, cron reports, and other outbound messages are less likely to disappear during a brief Gateway reconnect, without replaying chunks or media Discord already accepted. [#100896](https://github.com/nova/nova/pull/100896) Thanks @tiffanychum.
- Discord bots can now recover in place after repeated session-resume rejection, reducing prolonged outages, lost replies, and full Gateway restarts. [#103596](https://github.com/nova/nova/pull/103596)

- Discord Code Mode progress no longer fills with repetitive Wait rows from background polling, while ordinary custom and plugin tools remain visible. [#100164](https://github.com/nova/nova/pull/100164)
- Long Discord approval previews now preserve complete emoji and flags when shortened, avoiding broken replacement characters. [#99539](https://github.com/nova/nova/pull/99539) Thanks @zhangguiping-xydt.
- Discord read allowlists now block guild metadata, channel details, and thread listings before any provider request when those resources are outside the configured scope. [#98966](https://github.com/nova/nova/pull/98966) Thanks @pgondhi987.
- Discord users can complete approved Codex Computer Use actions such as `get_app_state` and receive the native tool result instead of getting a false timeout while the tool is still running. [#96818](https://github.com/nova/nova/pull/96818) Thanks @pollybot13, @zhangguiping-xydt.

#### Apple Messages

[Apple Messages](https://docs.nova.ai/channels/imessage) receives broader improvements to replies, typing, media, routing, setup guidance, and chat continuity. Remote Mac attachments can reach the active conversation through a usable local path, replies work in more bridge setups, and ordinary message text is less likely to be mistaken for internal role markers.

- Photos bridged from a remote iMessage Mac to a separate Gateway host now arrive in Codex conversations through a readable local path rather than a Mac-only filename. [#91803](https://github.com/nova/nova/pull/91803) Thanks @turbotheturtle.
- AppleScript-only and bot-user or SSH iMessage setups now deliver replies even when threading is unavailable, and database changes no longer leave inbound messages hidden behind stale recovery state. [#100446](https://github.com/nova/nova/pull/100446) Thanks @omarshahine.
- Direct iMessage chats using the `imsg` private API bridge now show typing as soon as a slow turn is accepted, without waiting for a read receipt. [#95621](https://github.com/nova/nova/pull/95621) Thanks @omarshahine.
- iMessage replies no longer lose ordinary sentence text that happens to end with `user:`, `system:`, or `assistant:`. [#96392](https://github.com/nova/nova/pull/96392) Thanks @ly-wang19.

- Hidden MiniMax reasoning no longer appears as a new iMessage or feeds back into the conversation as an echo-triggering inbound message. [#93820](https://github.com/nova/nova/pull/93820) Thanks @alix-007.
- Renaming iMessage groups, changing icons or membership, and leaving groups now require verified owner or administrator authority. [#97961](https://github.com/nova/nova/pull/97961) Thanks @eleqtrizit.
- Mac users setting up iMessage can install or update `imsg` from the setup flow, receive clearer probe guidance, and recover sessions that still reference the old skill location. [#101407](https://github.com/nova/nova/pull/101407) Thanks @omarshahine.

#### Gateway restart recovery

A supervised Gateway that repeatedly fails during startup now leaves operators a stable [restart and recovery](https://docs.nova.ai/gateway/restart-recovery) process to inspect and repair. Instead of relaunching forever, the control path remains available while automatic channel and provider restarts pause until the underlying problem is fixed.

- A repeatedly crashing supervised Gateway now leaves a stable control process available for inspection and repair instead of trapping operators in a restart loop. [a18708c](https://github.com/nova/nova/commit/a18708c5c12d93f14eb753b543a6747e8baa8c47) Thanks @obviyus.

#### Automation, browser control, and terminals

Scheduled work can wake when a command finishes or a watched condition changes, remote browser control can pair selected signed-in tabs and save completed downloads safely, and guarded workspace terminals are available across web and mobile.

##### Scheduled work

[Scheduled jobs](https://docs.nova.ai/automation/cron-jobs) can react when an external command finishes or a watched condition changes, so the full agent runs only when there is something new to handle. Reapplying the same declaration updates the intended job in place, preserving identity and history instead of creating duplicate schedules.

- A cron job can now watch a build, deploy, script, or other command and resume the originating workflow with its exit code and recent output when it finishes. [#92037](https://github.com/nova/nova/pull/92037) Thanks @anagnorisis2peripeteia.
- Cron declarations can now be safely reapplied without duplicate jobs or lost history, while ownership, next run, latest result, delivery, and failure notifications are easier to inspect. [#100480](https://github.com/nova/nova/pull/100480)
- Cron jobs can now watch an outside condition and run their real payload only when that state changes, avoiding full agent wakeups on unchanged polls. [#101195](https://github.com/nova/nova/pull/101195)

##### Remote browser control

[Browser control](https://docs.nova.ai/tools/browser-control) is easier to use across machines: operators can pair the bundled Chrome extension with a remote Gateway, share only selected signed-in tabs, diagnose Windows and WSL2 connection details, and revoke access by removing a tab from the Nova group. Agents can also wait for delayed downloads and save the finished file to a guarded local path with its final URL and suggested name.

- Windows and WSL2 users now get IPv4 and IPv6 checks plus the matching portproxy guidance needed to restore Chrome browser control without broadening CDP exposure. [#100590](https://github.com/nova/nova/pull/100590) Thanks @owlock, @zengwen-dt.
- The bundled Chrome extension now lets users control selected signed-in tabs from a phone or another channel without someone approving remote debugging at the desktop, and removing a tab revokes access. [#100619](https://github.com/nova/nova/pull/100619)
- Remote Gateway users can pair the bundled Chrome extension from another browser machine with `nova browser extension pair --gateway-url wss://...`, without installing Nova or Node.js there or opening an inbound port. [#101127](https://github.com/nova/nova/pull/101127)
- Agents can now save a browser download to a chosen guarded path or wait for a delayed export, receiving the final URL, filename, and local path. [#101369](https://github.com/nova/nova/pull/101369) Thanks @grd-chang.

##### Workspace terminals

Authenticated operators can open a guarded workspace terminal from the [Control UI](https://docs.nova.ai/web/control-ui), iOS, or Android without leaving the current workspace. Sessions use the selected agent's workspace and configured shell, can be disabled by policy, and follow the [Gateway protocol](https://docs.nova.ai/gateway/protocol) controls for ownership and connection state. Browser terminals can dock, resize, and run side by side, while iOS and Android provide focused entry points with clear connection guidance.

Same-release browser hardening completes the capability: terminals can reattach after reloads, sleep, or brief network drops and replay recent output; newly enabled support appears without a manual refresh; and closing, reopening, theming, cursor focus, prompt glyphs, and new-tab controls remain usable through repeated sessions.

- Authenticated admins can open an interactive terminal in an agent workspace from Gateway-backed controls, while fully sandboxed agents remain blocked and the feature can be disabled with `gateway.terminal.enabled`. [f083f35](https://github.com/nova/nova/commit/f083f35ddb467fa5ed7077244525913673bc7aa0)
- Control UI admins can now keep chat, session controls, and live shells together by opening multiple dockable, resizable terminal tabs inside the browser workspace. [ec72de4](https://github.com/nova/nova/commit/ec72de41faa71b71d0e479eaa31d791e3b6afe58)
- Opt-in Control UI terminal sessions can now survive page reloads, sleep, and brief network drops, letting operators reattach and replay recent output instead of losing running commands. [#100089](https://github.com/nova/nova/pull/100089)
- Opening a new Control UI terminal after closing the final tab now starts with a blank fresh shell instead of restoring the closed terminal output. [#100665](https://github.com/nova/nova/pull/100665)
- Control UI terminal tabs now close cleanly while opening, follow theme changes, and reopen at a usable size instead of leaving hidden sessions, stale colors, or unreachable controls. [2399ce7](https://github.com/nova/nova/commit/2399ce7c854d278276e65c9ed75f273a3c972e39)
- An already-open Control UI page now notices when terminal support is enabled and makes the terminal available without requiring a manual refresh. [3f976f9](https://github.com/nova/nova/commit/3f976f9f8624ded5af6fc48abf43c25a79661a32)
- Opening a new Control UI terminal tab after closing another no longer inherits an old exited state. [3c03389](https://github.com/nova/nova/commit/3c033899257210cb46d3c87468bb1a613e4fc831)
- The Control UI terminal no longer crashes when its web component is loaded more than once in a shared browser registry. [f2e5159](https://github.com/nova/nova/commit/f2e5159f53248800416c15cc3aef50e505968317)
- Control UI terminals now use installed Nerd Font fallbacks so supported prompt and listing icons render as glyphs instead of placeholder boxes. [#100128](https://github.com/nova/nova/pull/100128)
- The Control UI integrated terminal now shows one cursor instead of overlapping Chrome and terminal carets, making focus and typing state clearer. [#100240](https://github.com/nova/nova/pull/100240)
- The Control UI terminal's new-session button now aligns with the surrounding tabs for a cleaner, easier-to-scan tab bar. [#100256](https://github.com/nova/nova/pull/100256)

### Channels and Messaging

Replies and media now stay attached to the intended conversation more consistently across workspace, mobile, and community channels. [Signal](https://docs.nova.ai/channels/signal) can quote the triggering message and use friendly destination aliases, while [Telegram](https://docs.nova.ai/channels/telegram) handles albums, progress, retries, topics, routing, and delivery with fewer dropped, duplicated, stale, or hard-to-read results.

Discord, Slack, WhatsApp, Apple Messages, and other supported channels also receive clearer command, thread, attachment, proxy, and recovery behavior. The [Apple Messages](https://docs.nova.ai/channels/imessage) setup and delivery paths in this group preserve the chat context readers expect rather than exposing the routing work underneath.

#### Telegram

- Telegram automations can now tell from platform metadata whether a sender is a bot, making routing and classification less dependent on usernames or naming conventions. [#96810](https://github.com/nova/nova/pull/96810) Thanks @lin-hongkuan, @ohyeah521.
- Telegram sends and message actions that omit an account now consistently use the configured default bot instead of a stale identity that can misroute or reject the action. [#98789](https://github.com/nova/nova/pull/98789) Thanks @yetval.
- Telegram destinations genuinely named `current`, `self`, `this`, or `me` can now be reached through configured entries, while accidental bare session words fail closed. [#94107](https://github.com/nova/nova/pull/94107) Thanks @obviyus, @silver-state, @zhangguiping-xydt.
- Telegram sends to an `username` now use the account's configured proxy or custom Bot API endpoint for both target resolution and message delivery. [#100868](https://github.com/nova/nova/pull/100868) Thanks @machine3at.
- Telegram webhook startup now releases its listener, bot, and network resources after a fatal registration error such as invalid or revoked credentials. [#100863](https://github.com/nova/nova/pull/100863) Thanks @machine3at.
- Telegram photo albums now give the model every successfully downloaded image in order instead of only one photo and unusable file references, while failed items are omitted. [#97045](https://github.com/nova/nova/pull/97045) Thanks @nianjiuzst, @obviyus.
- Telegram replies now omit internal tool-execution failure lines and deliver only the intended assistant answer. [#95774](https://github.com/nova/nova/pull/95774) Thanks @mushuiyu886.
- Telegram replies retain literal wording such as `&lt;think&gt;` when it is part of the answer, while genuinely marked reasoning remains hidden. [#97286](https://github.com/nova/nova/pull/97286) Thanks @drickon, @obviyus.
- Telegram heartbeat fallbacks now hide the `notify=false` control marker and deliver silently as requested, including suppressing marker-only replies. [#100735](https://github.com/nova/nova/pull/100735) Thanks @hackerismydream, @vincentkoc.
- Telegram stickers and other plugin message actions now stay in the active forum topic or thread when sent to the matching conversation, including through Gateway dispatch. [#80293](https://github.com/nova/nova/pull/80293) Thanks @artdaal.
- Telegram messages can now be sent proactively through the `message` tool or `nova message send` instead of failing as an unsupported channel. [#92107](https://github.com/nova/nova/pull/92107) Thanks @bladin, @obviyus.
- `sessions_send` now rejects Telegram topic child sessions before dispatch and directs callers to the parent group, reducing misrouted agent work. [#99845](https://github.com/nova/nova/pull/99845) Thanks @nianjiuzst, @qingminglong.
- Polls now follow the selected direct or hybrid channel instead of being misrouted through the Gateway, with clear errors for unsupported duration or anonymity options. [#99950](https://github.com/nova/nova/pull/99950) Thanks @nianjiuzst.
- Established Telegram direct-message sessions now avoid resending recent messages already stored in the transcript, reducing token use and repetitive or confused replies. [#89855](https://github.com/nova/nova/pull/89855) Thanks @sweetcornna.
- Telegram direct-message follow-ups now include one copy of the previous assistant reply in recent context instead of duplicating it and wasting tokens. [#98769](https://github.com/nova/nova/pull/98769) Related [#98767](https://github.com/nova/nova/issues/98767). Thanks @rabsef-bicrym.
- Telegram bots in ambient group mode now see recent room context before deciding whether to speak, reducing replies to isolated fragments that were not directed at the bot. [#99143](https://github.com/nova/nova/pull/99143) Related [#99142](https://github.com/nova/nova/issues/99142). Thanks @obviyus.
- Telegram group agents now receive one chronological copy of recent messages instead of duplicated history and repeated delivery details consuming context. [#99256](https://github.com/nova/nova/pull/99256) Related [#99218](https://github.com/nova/nova/issues/99218). Thanks @obviyus.
- Telegram ambient group conversations can now retain unmentioned room context across later turns, restarts, and compaction without repeatedly replaying the same window. [#99306](https://github.com/nova/nova/pull/99306) Related [#99257](https://github.com/nova/nova/issues/99257). Thanks @obviyus.
- Telegram ambient group sessions now restore the relevant older chat context after a reset instead of silently treating archived messages as already visible. [#99385](https://github.com/nova/nova/pull/99385) Related [#99373](https://github.com/nova/nova/issues/99373). Thanks @obviyus.
- Telegram group agents now post visible replies when directly mentioned or replied to, while continuing to ignore unaddressed background chatter. [#99866](https://github.com/nova/nova/pull/99866) Related [#99854](https://github.com/nova/nova/issues/99854). Thanks @obviyus.
- Telegram direct-message follow-ups now include one accurate copy of each earlier assistant reply instead of duplicating a hidden-instruction version. [#100573](https://github.com/nova/nova/pull/100573) Thanks @momothemage, @mooresoftware.
- Telegram's live progress view now keeps reasoning, commentary, formatting, and tool activity readable and stable, then leaves a concise completion summary instead of disappearing. [#98907](https://github.com/nova/nova/pull/98907) Thanks @marvinthebored, @peetiegonzalez.
- Telegram rich replies and progress messages containing OAuth email addresses now arrive instead of being rejected by Telegram validation. [#95900](https://github.com/nova/nova/pull/95900) Thanks @obviyus.
- Telegram progress updates now truncate safely around emoji and other multi-unit characters, preventing broken glyphs and rejected Bot API payloads. [#96456](https://github.com/nova/nova/pull/96456) Thanks @he-yufeng.
- Telegram streaming draft previews no longer break or show garbled text when an emoji falls at the size boundary, so long previews can keep updating normally. [#96504](https://github.com/nova/nova/pull/96504) Thanks @mushuiyu886, @obviyus.
- Telegram replies now keep typing visible through more temporary API failures and fall back to plain text when valid rich content cannot be delivered. [#99745](https://github.com/nova/nova/pull/99745) Thanks @obviyus, @veda-nova.
- Telegram typing indicators now retry after transient network failures, restoring status feedback without adding duplicate-message risk to normal sends. [#100762](https://github.com/nova/nova/pull/100762) Thanks @lzw112, @vincentkoc.
- Telegram's final collapsed progress summary now includes Claude CLI thinking activity that was shown during the run instead of making that work appear to vanish. [4212de9](https://github.com/nova/nova/commit/4212de9e08d6e69357d937e399db3df63c1b66d7) Thanks @vincentkoc.
- Telegram users with `/reasoning on` now receive the model's saved reasoning messages alongside the final answer. [#97875](https://github.com/nova/nova/pull/97875) Thanks @fuller-stack-dev, @marvinthebored.
- Telegram groups and forum topics now show a typing indicator as soon as an addressed message is accepted, without signaling activity for ignored chatter. [#99965](https://github.com/nova/nova/pull/99965) Thanks @moeedahmed.
- Telegram configurations with legacy `capabilities: []` now inherit the normal inline-button policy, restoring clickable buttons without overriding intentional opt-outs. [#96468](https://github.com/nova/nova/pull/96468) Thanks @vincentkoc, @zhangguiping-xydt.
- Telegram users still receive a plain-text reply when rich formatting for an email, URL, mention, hashtag, command, phone number, bank card, or similar entity is rejected, instead of the bot going silent. [#96642](https://github.com/nova/nova/pull/96642) Thanks @moguangyu5-design.
- Telegram inline buttons supplied by plugins now run their intended actions and cleanup instead of posting raw callback data into chat. [#97174](https://github.com/nova/nova/pull/97174) Thanks @goldmar.
- Telegram rich-text replies now render math formulas more reliably instead of exposing raw LaTeX-style markers. [#97197](https://github.com/nova/nova/pull/97197) Thanks @vincentkoc, @wangwllu.
- Telegram final replies and media sends now fall back to readable plain text when formatting, captions, or quotes are rejected, and routine flood waits up to 60 seconds are honored instead of dropping the message. [#98786](https://github.com/nova/nova/pull/98786) Related [#98778](https://github.com/nova/nova/issues/98778). Thanks @obviyus.
- Telegram plugins can now turn a button tap into a normal user reply to the agent, while failed or skipped submissions leave the button available for another attempt. [#98922](https://github.com/nova/nova/pull/98922) Thanks @goldmar.
- Telegram tables, rankings, and literal line breaks now remain readable, with explicit logs when rich content must fall back to plain text. [#99861](https://github.com/nova/nova/pull/99861) Related [#99833](https://github.com/nova/nova/issues/99833). Thanks @obviyus.
- Telegram rich messages using `richMessages: true` and Markdown table mode `block` now display bordered, striped tables with the source column alignment. [#95822](https://github.com/nova/nova/pull/95822) Thanks @obviyus, @zhangguiping-xydt.
- Telegram fallback messages now replace invalid numeric Unicode surrogate entities safely instead of emitting malformed text, while valid numeric emoji entities still render. [#96581](https://github.com/nova/nova/pull/96581) Thanks @llagy007, @weeli-009.
- Telegram documents received through a containerized local Bot API now arrive with their actual contents when its mounted data path differs between containers. [#91984](https://github.com/nova/nova/pull/91984) Thanks @ailucasdz, @dizesales.
- Telegram documents sent near a Gateway restart now retry after recovery instead of disappearing silently, while permanent failures still request a resend. [#98102](https://github.com/nova/nova/pull/98102) Related [#98076](https://github.com/nova/nova/issues/98076). Thanks @davearcher18, @luoyanglang, @obviyus.
- Telegram rich messages and text-bearing forwards without a normal caption now reach the agent as readable conversation content instead of an unsupported-message placeholder. [#98735](https://github.com/nova/nova/pull/98735) Thanks @obviyus.
- Telegram now tells users when an attachment cannot be downloaded, reports the actual size limit for oversized files, and still retries transient failures such as rate limits. [#100051](https://github.com/nova/nova/pull/100051) Thanks @batyaro777.
- Telegram replies and forwards now preserve visible text from rich details, lists, math, captions, and credits so the agent receives the context users actually saw. [#100570](https://github.com/nova/nova/pull/100570) Thanks @veda-nova, @wangwllu.
- MP3 speech from Piper, Kokoro, and other OpenAI-compatible TTS endpoints now arrives in Telegram as a native voice note rather than a filename-style audio attachment. [#100715](https://github.com/nova/nova/pull/100715) Thanks @hemantsudarshan.
- Telegram no longer follows a successfully delivered final answer with a contradictory generic error when a later dispatch step fails, while partial-only failures still receive the existing fallback. [#90152](https://github.com/nova/nova/pull/90152) Thanks @zhangguiping-xydt.
- A temporary Telegram reply-session conflict no longer traps a DM or forum topic in constant retries that block later messages; retries are paced, conversation order is retained, and unrelated chats continue processing. [#96550](https://github.com/nova/nova/pull/96550) Thanks @cnbarrier404, @vacinc.
- Telegram reactions and message deletions now retry brief socket or Undici network failures, reducing unnecessary action failures without adding duplicate risk to ordinary message sends. [#96612](https://github.com/nova/nova/pull/96612) Thanks @miorbnli.
- Telegram messages entering through isolated ingress now proceed to the agent reply instead of replaying the same message in a loop. [#96847](https://github.com/nova/nova/pull/96847) Thanks @obviyus.
- Long-running Telegram turns can finish without being reclaimed and processed again midway, reducing stalled or duplicate delivery while giving operators a clearer unhealthy status when the backlog stops draining. [#96962](https://github.com/nova/nova/pull/96962) Thanks @joshavant.
- Telegram bots using isolated polling can resume ordered message processing after a stalled drain or Gateway restart without manual database repair. [#97118](https://github.com/nova/nova/pull/97118) Thanks @romneyda, @vincentkoc.
- Long non-streamed Telegram group replies now keep every chunk visible, including the beginning, while delivery receipts cover all generated text chunks. [#97304](https://github.com/nova/nova/pull/97304) Thanks @aliseturtle-lu, @obviyus.
- Long streamed Telegram replies now deliver their middle sections under the default configuration instead of silently omitting part of the answer. [#97312](https://github.com/nova/nova/pull/97312) Thanks @brycemurray, @obviyus.
- Telegram polling now recovers from temporary rate limits, server failures, and malformed error responses without disabling the account, while busy bots avoid cache writes that could trigger false stall restarts. [#98775](https://github.com/nova/nova/pull/98775) Related [#98772](https://github.com/nova/nova/issues/98772), [#98773](https://github.com/nova/nova/issues/98773). Thanks @obviyus.
- A repeatedly failing Telegram update no longer blocks later messages in the same chat or topic, and replayed updates are retried safely without duplicate commands or apology spam. [#98776](https://github.com/nova/nova/pull/98776) Related [#98774](https://github.com/nova/nova/issues/98774). Thanks @obviyus.
- Telegram webhook messages now survive Gateway restarts and temporary processing failures, while accounts recover from brief startup errors and repeated restarts stop leaking network connections. [#98806](https://github.com/nova/nova/pull/98806) Related [#98777](https://github.com/nova/nova/issues/98777). Thanks @obviyus.
- Queued Telegram updates now remain replayable until restart recovery is safely recorded, reducing message loss during a crash at processing startup. [#104032](https://github.com/nova/nova/pull/104032) Thanks @obviyus, @vincentkoc.
- Telegram sends now retry a safe TCP or TLS connection timeout, reducing lost final replies during flaky handshakes without retrying failures that may already have reached Telegram. [#101258](https://github.com/nova/nova/pull/101258) Thanks @lzw112.
- Telegram startup logs now show local socket failures such as `EADDRNOTAVAIL` instead of incorrectly steering operators toward DNS troubleshooting. [#97130](https://github.com/nova/nova/pull/97130) Thanks @zhangguiping-xydt.
- Telegram bot probes, webhook checks, membership audits, and polling now reject oversized Bot API success bodies before they can exhaust Gateway memory. [#97271](https://github.com/nova/nova/pull/97271) Thanks @hugenshen.
- Telegram chat-ID lookup now fails safely on oversized `getChat` responses instead of risking excessive Gateway memory use during onboarding or routing. [#97274](https://github.com/nova/nova/pull/97274) Thanks @hugenshen.
- Telegram onboarding now offers both the classic BotFather chat flow and the official web interface for creating a bot and copying its token into Nova. [#100540](https://github.com/nova/nova/pull/100540)
- After `/login codex` succeeds in Telegram, retrying the request now uses the newly authenticated OpenAI profile instead of the previous account. [fca0c81](https://github.com/nova/nova/commit/fca0c81791a5040536d4907913ed975bfcde1642) Thanks @100yenadmin.
- Telegram `/steer` and `/tell` commands can redirect an active Codex task during streaming or tool work instead of arriving late or becoming follow-up messages. [#98126](https://github.com/nova/nova/pull/98126) Related [#81594](https://github.com/nova/nova/issues/81594). Thanks @100yenadmin, @kyzcreig.
- Saying `wait` in a Telegram group conversation no longer cancels active Nova work, while explicit stop commands still take effect immediately. [#98639](https://github.com/nova/nova/pull/98639) Thanks @ianchen08.
- Telegram messages that cannot be steered into an active Codex turn are now retained for handling afterward instead of disappearing without a reply. [#103916](https://github.com/nova/nova/pull/103916) Thanks @jalehman.
- When Telegram requests overlap, the newest authorized message now wins without an outdated reply being sent or replaced queued work being started. [#103965](https://github.com/nova/nova/pull/103965)
- A Telegram reply that has already started is no longer unexpectedly cancelled when another authorized command arrives. [52a3314](https://github.com/nova/nova/commit/52a331466882ca0b6befa56c883355c758305813) Thanks @vincentkoc.

#### Signal

- Signal auto-replies now quote the message that triggered them, making responses easier to follow in groups and busy conversations. [#95718](https://github.com/nova/nova/pull/95718) Thanks @jesse-merhi.
- Signal reaction shortcuts now apply only to the intended structured exec or plugin approval, including forwarded monitor and chunked prompts, while ordinary messages that merely quote approval commands no longer gain controls; older delivered prompts may still require `/approve` once after upgrade. [#96880](https://github.com/nova/nova/pull/96880) Thanks @joshavant.
- Signal users who enable status reactions can now see when Nova accepts a message, works, uses tools, compacts, stalls, or finishes in direct and group chats. [#98791](https://github.com/nova/nova/pull/98791) Thanks @jesse-merhi.
- Signal QuickStart now shows one clear `signal-cli` installation failure and proceeds directly to the custom-path prompt instead of repeating the missing-binary message. [#96932](https://github.com/nova/nova/pull/96932) Thanks @romneyda.
- Signal plugin setup now handles slow, malformed, or oversized GitHub release metadata without risking process memory exhaustion. [#97536](https://github.com/nova/nova/pull/97536) Thanks @hugenshen.
- Signal container mode now stops oversized or runaway `signal-cli-rest-api` responses from threatening the entire Nova process. [#97539](https://github.com/nova/nova/pull/97539) Thanks @alix-007.
- Invalid JSON from the Signal REST container now produces a clear Signal-specific failure instead of exposing a raw parser error. [#98073](https://github.com/nova/nova/pull/98073) Thanks @lsr911, @vincentkoc.
- Signal QuickStart on macOS now installs `signal-cli` through Homebrew instead of downloading an incompatible Linux package, and gives platform-specific guidance when Homebrew is unavailable. [#96909](https://github.com/nova/nova/pull/96909) Thanks @romneyda.
- Signal container receives now reject oversized JSON frames before buffering them, limiting memory pressure without affecting normal messages or separately fetched attachments. [#99992](https://github.com/nova/nova/pull/99992) Thanks @sunlit-deng.
- Signal users can assign stable names such as `signal:me` or `signal:ops` to repeat contacts and groups instead of reusing raw phone numbers, UUIDs, or IDs. [#95738](https://github.com/nova/nova/pull/95738) Thanks @jesse-merhi.
- Signal users now receive clean assistant replies without internal tool status, reasoning tags, or tool-call markup. [#97360](https://github.com/nova/nova/pull/97360) Thanks @masatohoshino.

- Signal local-file attachments that are oversized or use suspicious paths now fail quickly with a clear error before consuming excessive Gateway memory. [#101391](https://github.com/nova/nova/pull/101391) Thanks @cxbasdev.

#### Slack

- Slack channels can keep ambient Nova participation while the opt-in `ignoreOtherMentions` setting prevents replies to conversations aimed at another person or group and retains that conversation as context for a later bot mention. [#53467](https://github.com/nova/nova/pull/53467) Thanks @hanamizuki.
- Slack operators can now choose `off`, `first`, `all`, or `batched` reply threading per channel, with automatic replies and message tools following the same effective choice. [#82253](https://github.com/nova/nova/pull/82253)
- Slack button and select interactions now remain in the correct assistant thread and show a working status there until the follow-up turn finishes. [#82895](https://github.com/nova/nova/pull/82895) Thanks @wukongai-cmu.
- The first Slack reply after a daily or idle reset can reuse recent thread history, so the conversation does not suddenly start from scratch. [#97100](https://github.com/nova/nova/pull/97100) Thanks @bek91.
- Slack replies stay attached to the root thread's session history instead of accumulating separate, nearly empty child sessions. [#97168](https://github.com/nova/nova/pull/97168) Related [#96535](https://github.com/nova/nova/issues/96535). Thanks @gorkem2020, @liuwqgit.
- Ordinary Slack thread replies no longer download and process the opening message attachments again, while new or reset sessions still receive those files once. [#100516](https://github.com/nova/nova/pull/100516)
- Session history now identifies Slack replies that were generated but intentionally superseded before delivery, so operators do not mistake them for messages the user received. [#100607](https://github.com/nova/nova/pull/100607) Thanks @bek91.
- Slack replies in very long threads and on busy Gateways now avoid several unnecessary waits, reducing stalls before thread and direct-message events reach the agent. [#101888](https://github.com/nova/nova/pull/101888) Thanks @obviyus.
- Slack agents can now read thread messages whose visible content exists only in attachments or blocks, including alerts with empty top-level text. [#97727](https://github.com/nova/nova/pull/97727) Thanks @chthtlo.
- Slack Codex conversations now retain one final assistant reply in history instead of duplicating it through both the app-server transcript and delivery fallback. [#100160](https://github.com/nova/nova/pull/100160) Thanks @steipete-oai.
- Scheduled and heartbeat-driven Slack messages now use the configured agent name and icon, with graceful fallback to the app identity when Slack rejects customization. [#84335](https://github.com/nova/nova/pull/84335) Thanks @rohang2005.
- Longer Slack assistant-thread replies now show changing progress notes so users can tell Nova is still working. [#85507](https://github.com/nova/nova/pull/85507) Thanks @emergentash.
- Slack presentation messages now arrive as native Block Kit cards with working headers, controls, and receipts instead of flattened plain text. [#95463](https://github.com/nova/nova/pull/95463) Thanks @zoowh.
- Slack rich-text block actions can now include emoji near the preview limit without producing malformed interaction text or downstream encoding failures. [#96577](https://github.com/nova/nova/pull/96577) Thanks @llagy007, @weeli-009.
- Slack buttons and menus now preserve time labels such as `9:00` and return the intended action value when selected. [#99877](https://github.com/nova/nova/pull/99877) Thanks @qingminglong, @rodja.
- Slack message reactions now accept common emoji or shortcode names, can target the current message without repeating its ID, and provide clearer member-lookup guidance. [#100375](https://github.com/nova/nova/pull/100375) Thanks @gorkem2020.
- Slack now uses one static acknowledgement reaction alongside its native assistant loading status by default, avoiding two competing progress displays for the same reply. [#100462](https://github.com/nova/nova/pull/100462) Thanks @steipete-oai.
- Slack messages and Block Kit labels now truncate without splitting emoji into broken replacement characters or invalid payload text. [#96382](https://github.com/nova/nova/pull/96382) Thanks @ly-wang19.
- Long Slack command and plugin approval previews now keep emoji intact at the length boundary, avoiding malformed approval text or payloads. [#96576](https://github.com/nova/nova/pull/96576) Thanks @llagy007, @weeli-009.
- Slack slash-command choice menus now shorten long labels without splitting emoji at the 75-character limit. [#97923](https://github.com/nova/nova/pull/97923) Thanks @lexes7.
- Slack replies now keep each agent's custom name and avatar through streaming or fallback delivery instead of reverting to the app identity. [#100084](https://github.com/nova/nova/pull/100084) Thanks @moerai.
- Slack operators running multiple Gateways through one Socket Mode app now receive a startup warning explaining why events may reach another connection and how to choose a safer deployment setup. [#79938](https://github.com/nova/nova/pull/79938) Thanks @jeffvsutherland.
- Slack replies no longer expose internal tool-failure banners, reasoning scaffolding, or tool-call markup to users. [#97367](https://github.com/nova/nova/pull/97367) Thanks @masatohoshino.
- When Slack accepts a reply but the confirmation is lost, Nova can verify the existing post and avoid sending a duplicate. [#97480](https://github.com/nova/nova/pull/97480) Thanks @joeyfrasier.
- Slack replies now retry after a temporary session-start conflict instead of stopping before the expected message is delivered. [#99647](https://github.com/nova/nova/pull/99647) Thanks @steipete-oai.
- Slack read actions can again access intentionally allowlisted channel names when Slack supplies an ID and `dangerouslyAllowNameMatching` is enabled. [#95313](https://github.com/nova/nova/pull/95313) Thanks @jontsai.
- Slack message and attachment text is no longer copied into verbose or debug logs during inbound processing. [#96312](https://github.com/nova/nova/pull/96312) Thanks @steipete-oai.
- Nova can use a trusted override for a compatible Slack API endpoint, while normal workspaces continue using Slack's public API and untrusted project .env files cannot redirect bearer-token requests. [#97154](https://github.com/nova/nova/pull/97154) Thanks @romneyda.
- Slack agents can now identify admitted bot-authored messages through `is_bot: true`, making it easier to prevent unwanted bot-to-bot replies. [#97822](https://github.com/nova/nova/pull/97822) Thanks @masatohoshino, @vincentkoc.
- Slack Socket Mode relay diagnostics now distinguish malformed WebSocket frames from transport failures, making channel problems easier to identify. [#98587](https://github.com/nova/nova/pull/98587) Thanks @lsr911, @vincentkoc.
- Slack startup and account checks now warn when a user OAuth credential is configured as the bot token, before identity confusion affects mentions or replies. [#99931](https://github.com/nova/nova/pull/99931) Thanks @ooiuuii.
- Long-running Slack integrations now keep conversation metadata caching within a fixed limit, preventing memory use from growing indefinitely as more channels and workspaces are encountered. [#101562](https://github.com/nova/nova/pull/101562) Thanks @vincentkoc, @zhangguiping-xydt.

#### Discord

- Discord tool-only replies no longer leave overlapping typing refreshes that suggest another answer is still coming, while explicitly configured typing behavior remains intact. [#84288](https://github.com/nova/nova/pull/84288) Thanks @dr00-eth.
- When a Discord voice-note reply fails, users now receive the assistant's answer as a threaded text fallback without duplicating text that was already delivered. [#89962](https://github.com/nova/nova/pull/89962) Thanks @danhayman.
- Discord's clear-all reactions action now returns a real error if any bot reaction remains instead of claiming complete success. [#90038](https://github.com/nova/nova/pull/90038) Thanks @masatohoshino.
- Discord now shows enabled Anthropic reasoning, notes, and tool activity in the right order with accurate counters and nonblank summaries. [#96106](https://github.com/nova/nova/pull/96106) Thanks @marvinthebored, @obviyus, @peetiegonzalez.
- Discord users now receive the reply text and a clear notice when an attachment is too large instead of seeing the completed response disappear. [#99577](https://github.com/nova/nova/pull/99577) Thanks @lin-hongkuan.
- Completed partial-stream Discord replies now arrive as fresh messages that can trigger normal unread cues after a user leaves the channel. [#99711](https://github.com/nova/nova/pull/99711) Thanks @davelutztx.
- Discord completion and error reactions now remain visible for the configured `doneHoldMs` and `errorHoldMs` durations instead of fixed default delays. [#94736](https://github.com/nova/nova/pull/94736) Thanks @liuwqgit.
- Discord voice replies now keep their accompanying text and extra media attached to the original message even when single-use reply mode is enabled. [#95978](https://github.com/nova/nova/pull/95978) Thanks @nxmxbbd.
- Discord attachments queued while Nova is busy now remain available when the message finally runs instead of disappearing after temporary download links expire. [#96183](https://github.com/nova/nova/pull/96183) Thanks @judsonnudson, @zacharyyw.
- Generated Discord thread names now preserve multiple Markdown emphasis spans without dropping or stranding formatting markers. [#96394](https://github.com/nova/nova/pull/96394) Thanks @ly-wang19.
- Discord's recent-model buttons now shorten long names without breaking emoji or producing invalid picker payloads. [#97600](https://github.com/nova/nova/pull/97600) Thanks @llagy007, @weeli-009.
- Long or media-rich implicit Discord replies now quote and notify the referenced user once in `first` or `batched` mode, while explicit and `all` replies retain every intended reference. [#100784](https://github.com/nova/nova/pull/100784) Thanks @qingminglong, @revision-co-ltd.
- Discord replies, cron reports, and other outbound messages are less likely to disappear during a brief Gateway reconnect, without replaying chunks or media Discord already accepted. [#100896](https://github.com/nova/nova/pull/100896) Thanks @tiffanychum.
- Discord automatic thread titles now handle long messages and channel details containing emoji without building malformed prompt text. [#101551](https://github.com/nova/nova/pull/101551) Thanks @alix-007.
- Discord voice playback failures now produce a readable error within the 8,192-byte limit, including when ffmpeg output contains non-English text or emoji. [#104230](https://github.com/nova/nova/pull/104230) Thanks @qingminglong.
- Multiple Discord bot accounts in one server now keep independent voice sessions, and configured voice auto-join works even when Discord becomes ready before voice startup completes. [#87530](https://github.com/nova/nova/pull/87530) Thanks @geekhuashan.
- Checking a Discord member who is not in voice now reports them as disconnected instead of raising a misleading command or gateway failure. [#90969](https://github.com/nova/nova/pull/90969) Thanks @asock.
- Adding a named Discord account no longer knocks a SecretRef-backed default account offline or into a restart loop. [#96401](https://github.com/nova/nova/pull/96401) Thanks @849261680.
- Discord voice conversations in `stt-tts` mode now retain earlier spoken context across turns instead of starting over after each reply. [#97746](https://github.com/nova/nova/pull/97746) Thanks @karabaralex, @sanjays2402.
- Discord voice playback now turns broken ffmpeg output pipes into a normal playback error instead of an uncaught Gateway-level exception. [#101088](https://github.com/nova/nova/pull/101088) Thanks @masatohoshino.
- Discord bots can now recover in place after repeated session-resume rejection, reducing prolonged outages, lost replies, and full Gateway restarts. [#103596](https://github.com/nova/nova/pull/103596)
- Discord voice playback now cleans up ffmpeg after output-pipe failures, reducing both Gateway crashes and leftover transcoder processes. [#101124](https://github.com/nova/nova/pull/101124)
- The configured primary Discord account now starts first in multi-account setups, so the main bot is not delayed behind secondary or invalid entries after a restart. [#101292](https://github.com/nova/nova/pull/101292) Thanks @turbotheturtle.
- Discord message reads and searches now decode raw compressed responses correctly and return clear errors for unexpected data instead of garbled output or opaque failures. [#80788](https://github.com/nova/nova/pull/80788) Thanks @jbetala7.
- Discord REST calls now fail with a clear error when a response is oversized or stalls instead of risking unbounded memory use and process instability. [#95412](https://github.com/nova/nova/pull/95412) Thanks @alix-007.
- Discord account health checks now fail safely on oversized identity responses instead of risking a Gateway crash or out-of-memory failure. [#97278](https://github.com/nova/nova/pull/97278) Thanks @hugenshen.
- Discord message, thread-history, and attachment requests now reject oversized successful responses before they can drive excessive Gateway memory growth. [#97693](https://github.com/nova/nova/pull/97693) Thanks @alix-007.
- Discord PluralKit lookups and voice-upload setup now stop unexpectedly large JSON responses before they can exhaust memory. [#97706](https://github.com/nova/nova/pull/97706) Thanks @cxbasdev.
- Malformed successful Discord responses now fail with endpoint-specific context instead of surfacing a raw parser error or crashing Nova. [#97889](https://github.com/nova/nova/pull/97889) Thanks @lsr911.
- An oversized Discord gateway metadata response now logs a bounded error and falls back to Discord's default gateway URL instead of risking a Gateway crash. [#98682](https://github.com/nova/nova/pull/98682) Thanks @wings1029.
- Discord deployments in restricted networks can now route Gateway and REST traffic through an explicitly configured DNS or private HTTP(S) proxy without opening broad direct HTTPS egress. [#99126](https://github.com/nova/nova/pull/99126) Related [#98266](https://github.com/nova/nova/issues/98266). Thanks @joshavant, @sallyom, @svuppala2006.
- Discord Gateway connections now cap incoming frames at 16 MiB, preserving tested large member events while rejecting extreme traffic before it pressures memory. [#99998](https://github.com/nova/nova/pull/99998) Thanks @sunlit-deng.
- Discord agents now receive `is_bot: true` for admitted bot messages while human and PluralKit sender behavior stays unchanged. [#97824](https://github.com/nova/nova/pull/97824) Thanks @masatohoshino, @vincentkoc.

#### WhatsApp

- Logged-out or replaced WhatsApp accounts now stay stopped until reconnection instead of entering repeated restart loops that can consume resources and slow other accounts. [#78511](https://github.com/nova/nova/pull/78511) Thanks @openperf.
- Eligible WhatsApp messages received during a brief reconnect now reach Nova for an automatic reply instead of being marked read and silently skipped. [#80642](https://github.com/nova/nova/pull/80642) Thanks @vishalj99.
- Concurrent WhatsApp Web replies, media, reactions, and queued messages now send one at a time per account, reducing interference and unpredictable delivery order. [#99050](https://github.com/nova/nova/pull/99050) Thanks @ooiuuii.
- Completed WhatsApp replies now continue delivering when another message arrives mid-delivery, so overlapping conversations are less likely to go unexpectedly silent. [#100205](https://github.com/nova/nova/pull/100205)
- Invalid `NOVA_WHATSAPP_WEB_SOCKET_URL` values now fail immediately with a clear configuration error instead of breaking later during socket startup. [#97697](https://github.com/nova/nova/pull/97697) Thanks @romneyda.
- WhatsApp can now restore a saved linked-device session from a valid credential backup when the primary file is interrupted or corrupted, avoiding an unnecessary QR re-pair. [#99070](https://github.com/nova/nova/pull/99070) Thanks @leonidaslux.
- `nova channels login --channel whatsapp` now replaces expired QR codes in place so interactive terminals show one current, scannable code. [#100159](https://github.com/nova/nova/pull/100159)
- A WhatsApp message interrupted by a temporary reply-session conflict can now be retried instead of being marked delivered and silently ignored on redelivery. [#101106](https://github.com/nova/nova/pull/101106) Thanks @andersonjeccel.
- Nova can use a trusted override to point the normal Baileys socket at a compatible local WebSocket endpoint, while normal WhatsApp connections continue using the default path unless explicitly overridden. [#97155](https://github.com/nova/nova/pull/97155) Thanks @romneyda.
- WhatsApp group owners can reliably use `/new`, `/stop`, `/status`, and similar commands even when their sender identity arrives as an internal LID. [#93379](https://github.com/nova/nova/pull/93379) Related [#77755](https://github.com/nova/nova/issues/77755). Thanks @jiveshkalra, @xialonglee.
- Direct WhatsApp polls now honor the same outreach timelock as other sends instead of reaching recipients during a blocked window. [1d128b4](https://github.com/nova/nova/commit/1d128b4dd23297ee3553142954e4ce0542ba83e6) Thanks @vincentkoc.
- Replies to Nova-authored WhatsApp group messages now remain visible on WhatsApp Desktop and other multi-device clients with their quote context intact. [#94879](https://github.com/nova/nova/pull/94879) Thanks @bartok9.
- WhatsApp direct sends and automatic replies now render combined bold-and-italic Markdown without stray asterisks, including when the formatted text contains emoji. [#96570](https://github.com/nova/nova/pull/96570) Thanks @llagy007, @weeli-009.
- Long WhatsApp auto-reply and inbound-message previews now preserve emoji and report the truncated character count accurately, making affected diagnostics readable without changing delivery. [#96580](https://github.com/nova/nova/pull/96580) Thanks @llagy007, @weeli-009.
- WhatsApp direct messages blocked by a reachout timelock now fail immediately with an explicit explanation instead of appearing accepted before a later delivery error. [#101264](https://github.com/nova/nova/pull/101264) Thanks @mcaxtr.

- With `channels.whatsapp.actions.calls`, MeowCaller, and telephony TTS configured, a WhatsApp agent can now call the requester and speak a short task-completion or urgent message. [#99635](https://github.com/nova/nova/pull/99635)

#### Weixin

- Configured Weixin accounts with opaque IDs containing characters such as an at sign or `.` now start normally and preserve their account-specific routing. [#93686](https://github.com/nova/nova/pull/93686) Related [#93556](https://github.com/nova/nova/issues/93556). Thanks @htkillermax-gif, @zhangguiping-xydt.
- Official Weixin installs and core-upgrade reconciliation now target plugin version 2.4.6 with its correct compatibility requirement instead of unexpectedly returning users to 2.4.3. [#96801](https://github.com/nova/nova/pull/96801) Thanks @lin-hongkuan.

#### Apple Messages

- Compatible iMessage bridge users can create, read, and vote on native Apple Messages polls, with upgrade guidance for unsupported `imsg` installations. [#98421](https://github.com/nova/nova/pull/98421) Thanks @lobster, @omarshahine.
- Photos bridged from a remote iMessage Mac to a separate Gateway host now arrive in Codex conversations through a readable local path rather than a Mac-only filename. [#91803](https://github.com/nova/nova/pull/91803) Thanks @turbotheturtle.
- Voting for an emoji-labeled iMessage poll option no longer sends an extra one-word message that repeats the selected answer. [#98691](https://github.com/nova/nova/pull/98691) Thanks @omarshahine.
- Agents now answer iMessage polls, including polls with comments, with one native vote instead of an ordinary text answer, a repeated selection, or a separate reply to the comment. [#98781](https://github.com/nova/nova/pull/98781) Thanks @omarshahine.
- AppleScript-only and bot-user or SSH iMessage setups now deliver replies even when threading is unavailable, and database changes no longer leave inbound messages hidden behind stale recovery state. [#100446](https://github.com/nova/nova/pull/100446) Thanks @omarshahine.
- Direct iMessage chats using the `imsg` private API bridge now show typing as soon as a slow turn is accepted, without waiting for a read receipt. [#95621](https://github.com/nova/nova/pull/95621) Thanks @omarshahine.
- iMessage replies no longer lose ordinary sentence text that happens to end with `user:`, `system:`, or `assistant:`. [#96392](https://github.com/nova/nova/pull/96392) Thanks @ly-wang19.
- Bursts of long iMessage messages can now be combined without cutting an emoji in half and sending broken text to the agent. [#97598](https://github.com/nova/nova/pull/97598) Thanks @weeli-009.
- iMessage startup warnings now distinguish working sender-allowlisted group setups from truly blocked configurations and point blocked operators to the correct fix. [#100046](https://github.com/nova/nova/pull/100046)
- Bare 32-character iMessage group IDs from `imsg` now route scheduled and direct sends to the intended conversation instead of a nonexistent phone number. [#99525](https://github.com/nova/nova/pull/99525) Related [#89235](https://github.com/nova/nova/issues/89235). Thanks @matthewdelprado.
- An iMessage helper pipe failure now ends pending work predictably and lets the monitor recover or stop cleanly instead of crashing the Gateway or hanging requests. [#101084](https://github.com/nova/nova/pull/101084) Thanks @masatohoshino.
- iMessage CLI send and action failures caused by broken output pipes now return a controlled error instead of risking a Gateway worker crash. [#101401](https://github.com/nova/nova/pull/101401) Thanks @cxbasdev.

#### LINE

- Default and named LINE bots configured under `channels.line.accounts` now receive working webhook routes unless explicitly disabled, preventing valid inbound messages from ending in 404 responses. [#81471](https://github.com/nova/nova/pull/81471) Thanks @edenfunf, @honorlin.
- LINE file uploads now retain recognizable audio extensions such as `.m4a`, allowing valid recordings to reach transcription instead of being treated as unknown files. [#96403](https://github.com/nova/nova/pull/96403) Thanks @tancolo, @zaidazmi.
- LINE template titles, fallback text, and alt text now keep emoji intact at field limits, preventing broken previews and rejected payloads. [#97428](https://github.com/nova/nova/pull/97428) Thanks @ly-wang19, @vincentkoc.
- Long LINE button labels, quick replies, postback data, and media controls now preserve emoji at field limits instead of producing malformed text. [#97470](https://github.com/nova/nova/pull/97470) Thanks @ly-wang19, @vincentkoc.
- LINE messages, cards, menus, locations, and code blocks now preserve emoji and other multi-unit characters at field limits instead of producing broken text or rejected payloads. [#98994](https://github.com/nova/nova/pull/98994) Thanks @lexes7, @vincentkoc.
- LINE replies that combine text with an image, card, or location now report a failed rich-media portion accurately while delivering the text once and avoiding duplicate retries. [#100996](https://github.com/nova/nova/pull/100996) Thanks @masatohoshino.

#### Feishu

- Feishu replies now arrive as completed blocks when block streaming is enabled without streaming cards, rather than disappearing entirely. [#94250](https://github.com/nova/nova/pull/94250) Related [#55027](https://github.com/nova/nova/issues/55027). Thanks @vincentkoc, @xialonglee, @zichaolong.
- When an interactive command button falls back to text, users now receive the command they can copy, with Feishu document comments explaining the manual step. [#94385](https://github.com/nova/nova/pull/94385) Related [#69754](https://github.com/nova/nova/issues/69754). Thanks @1yihui, @xialonglee.
- `nova channels login --channel feishu` now prints a compact QR code that stays scannable in a normal terminal window. [#97087](https://github.com/nova/nova/pull/97087) Thanks @nianjiuzst.
- Long Feishu streaming-card summaries now keep emoji and other non-BMP characters intact at the truncation boundary. [#97462](https://github.com/nova/nova/pull/97462) Thanks @ly-wang19.
- Long Feishu comments containing emoji at the cutoff now reach the agent as valid text instead of being split into malformed characters. [#97595](https://github.com/nova/nova/pull/97595) Thanks @llagy007, @weeli-009.
- Feishu and Lark registration and streaming-card requests now reject oversized provider JSON before it can place unbounded pressure on memory. [#97782](https://github.com/nova/nova/pull/97782) Thanks @alix-007.
- Supported interactive-card JSON sent through Feishu messages, thread replies, or text payloads now renders as a card instead of appearing as raw JSON. [#100883](https://github.com/nova/nova/pull/100883) Thanks @martingarramon, @vincentkoc, @zenorewn.
- Stalled Feishu tenant-token or streaming-card requests now time out with a clear error and release the processing lane so other Gateway messages can continue. [#102948](https://github.com/nova/nova/pull/102948) Thanks @hugenshen, @sallyom.
- Feishu setups that could send bot pushes but silently lost user replies now pass incoming messages into Nova instead of failing during monitor startup. [#94013](https://github.com/nova/nova/pull/94013) Thanks @xydt-tanshanshan.
- Feishu one-to-one chats can receive text, media, card, and fallback replies again instead of losing the response after the incoming message was processed. [#94760](https://github.com/nova/nova/pull/94760) Thanks @obviyus, @xydigit-zt.
- Feishu card headers now show a clean agent emoji and name instead of descriptive text from `identity.emoji`, while flags, skin-tone variants, family emoji, and other valid sequences remain intact. [#96587](https://github.com/nova/nova/pull/96587) Thanks @harjothkhara, @leedongyu1128.
- Feishu video messages now show the duration of local and remotely loaded MP4 clips when duration detection is available. [#98235](https://github.com/nova/nova/pull/98235) Thanks @areslp.
- Temporary Feishu streaming-card refresh failures are now contained and logged for diagnosis instead of surfacing as unhandled errors. [#99301](https://github.com/nova/nova/pull/99301) Thanks @lwy-2.
- Feishu direct messages received while the bot identity is temporarily unavailable no longer turn ordinary user mentions into accidental forwarding targets. [#100891](https://github.com/nova/nova/pull/100891) Thanks @zhangguiping-xydt.
- Feishu error logs now shorten emoji-containing text at a valid character boundary, making card-action and WebSocket cleanup failures easier to read. [#101364](https://github.com/nova/nova/pull/101364) Thanks @zengwen-dt.
- Feishu Drive can now list files beyond the first page of a large shared folder by accepting its returned `next_page_token`, with invalid page sizes rejected clearly before the request. [#101572](https://github.com/nova/nova/pull/101572) Thanks @zhangguiping-xydt.
- A Feishu connection that stops receiving messages is less likely to remain falsely marked healthy because transport activity now updates channel health. [#90966](https://github.com/nova/nova/pull/90966) Thanks @acache, @richardataxai-lab, @vincentkoc.
- Canceling a Feishu reconnect, startup, or bot-identity retry wait now ends cleanly instead of risking a `ReferenceError` during cleanup. [#98137](https://github.com/nova/nova/pull/98137) Thanks @zhanglei99586.
- Feishu bot replies no longer expose internal tool or runtime failure banners alongside the intended response. [#98705](https://github.com/nova/nova/pull/98705) Thanks @zengwen-dt.

- Multi-account Feishu setups can now start the default channel with an environment-backed top-level SecretRef and separate inline secrets for named accounts, without replacing the protected secret with plaintext. [#96965](https://github.com/nova/nova/pull/96965) Thanks @zw-xysk.

#### Google Chat

- Google Chat sends and request verification now bound oversized API, certificate, and error responses, allowing normal traffic through while broken or hostile bodies fail or truncate without exhausting memory. [#96772](https://github.com/nova/nova/pull/96772) Thanks @vincentkoc, @wangmiao0668000666.
- Google Chat agents can now distinguish allowed bot messages through `is_bot: true` and handle automated senders differently from people. [#97825](https://github.com/nova/nova/pull/97825) Thanks @masatohoshino, @vincentkoc.
- Long Google Chat approval cards now preserve emoji at the text limit, preventing corrupted approval text or malformed card payloads. [#96573](https://github.com/nova/nova/pull/96573) Thanks @llagy007, @weeli-009.

#### Google Meet

- Google Meet join, creation, talk-back, transcription, and related automation now work across browser and account languages by using English in Nova-controlled Meet tabs. [#89671](https://github.com/nova/nova/pull/89671) Thanks @unayung.
- Google Meet sessions launched through a paired macOS Chrome node now open the intended URL with the configured Chrome profile and audio tools, while unsupported actions and executable overrides are rejected before reaching the node. [#96908](https://github.com/nova/nova/pull/96908) Thanks @joshavant.
- When Google Meet's local OAuth callback port is occupied, `nova meet auth login` now offers the manual redirect-paste flow instead of stopping sign-in. [#96492](https://github.com/nova/nova/pull/96492) Thanks @jinduwang1001-max, @yetval.

#### Microsoft Teams

- Microsoft Teams replies to long parent messages now keep emoji and similar characters intact in the agent's parent-message context instead of inserting malformed text. [#96569](https://github.com/nova/nova/pull/96569) Thanks @llagy007, @weeli-009.
- Microsoft Teams Adaptive Card button clicks now deliver the submitted value to the agent instead of arriving as empty messages. [#97546](https://github.com/nova/nova/pull/97546) Thanks @jimmypuckett.
- Microsoft Teams file delivery and chat lookup now cap large Microsoft Graph responses and return a labeled error instead of risking a process crash. [#97784](https://github.com/nova/nova/pull/97784) Thanks @alix-007.
- Microsoft Teams attachment recovery now declines oversized Graph metadata with diagnostics instead of buffering it into Gateway memory, while normal hosted media still downloads within configured limits. [#101082](https://github.com/nova/nova/pull/101082) Thanks @cxbasdev.
- The Microsoft Teams personal-chat welcome card now displays its greeting with the intended bold, medium emphasis. [#96290](https://github.com/nova/nova/pull/96290) Thanks @ly-wang19, @vincentkoc.
- Microsoft Teams thread history now preserves literal entity text such as `&lt;APIKEY&gt;` instead of turning it into different markup before the agent sees it. [#96342](https://github.com/nova/nova/pull/96342) Thanks @ly-wang19.
- Microsoft Teams feedback on long responses now carries intact emoji into reflection processing, preventing a cutoff from corrupting prompts, logs, or encoding. [#96578](https://github.com/nova/nova/pull/96578) Thanks @llagy007, @weeli-009.

- Oversized or malformed Microsoft Teams personal-chat attachment metadata now fails safely with a warning instead of consuming unbounded Gateway memory. [#99125](https://github.com/nova/nova/pull/99125) Thanks @ly85206559.

#### Matrix

- Long Matrix thread starters keep emoji and other special characters intact when Nova shortens them for agent context. [#97121](https://github.com/nova/nova/pull/97121) Thanks @bartok9, @ly-wang19.
- Matrix operators now receive a structured warning when token rotations leave multiple populated storage roots, with details for identifying and carefully archiving stale folders. [#97353](https://github.com/nova/nova/pull/97353) Thanks @eldron81-r2d2, @outdog-hwh.
- Long Matrix reply quotes sent to agents now truncate emoji and other multi-unit characters without leaving broken text. [#97471](https://github.com/nova/nova/pull/97471) Thanks @ly-wang19.
- Matrix media downloads now enforce size and idle-timeout limits before buffering, including for encrypted media. [#97662](https://github.com/nova/nova/pull/97662) Thanks @alix-007.
- Malformed successful Matrix responses now produce a controlled homeserver error instead of an opaque unhandled JSON parsing failure. [#97973](https://github.com/nova/nova/pull/97973) Thanks @lsr911.
- Matrix dependency setup now stops its child process predictably and reports the failure when a local command's output pipe breaks. [#101597](https://github.com/nova/nova/pull/101597) Thanks @alix-007.
- Matrix replies now deliver the intended answer without leaking internal tool diagnostics, reasoning tags, or assistant-only scaffolding. [#97372](https://github.com/nova/nova/pull/97372) Thanks @masatohoshino.

#### Mattermost

- Mattermost streaming draft previews now shorten long text containing emoji without showing a malformed replacement character. [#97472](https://github.com/nova/nova/pull/97472) Thanks @ly-wang19.
- Mattermost channel monitoring now rejects inbound events above 16 MiB and reconnects, limiting memory exposure while continuing to accept normal large messages. [#99366](https://github.com/nova/nova/pull/99366) Thanks @sunlit-deng.
- Mattermost API calls now stop oversized or endless successful responses before they can consume unbounded memory, while normal requests and uploads continue unchanged. [#96033](https://github.com/nova/nova/pull/96033) Thanks @alix-007.
- Mattermost API failures with an empty JSON body now produce a clear status-based error instead of an `Unexpected end of JSON input` crash. [#97851](https://github.com/nova/nova/pull/97851) Thanks @pick-cat.
- Mattermost installations repaired after an upgrade now load and reconnect on Gateway restart without requiring a manual plugin-enable setting, including restrictive allowlist setups. [#98608](https://github.com/nova/nova/pull/98608) Related [#98564](https://github.com/nova/nova/issues/98564). Thanks @jacobtomlinson, @shakkernerd.
- Mattermost teams with more than 200 members can now discover and address valid peers beyond the first page of the team directory. [#98877](https://github.com/nova/nova/pull/98877) Related [#98871](https://github.com/nova/nova/issues/98871). Thanks @qingminglong.
- Mattermost replies now show the intended assistant response without exposing internal tool-failure diagnostics. [#98693](https://github.com/nova/nova/pull/98693) Thanks @zengwen-dt.

- Native `/oc_*` Mattermost commands work again in packaged installs using `nova/mattermost`, without allowing disabled or denied plugins to bypass Gateway checks. [#98819](https://github.com/nova/nova/pull/98819) Related [#98740](https://github.com/nova/nova/issues/98740). Thanks @amknight, @keltech-services.

#### Nextcloud

- Nextcloud Talk sends and reactions now bound server response sizes, protecting Nova from hangs or runaway memory use while preserving normal delivery. [#96031](https://github.com/nova/nova/pull/96031) Thanks @alix-007.
- Nextcloud Talk startup checks now show a concise bot-admin API failure without buffering an arbitrarily large error body. [#97811](https://github.com/nova/nova/pull/97811) Thanks @pick-cat.

#### IRC

- Long IRC messages now keep emoji and other supplementary characters intact when split into delivery chunks, including with unusually small configured chunk limits. [#96572](https://github.com/nova/nova/pull/96572) Thanks @llagy007, @weeli-009.
- IRC reconnects now rotate fallback nicknames after a 433 conflict instead of repeatedly retrying the same occupied name. [#96108](https://github.com/nova/nova/pull/96108) Thanks @wendy-chsy.
- IRC outbound text now preserves escaped emoji and keeps invalid surrogate escapes literal instead of silently replacing them with corrupted characters. [#97683](https://github.com/nova/nova/pull/97683) Thanks @llagy007, @weeli-009.
- Long IRC replies now arrive complete when they contain Chinese, Cyrillic, emoji, or other non-ASCII text, while respecting `messageChunkMaxChars`. [#99138](https://github.com/nova/nova/pull/99138) Thanks @yetval.
- IRC bots now reconnect and rejoin configured channels after a temporary server or network disconnect instead of staying silent until Nova is restarted. [#100799](https://github.com/nova/nova/pull/100799) Thanks @zhangguiping-xydt.
- IRC users now receive the intended answer without internal tool-failure banners or assistant-only scaffolding appearing in channel messages. [#97214](https://github.com/nova/nova/pull/97214) Thanks @masatohoshino, @studentzhou-svg, @vincentkoc.

- IRC allowlists now reject host-less `nick!user` entries by default and guide operators toward verified full host masks, reducing impersonation risk. [#98339](https://github.com/nova/nova/pull/98339) Thanks @yetval.

#### SMS

- Twilio SMS account checks now handle malformed successful JSON with safe phone-number listing or a clear Messaging Service error. [#97999](https://github.com/nova/nova/pull/97999) Thanks @lsr911.
- SMS replies now hide internal tool-trace failure banners and show only the intended assistant response. [#97989](https://github.com/nova/nova/pull/97989) Thanks @zengwen-dt.

#### Synology

- Long Synology Chat messages and diagnostic previews now truncate without cutting an emoji or other supplementary character in half, keeping downstream text valid. [#96574](https://github.com/nova/nova/pull/96574) Thanks @weeli-009.

#### Zalo

- Zalo setup, polling, sending, and health checks now reject abnormally large successful replies before they can push the Gateway into severe memory pressure. [#97277](https://github.com/nova/nova/pull/97277) Thanks @hugenshen.
- Zalo operators can point Bot API calls at a compatible alternate endpoint without patching code, while ordinary workspace environment files cannot silently redirect traffic and millisecond message times remain accurate. [#98768](https://github.com/nova/nova/pull/98768) Thanks @romneyda.
- Zalo gateway startup output now shows the connected bot account name when the Bot Platform supplies it. [#99274](https://github.com/nova/nova/pull/99274) Thanks @romneyda.
- Zalo operators can send proactive CLI or scripted messages to valid nonnumeric `chat_id` values without an `Unknown target` rejection. [#101548](https://github.com/nova/nova/pull/101548) Thanks @goutamadwant.

#### QQBot

- QQBot upgrades now migrate recoverable credential backups into SQLite without deleting source files when import fails, while disposable caches rebuild separately. [#89597](https://github.com/nova/nova/pull/89597)
- QQBot can now deliver documents and media created by sandboxed agents from authorized workspace paths while continuing to block path escapes. [#92872](https://github.com/nova/nova/pull/92872) Thanks @sliverp, @zhangguiping-xydt.
- QQBot speech-to-text now returns an early, labelled error when an OpenAI-compatible transcription endpoint sends an oversized response instead of buffering the full body in memory. [#96968](https://github.com/nova/nova/pull/96968) Thanks @mushuiyu886.
- QQBot Markdown tables now keep escaped pipe characters inside their cells, so commands and expressions do not shift into the wrong columns. [#97429](https://github.com/nova/nova/pull/97429) Thanks @ly-wang19.
- QQBot reminders created from long text now receive readable job names even when an emoji falls at the cutoff, rather than storing a broken character. [#96575](https://github.com/nova/nova/pull/96575) Thanks @llagy007, @weeli-009.
- QQBot status now reports disconnections and fatal close reasons accurately, then returns to connected only after a READY or RESUMED event. [#100127](https://github.com/nova/nova/pull/100127) Thanks @masatohoshino, @vincentkoc.
- QQBot approval cards, message previews, logs, media paths, and retry warnings now shorten emoji-containing text without broken replacement characters. [#101421](https://github.com/nova/nova/pull/101421) Thanks @wangmiao0668000666.
- QQBot previews, errors, commands, speech-to-text messages, media diagnostics, and logs now remain valid when emoji-containing text reaches a length limit. [#101516](https://github.com/nova/nova/pull/101516) Thanks @vincentkoc, @wangmiao0668000666.

- QQBot now avoids accidental reminders, limits exposure of private media details, and requires explicit confirmation before destructive channel or announcement actions. [#98032](https://github.com/nova/nova/pull/98032) Thanks @patrick-erichsen.

#### Tlon and Urbit

- Tlon and Urbit channel failures now bound oversized or malformed error responses before they can cause memory spikes, while retaining useful short messages. [#98496](https://github.com/nova/nova/pull/98496) Thanks @pandah97.
- Tlon now stops oversized or stalled external image downloads before they consume unbounded memory and can continue the message with the original URL. [#100374](https://github.com/nova/nova/pull/100374) Thanks @hugenshen.
- Oversized Tlon scry responses now fail with a clear path-specific error instead of risking a Gateway out-of-memory crash. [#100376](https://github.com/nova/nova/pull/100376) Thanks @hugenshen.
- Tlon approval notifications now keep emoji intact at the preview limit, preventing malformed message previews. [#97599](https://github.com/nova/nova/pull/97599) Thanks @llagy007, @weeli-009.
- Tlon media uploads now stop safely when Memex returns an oversized or malformed response instead of allowing the upload attempt to consume excessive memory. [#101115](https://github.com/nova/nova/pull/101115) Thanks @cxbasdev.

#### Nostr

- Repeated Nostr profile publishing now clears relay timeout timers after success, reducing stale resource buildup in long-running agents. [#98720](https://github.com/nova/nova/pull/98720) Related [#98463](https://github.com/nova/nova/issues/98463). Thanks @wangmiao0668000666, @zhanglei99586.

#### Voice Calls

- Google Meet and direct Voice Call sessions now keep the identity, workspace, routing, and transcript attribution of the agent that started the call instead of silently switching to the default agent. [#77763](https://github.com/nova/nova/pull/77763) Thanks @quangtran88.
- Google Live call history now keeps both sides of the conversation, while reconnects avoid submitting unfinished speech or combining unrelated utterances. [#84161](https://github.com/nova/nova/pull/84161)
- OpenAI Realtime outbound calls now play one opening greeting even when the recipient speaks immediately after answering, while later interruptions continue to stop active speech. [#86285](https://github.com/nova/nova/pull/86285) Thanks @giodl73-repo, @jnikolaidis.
- Callers using realtime OpenAI or Google voice calls can now interrupt assistant speech and have buffered phone audio stop promptly, while other providers keep the existing local fallback. [#90749](https://github.com/nova/nova/pull/90749) Thanks @moellenbeck.
- Voice callers now hear a completed answer without waiting for post-turn compaction, and a successful early playback is no longer repeated. [#94015](https://github.com/nova/nova/pull/94015) Thanks @xialonglee.
- Twilio voice-call operators can select US1, IE1, or AU1 so call control and records use the intended Region, with US1 remaining the default. [#95832](https://github.com/nova/nova/pull/95832) Thanks @jodok.
- Inbound Telnyx-style and Plivo voice conversations can now continue after the caller's first response instead of falling silent before Nova speaks again. [#100255](https://github.com/nova/nova/pull/100255) Thanks @dvy.
- Valid Twilio and Plivo callbacks now pass signature checks behind trusted IPv4 reverse proxies even when Node reports the proxy as an IPv4-mapped IPv6 address. [#100261](https://github.com/nova/nova/pull/100261) Thanks @rohitjavvadi.
- Repeated voice-call webhook deliveries are now acknowledged without repeating call or transcript side effects within the replay window. [#100263](https://github.com/nova/nova/pull/100263) Thanks @xialonglee.
- The Twilio voice-call provider now rejects unsupported API hostnames before sending a request and accepts only Nova's supported Twilio regional hosts. [094c0d4](https://github.com/nova/nova/commit/094c0d421faff7691d259a26af9cb135f00c6ebc) Thanks @vincentkoc.
- An accepted voice message that arrives while Nova is already replying can still receive a voice response when `tts.auto: "inbound"` is configured. [#95596](https://github.com/nova/nova/pull/95596) Thanks @mcaxtr.
- Realtime voice prompts now remain readable when long agent names or injected context containing emoji must be shortened. [#101304](https://github.com/nova/nova/pull/101304) Thanks @alix-007.
- Google Meet local audio bridges now shut down cleanly and log a warning when a capture or playback command pipe fails, rather than crashing on an unhandled stream error. [#101596](https://github.com/nova/nova/pull/101596) Thanks @alix-007.

- Voice Call history now stays with the correct configured agent across Gateway restarts and upgrades, while ambiguous legacy state is left untouched with actionable warnings. [#89884](https://github.com/nova/nova/pull/89884) Thanks @mushuiyu886.
- Completed Voice Call status remains available through the Gateway, tool, and CLI after restart or eviction instead of incorrectly appearing missing. [#99797](https://github.com/nova/nova/pull/99797) Thanks @darren2030.

#### ClickClack

- ClickClack agent replies to top-level messages now stay in the active channel or direct message, while replies inside real threads remain threaded. [#100582](https://github.com/nova/nova/pull/100582) Thanks @marvinthebored, @vincentkoc.
- ClickClack can now show opt-in, durable commentary and tool activity during a run so users are not left with an empty channel until the final reply. [#99954](https://github.com/nova/nova/pull/99954) Thanks @obviyus, @ragesaq.

- ClickClack now stops oversized REST success responses at the provider limit, giving users and operators a predictable failure instead of continued streaming and memory growth. [#96970](https://github.com/nova/nova/pull/96970) Thanks @mushuiyu886, @vincentkoc.

#### Shared channel improvements

- Messages that fail before reaching Discord, Slack, Matrix, or another channel can now be replayed after connectivity returns, while uncertain post-send outcomes still avoid blind duplicates. [#101024](https://github.com/nova/nova/pull/101024) Thanks @sunnyshu0925.
- Messages sent through Nova's message tool now retain configured static or identity response prefixes, keeping routed and broadcast messages consistently labeled. [#93639](https://github.com/nova/nova/pull/93639) Thanks @zengwen-dt.
- Completions from subagents, scheduled tasks, media jobs, and agent harnesses now return through the same configured account, destination, and thread that requested them. [#98240](https://github.com/nova/nova/pull/98240) Thanks @yetval.
- Replies and attachments already accepted by a channel are no longer resent after a restart or recovery failure, while genuinely unsent items remain retryable. [#99600](https://github.com/nova/nova/pull/99600) Thanks @zhangguiping-xydt.
- Outbound sends now report failed and partially delivered messages with useful per-part outcomes instead of presenting every attempt as a success. [#99928](https://github.com/nova/nova/pull/99928) Thanks @masatohoshino.
- Non-streaming channels no longer send the same final text or media twice for one message, while genuinely separate replies with different routing or thread identities still go through. [#100828](https://github.com/nova/nova/pull/100828) Thanks @vincentkoc, @zhangxiaojiujiayi.
- Cron and outbound channel sends no longer report success without a usable platform receipt, making missing notifications show as not delivered or suppressed instead of falsely delivered. [#79811](https://github.com/nova/nova/pull/79811) Thanks @indulgeback.
- Queued messages now resume at a gentler pace after an outage, restart, or reconnect, reducing avoidable channel and provider rate-limit bursts while keeping recovery bounded. [#101118](https://github.com/nova/nova/pull/101118) Thanks @zengwen-dt.
- Noisy phone numbers with extra plus signs now match the intended Signal, iMessage, or WhatsApp contact, while identities with no digits are rejected safely. [#100467](https://github.com/nova/nova/pull/100467) Thanks @morluto.
- Reply directives containing hidden unsafe characters now produce stable, display-safe reply IDs before chat routing uses them. [#96446](https://github.com/nova/nova/pull/96446) Thanks @lin-hongkuan.
- Ambient agents now stay quieter in observed group conversations and honor operator instructions such as replying only when spoken to. [#99144](https://github.com/nova/nova/pull/99144) Thanks @obviyus.
- Ambient group chats now remain silent unless the agent deliberately sends a message, without stray status lines, tool summaries, compaction notices, delivery warnings, or overflow follow-ups. [#99145](https://github.com/nova/nova/pull/99145) Thanks @obviyus.
- Always-on group agents can now receive and answer valid unmentioned messages after a plugin fallback instead of silently dropping them. [#99506](https://github.com/nova/nova/pull/99506) Related [#99457](https://github.com/nova/nova/issues/99457). Thanks @lzy3538, @zqchris.
- Agents catching up in busy group chats now receive clearer sender-by-sender history, making multi-person conversations easier to follow without exposing local paths or URLs. [#100366](https://github.com/nova/nova/pull/100366) Thanks @gorkem2020.
- Telegram and Discord plugin commands that send their own response can return `{ suppressReply: true }`, preventing a second misleading empty-response warning or failure. [#80928](https://github.com/nova/nova/pull/80928) Related [#80756](https://github.com/nova/nova/issues/80756). Thanks @alexuser, @unclouded77.
- With `messages.ackReactionScope: "all"`, ambient room messages now receive the configured acknowledgement reaction across Discord, Slack, and Telegram. [#87433](https://github.com/nova/nova/pull/87433) Thanks @paul-phan, @scoootscooob.
- Channel plugins can resume automatic recovery after a long healthy run, so an occasional later disconnect is not blocked by an old restart budget while true rapid crash loops remain capped. [#101413](https://github.com/nova/nova/pull/101413) Thanks @clintoncodewell.
- Telegram and other channels can recover automatically after certain API outages and timed-out shutdowns instead of remaining silent until a Gateway restart. [#94016](https://github.com/nova/nova/pull/94016) Thanks @sheyanmin.
- A partially delivered queued send is no longer blindly replayed after reconnect, reducing duplicate Telegram and other channel messages. [#96247](https://github.com/nova/nova/pull/96247) Thanks @obviyus, @rosenlo.
- Discord and other progress views now hide repetitive internal Code Mode polling while continuing to show meaningful tool activity. [#99893](https://github.com/nova/nova/pull/99893)
- Long-running Discord and Nextcloud Talk integrations now bound their channel metadata caches instead of letting each newly encountered room increase memory use forever. [#101650](https://github.com/nova/nova/pull/101650) Thanks @alix-007, @vincentkoc.
- A transient Gmail watch-renewal failure now produces an error without crashing a long-running foreground `nova webhooks gmail run` process. [#100342](https://github.com/nova/nova/pull/100342) Thanks @cxbasdev, @vincentkoc.
- Channel previews, thread names, snippets, and shortened errors across browser and messaging integrations now preserve whole emoji and other Unicode characters. [c16bb87](https://github.com/nova/nova/commit/c16bb8725a8a04d5de92855769cf87e13574384f) Thanks @vincentkoc.
- Long Slack context labels, Zalo messages and captions, and extension command output now truncate without breaking emoji or other non-BMP characters. [7e03242](https://github.com/nova/nova/commit/7e0324263b867d3d47138d1d2b1e9afd1dd2016f) Thanks @hugenshen, @mushuiyu886, @vincentkoc.
- Fenced code blocks that contain example lines resembling Markdown fence markers are now kept together instead of being split mid-block and becoming confusing or misread. [#96745](https://github.com/nova/nova/pull/96745) Thanks @ly-wang19, @vincentkoc.
- Long unbroken messages now keep emoji intact when split into delivery-sized chunks, preventing garbled replacement characters for users and channel plugins. [#96951](https://github.com/nova/nova/pull/96951) Thanks @bartok9, @ly-wang19.
- Skill command descriptions now remain fuller where supported and stay valid in Discord and Mattermost when emoji appears near a platform limit. [#99593](https://github.com/nova/nova/pull/99593) Thanks @pick-cat.
- Long emoji-containing agent labels now produce clean native channel thread names and introductions instead of broken characters. [#101527](https://github.com/nova/nova/pull/101527) Thanks @lsr911.
- Chinese, Japanese, and Korean bold labels followed immediately by text now render as bold instead of exposing literal `**` markers in Telegram and other shared-Markdown channels. [#101230](https://github.com/nova/nova/pull/101230) Thanks @nicknmorty.
- Attachment download failures across WhatsApp, LINE, Signal, iMessage, Teams, Feishu, Mattermost, and Zalo now remain visible and actionable instead of disappearing or masquerading as successful media. [#100119](https://github.com/nova/nova/pull/100119)
- Nova now recognizes `.m2a` recordings as audio, allowing them to move through attachment, transcription, memory, and chat display workflows without conversion. [#92167](https://github.com/nova/nova/pull/92167) Thanks @llljjjwww333.
- Files sent through Telegram and other supported chat channels now keep clean names such as `report.png` instead of exposing an internal cache identifier in the attachment filename. [#96565](https://github.com/nova/nova/pull/96565) Thanks @narahariraghava, @obviyus.
- Cron summaries, Teams and Slack replies, and other embedded assistant responses no longer expose provider reasoning markers such as `&lt;/mm:think&gt;`. [#101036](https://github.com/nova/nova/pull/101036) Thanks @velanir-ai-manager.
- Punctuation around a model's `NO_REPLY` token no longer turns it into a visible chat message, while legitimate messages containing the token still arrive. [#98224](https://github.com/nova/nova/pull/98224) Thanks @sunnyshu0925.
- Slack, Discord, Telegram, WhatsApp, and Microsoft Teams users now receive a clear retry and re-authentication message when a model provider returns a recognized HTTP 401 error instead of seeing only a reaction or no useful reply. [#96599](https://github.com/nova/nova/pull/96599) Thanks @sjf-oa.
- Text commands such as `/model fable` now reliably display their confirmation even in flows that suppress ordinary source replies. [#100151](https://github.com/nova/nova/pull/100151)
- The bare `/think` command now shows available thinking levels promptly in Telegram, Slack, and Discord without waiting on slow model discovery. [#101926](https://github.com/nova/nova/pull/101926) Thanks @vincentkoc.
- Direct mentions to Telegram and Discord group bots using `message_tool_only` now produce visible channel replies on both new and resumed sessions. [#99389](https://github.com/nova/nova/pull/99389) Related [#99371](https://github.com/nova/nova/issues/99371). Thanks @obviyus.

- The `/usage full` footer is shorter and easier to read on Telegram and other narrow displays, with detailed token information still available through dedicated views. [#92877](https://github.com/nova/nova/pull/92877) Thanks @marvinthebored.
- Custom usage footers now render alias and map fallbacks correctly even when model or mode names collide with properties such as `toString` or `constructor`. [#98503](https://github.com/nova/nova/pull/98503) Related [#98466](https://github.com/nova/nova/issues/98466). Thanks @chenyangjun-xy, @zhanglei99586.
- Transient stdout or stderr read errors from `gog gmail watch serve` no longer crash Nova while Gmail watch mode is running. [#100519](https://github.com/nova/nova/pull/100519) Thanks @cxbasdev.

### Providers and Models

Across Anthropic and Claude, Gemini, OpenAI and Codex, local models, and other supported routes, [providers](https://docs.nova.ai/concepts/model-providers) now handle credentials, catalogs, limits, fallbacks, streaming, and tool calls more consistently. Readers should see fewer requests fail because the selected route used the wrong model metadata, replayed incompatible reasoning, lost authentication state, or interpreted a provider response incorrectly.

The [model catalog](https://docs.nova.ai/concepts/models) also reports availability and capability more accurately, while [Codex supervision](https://docs.nova.ai/plugins/codex-supervision) keeps connected model choices and session behavior aligned with the backend that was actually selected.

#### Provider setup and model selection

##### New providers and integrations

- OpenCode Zen users can browse and run its supported Claude, GPT, Gemini, GLM, DeepSeek, MiniMax, Qwen, and other models without manually defining each route. [#92495](https://github.com/nova/nova/pull/92495) Thanks @mushuiyu886, @sallyom.
- Library and integration developers can now install a version-matched package, create independent AI runtimes, and reuse Nova's supported model transports without embedding the full application. [#99059](https://github.com/nova/nova/pull/99059)
- Featherless AI now has an official provider install and onboarding path, including `FEATHERLESS_API_KEY`, a curated `featherless/Qwen/Qwen3-32B` default, and support for exact Featherless model IDs. [#101092](https://github.com/nova/nova/pull/101092) Thanks @vincentkoc.
- Meta Model API is now exposed through the public `meta` provider, with `meta/muse-spark-1.1`, canonical provider docs, and standalone npm or ClawHub installation paths. [#103070](https://github.com/nova/nova/pull/103070) Thanks @vincentkoc.
- The bundled Meta provider now uses `https://api.meta.ai/v1`, advertises Muse Spark 1.1's documented 131,072-token output limit, and applies official-host request protections. [#103680](https://github.com/nova/nova/pull/103680) Thanks @vincentkoc.

##### Anthropic, Google, and OpenAI setup

- Claude Fable 5 now works through Anthropic Vertex for simple-completion tasks such as generated conversation labels instead of failing before the request reaches Vertex. [#98932](https://github.com/nova/nova/pull/98932)
- Claude CLI users can combine multiple `--mcp-config` files without losing servers or corrupting the prompt, and concurrent Gemini CLI runs are less likely to interfere with shared credential files. [#98983](https://github.com/nova/nova/pull/98983) Related [#98944](https://github.com/nova/nova/issues/98944), [#98945](https://github.com/nova/nova/issues/98945). Thanks @obviyus.
- Google image generation can now use `models.providers.google.apiKey` and an optional custom `baseUrl` without separate environment credentials or an auth profile. [#100779](https://github.com/nova/nova/pull/100779) Thanks @amknight.
- OpenAI image generation can now be enabled from `models.providers.openai` with a usable API key and custom base URL, without also requiring `OPENAI_API_KEY` or an auth profile. [#100745](https://github.com/nova/nova/pull/100745) Thanks @amknight.
- Configurations using the retired `openai-codex-responses` API ID now receive a validation message naming the supported replacement instead of a generic failure. [#96257](https://github.com/nova/nova/pull/96257) Thanks @james-16, @yetval.
- Legacy `openai-codex` references now direct operators to `nova doctor --fix` and `nova models status` instead of suggesting configuration that fails validation. [#100120](https://github.com/nova/nova/pull/100120) Thanks @jason-vaughan, @sunnyshu0925, @vincentkoc.

##### Local and self-hosted models

- Ollama model discovery now stops oversized or never-ending endpoint responses before they can exhaust memory or leave setup hanging. [#96027](https://github.com/nova/nova/pull/96027) Thanks @alix-007.
- LM Studio model discovery and startup now stop pathological server responses at a fixed size and report a clear error instead of buffering them indefinitely. [#96042](https://github.com/nova/nova/pull/96042) Thanks @alix-007.
- `nova models list` now reports configured local Ollama models as available when they are running and usable. [#97491](https://github.com/nova/nova/pull/97491) Thanks @lingfeizi, @qingminglong.
- Custom Xiaomi MiMo and other OpenAI-compatible models without a known output limit can now complete chats instead of failing with an invented oversized cap. [#98312](https://github.com/nova/nova/pull/98312) Thanks @peole, @sanjays2402.

##### Shared provider configuration

- Provider setup now stops reading runaway model-discovery responses before they can stall or exhaust memory, while normal self-hosted server responses continue to work. [#95244](https://github.com/nova/nova/pull/95244) Thanks @alix-007, @sallyom.
- Rerunning provider onboarding or refreshing models now preserves operator-owned timeouts, transport settings, MiniMax models, and SecretRef credentials instead of silently erasing them. [#100107](https://github.com/nova/nova/pull/100107) Thanks @frank-beans.
- With `models.mode` set to `replace`, agent startup now uses only explicitly configured providers and skips the slow implicit provider scan. [#82638](https://github.com/nova/nova/pull/82638) Related [#66957](https://github.com/nova/nova/issues/66957). Thanks @eldar702, @wangzhengshu.
- Bundled provider aliases now accept supported overlay settings such as request timeouts without demanding custom-provider fields like `baseUrl` and `models`. [#88400](https://github.com/nova/nova/pull/88400) Thanks @pluviobyte.
- Isolated cron jobs can now use models supplied by enabled bundled plugins without failing as unknown or silently resolving to the wrong provider. [#96070](https://github.com/nova/nova/pull/96070) Thanks @sallyom, @sunnyshu0925.
- Z.AI endpoint and model detection now fails gracefully on oversized or endless error responses instead of exhausting host memory. [#97540](https://github.com/nova/nova/pull/97540) Thanks @alix-007.
- Microsoft Foundry connection tests now stop oversized or continuously streamed error responses while preserving concise setup diagnostics. [#97812](https://github.com/nova/nova/pull/97812) Thanks @pick-cat.
- Generic provider configurations for official DashScope/Qwen, Moonshot, Z.AI, DeepSeek, Groq, Cerebras, and Chutes endpoints now retain the compatibility behavior those services require even without optional plugins. [#100125](https://github.com/nova/nova/pull/100125)
- Provider onboarding no longer writes an empty `request` block when no request overrides were supplied. [3a0a736](https://github.com/nova/nova/commit/3a0a736843af2877d66f5b8b8bcc78786d8f04a0) Thanks @vincentkoc.

##### Model catalogs and selection

- Switching a live Control UI or TUI session through a provider-qualified model alias now saves the canonical provider and model, preventing the next request from being rejected. [#100209](https://github.com/nova/nova/pull/100209) Thanks @sahilsatralkar.
- Bedrock Mantle model discovery now times out and caps oversized catalog responses instead of hanging or consuming excessive memory, while cached models remain available. [#99961](https://github.com/nova/nova/pull/99961) Thanks @zhangguiping-xydt.
- OpenRouter video model discovery now stops oversized or runaway catalog responses promptly instead of letting them consume memory without limit, while normal discovery behavior is preserved. [#96505](https://github.com/nova/nova/pull/96505) Thanks @mushuiyu886.
- Model aliases and partial names such as `opus` now resolve to the newest matching version even when catalogs reach double-digit versions, preventing silent routing to an older model. [#96609](https://github.com/nova/nova/pull/96609) Thanks @yetval, @zw-xysk.
- Paginated provider catalogs now expose models beyond the first page, while malformed, endless, or redirected catalogs fail safely instead of caching an incomplete list or forwarding sensitive headers across origins. [#97012](https://github.com/nova/nova/pull/97012) Thanks @zhangguiping-xydt.
- Hugging Face model discovery now falls back to the bundled catalog when a provider response is malformed or oversized instead of risking excessive memory use. [#101079](https://github.com/nova/nova/pull/101079) Thanks @cxbasdev.
- Trusted official external providers can now show model-specific thinking choices before full runtime activation, including off, low, high, and max for Z.AI GLM 5.2. [b4fce16](https://github.com/nova/nova/commit/b4fce16971995438ee416eee90569a37d6a592dc) Thanks @vincentkoc.
- Status summaries now respect provider-local model aliases, showing the selected alias without a false pinned-model mismatch warning. [1d4e789](https://github.com/nova/nova/commit/1d4e7899a47f4483d29848eac02e1fb89de2a2ee)
- OpenRouter scans now interpret model names such as `8b-70b` by their larger parameter size, improving minimum-size filters and small-model security warnings. [#96288](https://github.com/nova/nova/pull/96288) Thanks @ly-wang19.
- Media-generation catalogs now keep the correct default model marker even when provider metadata includes harmless surrounding whitespace. [#96430](https://github.com/nova/nova/pull/96430) Thanks @lin-hongkuan.
- Very long OpenRouter Fusion model IDs now remain valid Unicode in the agent prompt instead of showing a corrupted character when an emoji reaches the display limit. [#104433](https://github.com/nova/nova/pull/104433) Thanks @zhangguiping-xydt.

#### Sign-in and credentials

##### Anthropic and Claude

- Anthropic OAuth token exchange and refresh now reject oversized endpoint responses early instead of reading an unbounded body into memory. [#96644](https://github.com/nova/nova/pull/96644) Thanks @solodmd.
- Anthropic sign-in now rejects unsupported callback-host overrides, keeps authorization on standard local loopback addresses, and avoids callback failures or exposure through a non-local listener. [#96917](https://github.com/nova/nova/pull/96917) Thanks @xialonglee.
- Expired Claude CLI authentication now shows the exact recovery command `claude auth login && nova models auth login --provider anthropic --method cli` instead of a generic failure. [#97669](https://github.com/nova/nova/pull/97669) Thanks @alix-007.
- Anthropic OAuth subscription requests now carry the Claude Code-style billing identity, helping them use the intended subscription route instead of failing or being treated as the wrong request type. [709be93](https://github.com/nova/nova/commit/709be93ca8987009540eb56ed1b6bfda136427de) Thanks @vincentkoc.

##### OpenAI, ChatGPT, and Codex

- ChatGPT OAuth sign-in and refresh now reject unexpectedly large token responses cleanly instead of risking Gateway memory exhaustion. [#99479](https://github.com/nova/nova/pull/99479) Thanks @pandah97.
- Cloudflare 403 challenges on OpenAI or Codex OAuth requests now produce gateway-block guidance instead of incorrectly telling users their authentication failed. [#94440](https://github.com/nova/nova/pull/94440) Related [#94432](https://github.com/nova/nova/issues/94432). Thanks @lzyyzznl, @pbm9z95m6z-hue.
- OpenAI authentication errors now point ChatGPT/Codex OAuth users to a model compatible with their existing sign-in instead of recommending an outdated default. [#100579](https://github.com/nova/nova/pull/100579) Thanks @zhangguiping-xydt.
- For Codex-backed OpenAI models, `/status` now identifies ChatGPT login authentication as `oauth (codex-cli)` instead of incorrectly labeling it as an environment API key. [#91240](https://github.com/nova/nova/pull/91240) Related [#91099](https://github.com/nova/nova/issues/91099). Thanks @849261680, @ukstem.
- OpenAI Realtime voice in Talk, Voice Call, and Discord can now use an existing Codex/OpenAI OAuth login when no explicit API key is configured. [#100671](https://github.com/nova/nova/pull/100671) Thanks @steipete-oai.

##### Google and Gemini

- Google Gemini CLI sign-in now rejects oversized OAuth, profile, project, and onboarding responses with labeled errors instead of risking excessive memory use. [#97587](https://github.com/nova/nova/pull/97587) Thanks @hugenshen.
- Google Gemini CLI OAuth failures now keep oversized or malformed provider responses bounded while preserving useful error details. [#99605](https://github.com/nova/nova/pull/99605) Thanks @mushuiyu886.
- Google OAuth sign-in, token exchange, and project discovery now return a bounded error for oversized responses instead of risking a process crash. [#97628](https://github.com/nova/nova/pull/97628) Thanks @vincentkoc, @wangmiao0668000666.

##### GitHub Copilot

- GitHub Copilot sign-in, refresh, and model-list checks now fail with labeled size limits when GitHub or a proxy returns an oversized response. [#97499](https://github.com/nova/nova/pull/97499) Thanks @wangmiao0668000666.
- GitHub Copilot sign-in and token refresh now reject oversized service responses with a clear error before they can exhaust Nova's memory. [#97579](https://github.com/nova/nova/pull/97579) Thanks @hugenshen.
- GitHub Copilot device login now fails cleanly on an oversized successful response instead of risking an out-of-memory crash. [#97583](https://github.com/nova/nova/pull/97583) Thanks @hugenshen.
- OpenAI-compatible providers routed through the GitHub Copilot BYOK harness now retain bearer authentication, reducing false 401 errors for valid credentials. [#99955](https://github.com/nova/nova/pull/99955) Thanks @hxy91819.

##### xAI and Grok

- xAI and Grok OAuth sign-in now works on SSH hosts, containers, VPS systems, and other headless environments without forwarding a localhost callback port. [#97249](https://github.com/nova/nova/pull/97249) Thanks @fuller-stack-dev, @jaaneek.
- xAI sign-in, token refresh, and device approval now stop oversized OAuth responses before they can consume unbounded memory. [#97615](https://github.com/nova/nova/pull/97615) Thanks @cxbasdev.
- Existing xAI and Grok OAuth sessions using the retired token endpoint can renew after expiry without forcing another browser or SSH-tunneled login. [#96146](https://github.com/nova/nova/pull/96146) Thanks @fuller-stack-dev, @jaaneek.

##### Ollama, MiniMax, Chutes, Z.AI, OpenRouter, and ClawRouter

- Ollama Cloud setup now stops oversized or malicious authentication responses before they can consume excessive memory, while normal sign-in remains unchanged. [#97581](https://github.com/nova/nova/pull/97581) Thanks @hugenshen.
- MiniMax OAuth device setup now limits authorization response size so a faulty proxied or self-hosted endpoint cannot exhaust Gateway memory. [#96322](https://github.com/nova/nova/pull/96322) Thanks @lsr911.
- Chutes login, user lookup, and token refresh now stop unexpectedly large OAuth responses with a bounded error instead of buffering them without limit. [#96777](https://github.com/nova/nova/pull/96777) Thanks @wangmiao0668000666.
- Chutes onboarding now fails clearly when token-exchange or user-info responses are oversized, preventing abnormal authentication traffic from causing unbounded memory growth. [#96779](https://github.com/nova/nova/pull/96779) Thanks @wangmiao0668000666.
- Z.AI users can recover a profile that accidentally stored an onboarding command as the API key without wiping all authentication state. [#97520](https://github.com/nova/nova/pull/97520) Thanks @zhangguiping-xydt.
- Chutes sign-in and token refresh errors now include a useful bounded snippet without allowing an endpoint to stream an unlimited response into memory. [#97808](https://github.com/nova/nova/pull/97808) Thanks @pick-cat.
- OpenRouter sign-in now fails safely on oversized replies, and Discord webhook sends remain successful when their optional response body is absent, malformed, or too large. [#98098](https://github.com/nova/nova/pull/98098) Thanks @lwy-2.
- OpenRouter model probes and agent requests now use discovered environment or profile API keys correctly instead of failing with a missing-authentication-header error. [#98187](https://github.com/nova/nova/pull/98187) Related [#97934](https://github.com/nova/nova/issues/97934). Thanks @laurencebrown, @sunlit-deng.
- ClawRouter models selected in agent defaults now resolve at runtime when the credential is stored in an auth profile instead of the environment. [#99759](https://github.com/nova/nova/pull/99759)

##### Amazon Bedrock

- Amazon Bedrock users can now analyze images and PDFs with the same AWS profile, role, SSO, environment, or instance credentials already used for chat. [#72092](https://github.com/nova/nova/pull/72092) Thanks @truffle-dev.

##### Shared sign-in and credential behavior

- OpenAI/Codex and Anthropic OAuth result pages now show Nova branding instead of the legacy Pi logo. [1834592](https://github.com/nova/nova/commit/1834592be17668cbfc9ea834c57df73e05b71f14)
- Agents created by copying credentials now preserve the source agent's portable provider-profile priority instead of unexpectedly choosing a different credential. [#100833](https://github.com/nova/nova/pull/100833) Thanks @machine3at.
- New or updated provider credentials entered through the CLI now appear in the running Gateway and Control UI model picker without a manual secrets reload or restart. [#101256](https://github.com/nova/nova/pull/101256) Thanks @fuller-stack-dev.
- OAuth-backed models now become available in Gateway model browsing after credentials are renewed from another CLI process, without requiring a Gateway restart. [#104732](https://github.com/nova/nova/pull/104732) Thanks @fuller-stack-dev.

#### Fallbacks and model switching

##### Anthropic and Claude

- Anthropic conversations rejected for a missing tool result now tell users to retry or start a fresh session with `/new` instead of showing only a generic provider failure. [#98163](https://github.com/nova/nova/pull/98163) Thanks @masatohoshino.
- Claude native-thinking sessions can now recover automatically after Anthropic rejects a replayed thinking block, without manual compaction or transcript loss. [#98411](https://github.com/nova/nova/pull/98411) Related [#98308](https://github.com/nova/nova/issues/98308). Thanks @clearhorizoninvestments, @sunlit-deng.
- Claude CLI agent runs now fail over instead of presenting provider errors or raw stream data as answers, preserve multilingual and emoji output, and stop runaway one-shot output before it exhausts Gateway memory. [#98942](https://github.com/nova/nova/pull/98942) Related [#98896](https://github.com/nova/nova/issues/98896). Thanks @obviyus.
- Eligible direct API-key requests to Claude Fable 5 now return an Opus 4.8 answer when Anthropic's safety classifier declines Fable, with diagnostics and Opus billing made clear. [#99906](https://github.com/nova/nova/pull/99906)

##### Google and Gemini

- Gemini streaming can retry with another configured API key after a retryable quota or rate-limit response instead of failing on the first key. [#97328](https://github.com/nova/nova/pull/97328) Thanks @monkeyleet.

##### Ollama, OpenAI-compatible providers, and Z.AI

- Ollama requests whose native response stream ends early can now continue to a configured fallback model instead of stopping with `LLM request failed`. [#100482](https://github.com/nova/nova/pull/100482) Thanks @turbotheturtle.
- A detail-less failure from an OpenAI-compatible provider no longer puts a valid API-key profile into cooldown or forces avoidable fallback traffic. [#100617](https://github.com/nova/nova/pull/100617) Thanks @fengjikui.
- Z.AI and similar HTTP 429 responses now distinguish temporary service overload from ordinary rate limiting and preserve provider-supplied retry timing. [#98165](https://github.com/nova/nova/pull/98165) Thanks @sunnyshu0925.
- Continued conversations with strict custom OpenAI Responses-compatible endpoints no longer fail on an unsupported `input[n].status` field and needlessly switch to a fallback model. [#100831](https://github.com/nova/nova/pull/100831) Thanks @chenxiaoyu209.

##### Shared fallback and model-selection behavior

- Replay-safe model timeouts can now advance to the next configured provider, letting agent, chat, and cron runs recover without repeating work that may have side effects. [#96142](https://github.com/nova/nova/pull/96142) Thanks @brokemac79, @riazrahaman.
- Agent runs can move to the next configured model after a provider drops a stream, while genuine cancellations still stop promptly. [#90908](https://github.com/nova/nova/pull/90908) Thanks @shengting.
- Embedded-agent runs can now try the next configured fallback model after a temporary upstream `LLM request failed` error. [#95542](https://github.com/nova/nova/pull/95542) Thanks @altaywtf, @mikasa0818.
- Configured fallback chains now try an alternate model when the primary provider reports `model_not_found`, reducing failures after model availability changes. [#97571](https://github.com/nova/nova/pull/97571) Thanks @liuhao1024.
- When a configured runtime model is no longer available, chat now explains that a new session will not help and directs operators to choose an available model. [#97611](https://github.com/nova/nova/pull/97611) Thanks @romneyda.
- Provider failures now keep fallback error text within the configured size limit, preventing oversized responses from overwhelming logs or visible diagnostics. [#99340](https://github.com/nova/nova/pull/99340) Thanks @pick-cat.
- `/model default` now actually returns an active session to its configured model after steering, fallback, or a previous manual selection. [#96318](https://github.com/nova/nova/pull/96318) Thanks @marsman-lab, @sunnyshu0925.
- Gateway chat now classifies mixed provider messages as rate limits when throttling is the real failure, giving users recovery guidance that matches the problem. [#100755](https://github.com/nova/nova/pull/100755) Thanks @pick-cat.
- `nova status` and `session_status` now identify when a session is using a fallback model and show the configured primary model beside it. [#101337](https://github.com/nova/nova/pull/101337) Thanks @lzy3538.

#### Replies, reasoning, and tool calls

##### Anthropic and Claude

- Claude CLI replies that streamed successfully are now retained when the final success envelope contains no text, preventing the completed answer from disappearing or triggering an empty-response fallback. [#90450](https://github.com/nova/nova/pull/90450) Thanks @totobusnello.
- Claude Code 2.1 users can again approve and run Bash, WebFetch, Grep, Glob, AskUserQuestion, and other native tools in claude-cli sessions. [#98665](https://github.com/nova/nova/pull/98665) Related [#95171](https://github.com/nova/nova/issues/95171). Thanks @carterdawson, @yetval.
- Claude CLI-backed agents now show native reasoning in `/reasoning stream` or `/reasoning on`, while `/reasoning off` consistently suppresses it for queued follow-ups too. [#99401](https://github.com/nova/nova/pull/99401) Thanks @marvinthebored.
- Anthropic Opus 4.8 can now run with `tools.profile=coding` without every turn failing with an HTTP 400 schema error before the assistant replies. [#100492](https://github.com/nova/nova/pull/100492) Thanks @lin-hongkuan, @vincentkoc.
- Anthropic Messages-compatible proxy users no longer see raw antml tool-call XML or arguments leak into visible Claude replies. [b2787a1](https://github.com/nova/nova/commit/b2787a1c7a7ae1a20d05411bba1dbf9091490c23) Thanks @jerry-xin.
- Anthropic agents routed through AWS Bedrock can keep Feishu Bitable write tools enabled without the tool definitions blocking every conversation. [#94990](https://github.com/nova/nova/pull/94990) Thanks @twinslee, @vincentkoc.
- Claude Fable 5 now uses the expected Anthropic `context1m` stream setup when 1M context is enabled, without affecting similar model IDs. [#100572](https://github.com/nova/nova/pull/100572) Thanks @zhangguiping-xydt.
- Claude conversations through GitHub Copilot can continue after a tool failure with no visible output instead of entering repeated provider-schema failures. [#101373](https://github.com/nova/nova/pull/101373) Thanks @galiniliev.
- Anthropic-compatible calls with token caps too small for manual thinking now run normally without thinking instead of failing provider validation. [#101415](https://github.com/nova/nova/pull/101415) Thanks @pick-cat.

##### OpenAI-compatible and local models

- Ollama Cloud and other OpenAI-compatible Ollama chats can now continue after a tool call instead of failing the next turn with a provider 400 error. [#96474](https://github.com/nova/nova/pull/96474) Thanks @849261680.
- vLLM, Ollama proxies, and other OpenAI-compatible gateways can deliver streamed replies even when they incorrectly label an event stream as JSON, avoiding an early parsing failure that previously ended the agent run. [#96503](https://github.com/nova/nova/pull/96503) Thanks @zengwen-dt.
- GPT-5.5 and other models can send valid streaming events larger than 64 KiB through ChatGPT Responses without failing the request, while malformed unbounded streams remain limited. [#98198](https://github.com/nova/nova/pull/98198) Thanks @marvinthebored, @obviyus, @peetiegonzalez.
- `nova agent --local` now reports a clear first-event timeout when a provider opens a stream but never sends usable output instead of appearing to hang indefinitely. [#98525](https://github.com/nova/nova/pull/98525) Thanks @osolmaz.
- MCP tools that expect arrays or objects can now accept those values when Xiaomi MiMo, Ollama, or another affected provider returns them as JSON strings, avoiding a pre-execution validation failure. [#96922](https://github.com/nova/nova/pull/96922) Thanks @liuhao1024.
- Repaired plain-text tool calls from LM Studio, xAI, and Ollama now emit a final completion event so plugins and other streaming consumers can finish them reliably. [#104714](https://github.com/nova/nova/pull/104714)

##### Google and Gemini

- Google Live voice sessions can now register and call Nova tools instead of rejecting their declarations before a tool-backed turn begins. [#100260](https://github.com/nova/nova/pull/100260)

##### MiniMax, OpenRouter, Mistral, and opencode-go

- MiniMax M3 replies, including those routed through Fireworks, no longer expose hidden `mm:` reasoning in visible chat or progress output. [#93767](https://github.com/nova/nova/pull/93767) Thanks @drhack1, @vincentkoc.
- Long opencode-go model runs are less likely to be falsely stopped as stalled while valid provider events are still arriving. [#97128](https://github.com/nova/nova/pull/97128) Thanks @liuwqgit, @vincentkoc, @yetval.
- OpenRouter's DeepSeek V4 Flash and Pro models can answer with thinking enabled without failing with an HTTP 400. [#97208](https://github.com/nova/nova/pull/97208) Related [#97196](https://github.com/nova/nova/issues/97196). Thanks @nianjiuzst, @patelmm79.
- Direct `mistral-medium-3-5` requests now send the user-selected adjustable reasoning level to Mistral as `reasoningEffort`. [#100688](https://github.com/nova/nova/pull/100688) Thanks @aniruddhaadak80, @wm0018.

##### Shared reasoning and tool behavior

- Realtime voice sessions now omit an individual custom tool with an invalid provider-specific name and warn about it instead of letting that tool break the entire OpenAI, Azure, or Google session. [#89175](https://github.com/nova/nova/pull/89175) Thanks @vincentkoc.
- Switching from thinking-off mode to a reasoning-required model now selects its lowest supported effort rather than silently choosing the most expensive level. [#93335](https://github.com/nova/nova/pull/93335) Thanks @obuchowski.

#### Voice, transcription, images, and video

##### OpenAI and Azure voice and images

- OpenAI Realtime voice and transcription sessions now start behind Clash, Surge, sing-box, and similar TUN proxy setups that resolve `api.openai.com` into fake-IP ranges. [#86526](https://github.com/nova/nova/pull/86526) Thanks @shushushv.
- OpenAI and Azure realtime voice connections now close inbound messages above 16 MiB, limiting avoidable gateway memory pressure. [#99450](https://github.com/nova/nova/pull/99450) Thanks @sunlit-deng.
- OpenAI realtime voice sessions now default to `gpt-realtime-2.1` when no model is specified, while explicit model pins continue to work. [#101390](https://github.com/nova/nova/pull/101390) Thanks @vincentkoc.
- OpenAI image generation and reference-image editing no longer crash when credentials or a custom base URL are ready before the provider model catalog finishes loading. [#105518](https://github.com/nova/nova/pull/105518) Thanks @vincentkoc.
- OpenAI video generation now stops oversized or endless submission responses with a bounded provider error before they can hang the request or exhaust memory. [#96905](https://github.com/nova/nova/pull/96905) Thanks @alix-007.

##### Google and Gemini media

- Gemini CLI media analysis now returns its description even when the valid response also contains nested usage or other metadata. [#96432](https://github.com/nova/nova/pull/96432) Thanks @lin-hongkuan.
- Google Veo video generation now ends oversized create or status responses early with a clear bounded error, preventing a broken endpoint from hanging Nova or consuming memory indefinitely. [#96605](https://github.com/nova/nova/pull/96605) Thanks @alix-007.

##### MiniMax, xAI, and Fal-hosted media

- Reference-image edits through Fal-hosted Grok Imagine and Nano Banana 2 Lite now reach the correct service, while mixed-model fallbacks honor each candidate's supported resolution and reference limits. [#98688](https://github.com/nova/nova/pull/98688) Thanks @davenicoll, @vincentkoc.
- MiniMax TTS now accurately explains that volume must be greater than 0 and may be as high as 10 when a directive is invalid. [#101359](https://github.com/nova/nova/pull/101359) Thanks @quratulain-bilal.
- MiniMax VLM and native PDF provider errors now remain readable when emoji or other supplementary characters land at the diagnostic snippet limit. [#101728](https://github.com/nova/nova/pull/101728) Thanks @wings1029.
- MiniMax video generation now rejects oversized task, status, or file-metadata responses before unbounded memory use or binary download begins, while normal responses continue to work. [#96889](https://github.com/nova/nova/pull/96889) Thanks @alix-007.
- xAI video generation now stops oversized create or status responses with a clear size-limit error instead of buffering until Nova hangs or consumes excessive memory. [#96903](https://github.com/nova/nova/pull/96903) Thanks @alix-007, @vincentkoc.
- MiniMax image understanding now stops oversized or malformed successful responses at a bounded limit, protecting memory while returning a useful diagnostic. [#100694](https://github.com/nova/nova/pull/100694) Thanks @zhangguiping-xydt.

##### Video providers and generation services

- Moonshot video understanding now returns a predictable error for oversized or malformed responses instead of hanging or consuming memory indefinitely, including with custom base URLs. [#96502](https://github.com/nova/nova/pull/96502) Thanks @hugenshen.
- Qwen video understanding now stops oversized or malformed endpoint responses with a clear error instead of hanging or reading without limit, while normal descriptions continue unchanged. [#96604](https://github.com/nova/nova/pull/96604) Thanks @alix-007.
- BytePlus video generation now stops oversized task-submission or status responses with a clear error before they can stall Nova or exhaust memory, while normal responses continue unchanged. [#96606](https://github.com/nova/nova/pull/96606) Thanks @alix-007.
- DashScope-compatible video submission and polling now reject oversized JSON responses with a bounded error instead of risking memory pressure or process instability, while ordinary responses continue normally. [#96782](https://github.com/nova/nova/pull/96782) Thanks @wangmiao0668000666.
- OpenRouter video generation now rejects oversized submit and polling responses before they can hang Nova or consume runaway memory, while normal-sized malformed responses retain their established error handling. [#96873](https://github.com/nova/nova/pull/96873) Thanks @alix-007.
- Vydra image, video, and speech generation now fails with a bounded error on oversized or endless control responses instead of hanging or exhausting memory, while valid responses continue normally. [#96875](https://github.com/nova/nova/pull/96875) Thanks @alix-007.
- fal music and video generation now stops oversized successful responses with a clear size-limit error before they can hang or exhaust memory, while normal generation continues as before. [#96886](https://github.com/nova/nova/pull/96886) Thanks @alix-007.
- Together and PixVerse video generation now returns a provider-labelled size error for oversized successful responses instead of continuing until severe memory pressure or process failure. [#96904](https://github.com/nova/nova/pull/96904) Thanks @alix-007.
- Runway video generation now stops oversized create and status responses instead of continuing to consume memory or stall, while normal polling and provider-specific errors remain intact. [#96907](https://github.com/nova/nova/pull/96907) Thanks @alix-007.
- Comfy image-generation workflows now stop oversized ComfyUI responses with the actual size-limit error instead of risking memory exhaustion or misreporting the response as malformed JSON. [#96927](https://github.com/nova/nova/pull/96927) Thanks @wangmiao0668000666.
- DeepInfra video generation now rejects oversized successful responses with a bounded error instead of risking an out-of-memory crash. [#97486](https://github.com/nova/nova/pull/97486) Thanks @hugenshen.

##### Voice and transcription across providers

- Configured Voice Call transcription providers such as xAI remain selectable when another provider registry is active, allowing Talk sessions to start normally. [#97170](https://github.com/nova/nova/pull/97170) Thanks @solavrc.
- Missing official media providers now produce errors with the exact recovery commands needed to restore transcription and other media workflows. [#97484](https://github.com/nova/nova/pull/97484) Thanks @wangmiao0668000666.
- A malformed Inworld voices response now produces a clear provider-specific error instead of an unhelpful parsing exception or process crash. [#98660](https://github.com/nova/nova/pull/98660) Thanks @solodmd.
- Short non-English audio now keeps the configured language hint without an unrelated English prompt, reducing accidental translation when users expect a transcript in the spoken language. [#99023](https://github.com/nova/nova/pull/99023) Thanks @flyveryhigh, @nianjiuzst.

##### Shared media selection and response safety

- Image and video tools can now automatically select configured provider-plugin models authenticated through environment variables. [#98623](https://github.com/nova/nova/pull/98623) Thanks @medns.
- Automatically configured video understanding now uses provider defaults such as Moonshot's intended video model unless the user selected a model explicitly. [#99791](https://github.com/nova/nova/pull/99791) Thanks @vincentkoc, @zhangguiping-xydt.
- Image generation now stops with a clear size-limit error when a provider or custom endpoint sends an oversized or endless response, preventing hangs and runaway memory use while valid images and edits continue normally. [#96495](https://github.com/nova/nova/pull/96495) Thanks @hugenshen, @sallyom.

#### Speech, search, embeddings, and documents

##### Speech and transcription

- Google Gemini TTS now rejects oversized responses before buffering them into memory, while normal speech results continue through the existing audio workflow. [#96984](https://github.com/nova/nova/pull/96984) Thanks @mushuiyu886.
- Inworld text-to-speech and voice-list requests now fail safely on oversized, malformed, or never-ending responses instead of hanging or consuming unbounded Gateway memory. [#95416](https://github.com/nova/nova/pull/95416) Thanks @alix-007, @vincentkoc.
- Azure Speech, Microsoft Speech, ElevenLabs, MiniMax TTS, OpenRouter transcription, and xAI transcription now stop oversized or endless responses before they can stall speech work or strain Gateway memory, while ordinary responses remain unchanged. [#96496](https://github.com/nova/nova/pull/96496) Thanks @hugenshen.
- Volcengine, BytePlus Seed Speech, and Xiaomi TTS now stop oversized provider responses before one speech request can stall or destabilize Nova. [#96874](https://github.com/nova/nova/pull/96874) Thanks @alix-007.
- Google audio and video understanding now stops oversized provider responses at the shared 16 MiB limit with a clear error instead of allowing them to consume excessive memory. [#96920](https://github.com/nova/nova/pull/96920) Thanks @mushuiyu886, @vincentkoc.

##### Embeddings and memory search

- Gemini memory-embedding batch uploads, creation, and status checks now fail safely when a compatible endpoint returns an oversized control response. [#97535](https://github.com/nova/nova/pull/97535) Thanks @hugenshen.
- OpenAI-compatible embedding requests now close oversized responses early with a clear provider error instead of buffering until Nova stalls or runs out of memory, while normal embeddings continue working. [#96868](https://github.com/nova/nova/pull/96868) Thanks @alix-007.
- OpenAI embedding batch polling and Realtime setup now cancel oversized successful responses early and return a bounded error instead of growing memory without limit. [#97533](https://github.com/nova/nova/pull/97533) Thanks @hugenshen.
- OpenAI-compatible embedding batch downloads now process valid large outputs while stopping oversized files or JSONL records before they can exhaust memory. [#98554](https://github.com/nova/nova/pull/98554) Thanks @sunlit-deng, @vincentkoc.
- GitHub Copilot model discovery and memory search now reject oversized or malformed responses instead of buffering them without limit, while valid catalog and embedding results continue normally. [#96499](https://github.com/nova/nova/pull/96499) Thanks @hugenshen, @sallyom.
- Voyage embedding batch jobs now stop oversized status, failure, and error-file responses before they can hang or exhaust worker memory, while oversized diagnostics degrade safely and ordinary responses remain unchanged. [#96608](https://github.com/nova/nova/pull/96608) Thanks @alix-007.
- LM Studio embedding preload now respects the configured context limit, reducing GPU out-of-memory failures during memory search on constrained hardware. [#100750](https://github.com/nova/nova/pull/100750) Thanks @hxz398, @zak-li, @zoowh.
- Malformed Voyage embedding batches now close their download connections after parsing fails, reducing resource buildup during repeated or large workloads. [#98840](https://github.com/nova/nova/pull/98840) Thanks @solodmd.

##### Search and document processing

- Google Meet document processing now rejects oversized Google Drive exports before they can destabilize Nova, while ordinary documents still export as text. [#97620](https://github.com/nova/nova/pull/97620) Thanks @alix-007, @vincentkoc.
- Parallel web search now returns a bounded error when an upstream response is malformed, oversized, or never-ending instead of risking a hang or out-of-memory crash. [#96035](https://github.com/nova/nova/pull/96035) Thanks @alix-007.
- Exa searches now reject responses above the supported limit, preventing excessive provider output from hanging Nova or creating memory pressure. [#96038](https://github.com/nova/nova/pull/96038) Thanks @alix-007.

#### Provider response safety and clearer errors

##### Anthropic and OpenAI-compatible streams

- Anthropic-compatible requests now fail promptly with a bounded transport error when an upstream stream sends an oversized partial event instead of hanging and consuming memory. [#100686](https://github.com/nova/nova/pull/100686) Thanks @zhangguiping-xydt.
- OpenAI ChatGPT Responses streaming now cancels oversized or endless provider bodies with a clear error before they can consume excessive process memory, while normal responses keep using the existing parser. [#96762](https://github.com/nova/nova/pull/96762) Thanks @vincentkoc, @wangmiao0668000666.
- OpenAI-compatible provider and proxy streams now stop oversized malformed or never-ending bodies at the affected request instead of letting them destabilize or crash the Nova process. [#96989](https://github.com/nova/nova/pull/96989) Thanks @vincentkoc, @wangmiao0668000666.
- OpenAI-compatible Chat Completions now use Nova's guarded network path, adding the same response safety controls used by other protected model calls. [#97228](https://github.com/nova/nova/pull/97228) Thanks @vincentkoc, @wangmiao0668000666.
- Azure OpenAI Responses now bound oversized streaming and error bodies, protecting memory while preserving normal errors and cancellation. [#97349](https://github.com/nova/nova/pull/97349) Thanks @wangmiao0668000666.
- Anthropic-compatible model requests now consistently use Nova's guarded transport, response normalization, and managed stream cleanup rather than bypassing them through the SDK. [#101357](https://github.com/nova/nova/pull/101357) Thanks @wangmiao0668000666.
- When an OpenAI or OpenAI-compatible chat-completions model refuses a request, users now see the provider's explanation instead of a blank assistant reply. [#102344](https://github.com/nova/nova/pull/102344) Thanks @wuqxuan, @yetval.

##### Proxies and other provider endpoints

- Proxy-backed model streams now fail with bounded, clearer errors when responses are oversized, malformed, incomplete, or idle instead of hanging or consuming unbounded data. [#97235](https://github.com/nova/nova/pull/97235) Thanks @vincentkoc, @zhangguiping-xydt.
- Mistral-compatible endpoints now stop oversized streaming responses with a labeled error before Nova can run out of memory. [#97648](https://github.com/nova/nova/pull/97648) Thanks @wangmiao0668000666.
- Abnormally large Google Meet, Calendar, or OAuth responses now stop with an error before they can consume uncontrolled Gateway memory. [#98850](https://github.com/nova/nova/pull/98850) Thanks @pandah97.

##### Shared provider diagnostics

- Request-format and schema failures now show the relevant diagnostic without sending users through unnecessary provider login or reconfiguration steps. [#95779](https://github.com/nova/nova/pull/95779) Thanks @pick-cat.

#### Codex app-server and supervised sessions

##### Runtime and model compatibility

- Codex users can route both `codex/*` and `openai/*` models through the bundled runtime, and older conversations resume without unnecessary context reprojection. [#105034](https://github.com/nova/nova/pull/105034)
- The bundled Codex plugin can complete backend requests again after updating its managed app-server runtime, with no model-picker or configuration migration required. [#106098](https://github.com/nova/nova/pull/106098)
- Nova's managed Codex workflow now uses app-server 0.143.0, and self-managed installations must use 0.143.0 or newer for protocol compatibility. [366258d](https://github.com/nova/nova/commit/366258dee6e4a3ea0bb04b1316e5a0c419c60188) Thanks @vincentkoc.
- The managed Codex harness now surfaces supported GPT-5.6 Sol, Terra, and Luna models returned by the account catalog and gives self-managed users current version guidance. [f80ce21](https://github.com/nova/nova/commit/f80ce219fcf0c5cbe9871b9ad05b7570fbfeba6e) Thanks @vincentkoc.
- Managed Codex users on macOS, Linux, and Windows now receive app-server 0.144.1 instead of 0.144.0. [5dcba9f](https://github.com/nova/nova/commit/5dcba9fae725c080b62c4b4e19533f5fcd59b964) Thanks @vincentkoc.
- Codex-native delegation from Nova threads now creates native task records again, while unsupported custom Codex app-server versions fail startup with a clear minimum-version error. [#101221](https://github.com/nova/nova/pull/101221)
- Codex sessions using `gpt-5.5-pro` or `gpt-5.4-pro` now clamp unsupported reasoning levels before the first turn, avoiding an immediate request rejection when live metadata is unavailable. [#101484](https://github.com/nova/nova/pull/101484) Thanks @zhangguiping-xydt.

##### Session reliability and diagnostics

- Scheduled and CLI Codex runs with an explicit timeout longer than 30 minutes can now use that full budget instead of being stopped by the terminal-idle guard. [#85296](https://github.com/nova/nova/pull/85296) Thanks @alkor2000, @vincentkoc.
- A missing or hung local Codex tool result no longer switches the active session to another provider that cannot resolve the local failure. [#95543](https://github.com/nova/nova/pull/95543) Thanks @mikasa0818.
- Codex app-server runs with an invalid ChatGPT OAuth session now surface the real sign-in error promptly instead of waiting for a misleading ten-second authentication timeout. [#100713](https://github.com/nova/nova/pull/100713) Thanks @lin-hongkuan.
- Codex runs stopped by the guardian rejection limit now say why they ended, so operators do not have to mistake the result for a crash, cancellation, or generic interruption. [#101220](https://github.com/nova/nova/pull/101220) Thanks @darren2030.
- Crestodian setup and repair chats on Codex-backed runs can now access the status and repair tool they need instead of stopping with a missing-tool response. [#101281](https://github.com/nova/nova/pull/101281)
- Shared Codex app-server clients now keep usage limits, auth cooldowns, thread subscriptions, and resumed connections tied to the account and conversation that actually owns them. [#101376](https://github.com/nova/nova/pull/101376)
- Codex app-server stdout failures now end affected requests cleanly, while a diagnostics-only stderr failure no longer interrupts an otherwise healthy turn. [#101505](https://github.com/nova/nova/pull/101505) Thanks @mushuiyu886, @vincentkoc.

#### Usage, context, cost, and diagnostics

##### Usage and quota reporting

- Anthropic usage checks now cap unusually large error responses so a CDN, firewall, or proxy page cannot exhaust Nova's memory. [#97614](https://github.com/nova/nova/pull/97614) Thanks @cxbasdev.
- OpenAI and Codex users authenticated through the app server can again see their five-hour and weekly quota windows in chat, CLI, and JSON status output. [#92520](https://github.com/nova/nova/pull/92520) Thanks @brokemac79.
- OpenAI OAuth usage checks now cap oversized WHAM rate-limit responses before they can destabilize the process. [#97702](https://github.com/nova/nova/pull/97702) Thanks @cxbasdev.
- GitHub Copilot usage checks now contain oversized or endless endpoint responses as a usage error instead of buffering them indefinitely, while normal usage data still loads. [#96607](https://github.com/nova/nova/pull/96607) Thanks @alix-007.
- OpenRouter cost tracking now caps unexpectedly large metadata responses and keeps the original streamed estimate instead of disrupting the agent turn. [#97490](https://github.com/nova/nova/pull/97490) Thanks @hugenshen.
- MiniMax and other shared provider usage checks now fail safely on oversized or malformed replies instead of buffering them without limit. [#97659](https://github.com/nova/nova/pull/97659) Thanks @cxbasdev, @vincentkoc.
- OpenRouter completions that the provider bills at $0 now stay recorded as free in transcripts, summaries, logs, and usage totals instead of being replaced with estimated catalog pricing. [#101177](https://github.com/nova/nova/pull/101177)

##### Context limits and prompt efficiency

- Amazon Bedrock adaptive-thinking Claude and Fable runs now honor configured high output-token limits for longer answers, reasoning, and tool calls. [#97343](https://github.com/nova/nova/pull/97343) Thanks @lilan0125, @prasithg.
- Long, tool-heavy or media-heavy embedded-agent conversations now retain more prompt-cache reuse between turns, reducing repeated token processing, latency, and cost on prefix-cached providers. [#102610](https://github.com/nova/nova/pull/102610) Thanks @ugiezzz.
- Nemotron 3 Super now exposes its full 1,048,576-token context budget in Nova's bundled NVIDIA fallback catalog instead of compacting at the stale 262,144-token limit. [#98726](https://github.com/nova/nova/pull/98726) Thanks @eleqtrizit.
- ChatGPT OAuth-backed Responses sessions now retain backend affinity across turns, improving prompt-cache reuse and reducing repeated processing of the same conversation context. [#100233](https://github.com/nova/nova/pull/100233) Thanks @marvinthebored, @obviyus, @peetiegonzalez.

##### Session and model diagnostics

- After `/model` changes a session's provider, `/status` and `session_status` now report that provider's usage, authentication, runtime, and context details rather than stale defaults. [#93384](https://github.com/nova/nova/pull/93384) Thanks @obviyus, @osolmaz, @rollingshmily, @samiralibabic, @zhangguiping-xydt.
- Model-call traces now include prompt-size and per-call token usage details, helping operators investigate cost and prompt growth without capturing raw content. [#95770](https://github.com/nova/nova/pull/95770) Thanks @amknight.
- The diagnostics timeline now shows when provider model calls ran, how long they took, and whether they succeeded without recording prompt or response content. [7253552](https://github.com/nova/nova/commit/7253552c68d0ac8c6098126d373f185bb6df22a2) Thanks @vincentkoc.

### Memory and Sessions

[Memory](https://docs.nova.ai/concepts/memory) indexing, recall, wiki synchronization, and search recover from more malformed pages, stale status, large indexes, transient reads, and provider mismatches without hiding useful stored context or overwriting user notes. When a result is incomplete or a configured memory provider is unavailable, the failure is clearer instead of looking like a complete answer.

[Sessions](https://docs.nova.ai/cli/sessions), transcripts, compaction, goals, and routing also retain the intended conversation more consistently through restarts, resets, delayed follow-ups, tool-heavy runs, and client changes. The practical result is less missing history, fewer replies stored against the wrong session, and more dependable continuation of long-running work.

#### Memory search and recall

- QMD `search` and `vsearch` modes now skip the LLM reranker, reducing latency and avoiding unnecessary GPU failures while full `query` mode keeps reranking. [#88887](https://github.com/nova/nova/pull/88887) Thanks @potterdigital.
- Memory-wiki pages titled `Index` now remain stored, searchable, and retrievable instead of being hidden or overwritten by generated directory pages. [#94326](https://github.com/nova/nova/pull/94326) Thanks @vincentkoc, @yetval.
- Active Memory now warns when recalled operational details may be outdated and clearly marks clipped summaries, so old or incomplete status is less likely to look current. [#95888](https://github.com/nova/nova/pull/95888) Thanks @spencer2211.
- Memory-wiki pages in subfolders now appear in search, lookup, compiled indexes, digests, and vault counts just like pages at the top level. [#96022](https://github.com/nova/nova/pull/96022) Thanks @machine3at, @vincentkoc.
- Large memory indexes can now return filtered matches beyond sqlite-vec's first 4,096 candidates without failing or silently missing valid results. [#96157](https://github.com/nova/nova/pull/96157) Thanks @itsuzef, @vincentkoc.
- Repeated QMD-backed `memory_search` and `nova memory search` requests can return faster after the first lookup, while diagnostics separate setup time from search time and missing collections still trigger repair. [#96655](https://github.com/nova/nova/pull/96655) Thanks @bek91.
- Memory search now works with installed generic embedding plugins such as local llama.cpp, including their default model and connection details. [#97095](https://github.com/nova/nova/pull/97095) Thanks @849261680.
- One memory-wiki page with broken YAML no longer blocks healthy pages from being searched, compiled, linted, counted, or updated. [#97177](https://github.com/nova/nova/pull/97177) Related [#96125](https://github.com/nova/nova/issues/96125). Thanks @cow11023, @sunnyshu0925.
- Memory Wiki now marks claims with malformed explicit freshness timestamps as unknown instead of masking the bad metadata with the page date. [#97465](https://github.com/nova/nova/pull/97465) Thanks @ly-wang19.
- Detailed `/status plugins` now warns when a configured memory embedding provider is unavailable and semantic recall has fallen back to keyword search. [#97968](https://github.com/nova/nova/pull/97968) Thanks @masatohoshino.
- QMD memory recall now turns malformed or warning-filled mcporter output into a clear, filtered error instead of exposing raw subprocess text. [#98381](https://github.com/nova/nova/pull/98381) Thanks @miorbnli.
- `memory_get` with `corpus=all` can now return an available wiki supplement when the requested memory file is missing instead of stopping with an empty result. [#100904](https://github.com/nova/nova/pull/100904) Thanks @mushuiyu886, @vincentkoc.
- With `memorySearch.provider: none`, Nova now starts FTS-only memory without an unnecessary plugin capability scan. [fbf574a](https://github.com/nova/nova/commit/fbf574ad9db2658652e442aab4be3d597e1a9c14)
- Interactive QMD memory searches with no matches now return an empty result promptly instead of appearing stuck during unnecessary index maintenance. [#90030](https://github.com/nova/nova/pull/90030) Related [#90023](https://github.com/nova/nova/issues/90023). Thanks @ruben2000de, @sahibzada-allahyar.
- `nova doctor --fix` can now carry legacy Memory Core indexes from 2026.6.9 upgrades into the current store without forcing a full re-embed. [#95631](https://github.com/nova/nova/pull/95631) Thanks @mushuiyu886, @vincentkoc.
- `nova memory status` now warns when session transcripts still need indexing instead of incorrectly reporting memory as current. [#97857](https://github.com/nova/nova/pull/97857) Related [#97814](https://github.com/nova/nova/issues/97814). Thanks @che10x, @zw-xysk.
- Memory Core now preserves short standalone concepts such as `kv` and `s3` in tags, improving recall without matching them inside unrelated words. [#96304](https://github.com/nova/nova/pull/96304) Thanks @ly-wang19.
- Memory-wiki bridge status now returns a usable warning instead of crashing on malformed plugin artifacts, and `readMemoryArtifacts: false` now reliably prevents those reads. [#100900](https://github.com/nova/nova/pull/100900) Thanks @huveewomg.
- Wiki search and retrieval now explain when an older or partial memory plugin lacks shared-search support and offer a practical workaround instead of exposing a raw TypeError. [#100902](https://github.com/nova/nova/pull/100902) Thanks @huveewomg, @vincentkoc, @xuanmingguo.
- Memories containing emoji or supplementary CJK characters can now be indexed without malformed text stalling the operation. [#101574](https://github.com/nova/nova/pull/101574) Thanks @jensenwang560-blip.
- When both a primary memory read and its wiki supplement fail, `memory_get corpus=all` now returns the original structured read error instead of crashing the tool call. [#101902](https://github.com/nova/nova/pull/101902) Thanks @aniruddhaadak80, @vincentkoc, @zw-xysk.
- Memory-index debug logs now show whether an embedding batch completed or failed, making indexing problems easier to trace. [#94732](https://github.com/nova/nova/pull/94732) Thanks @doubleji817-lang, @xydt-tanshanshan.
- `nova memory status --fix` now repairs session-corpus state without mistaking healthy daily-memory records for stale data. [#93389](https://github.com/nova/nova/pull/93389) Thanks @alix-007, @vincentkoc.
- `nova memory status` no longer shows impossible session indexing totals where the indexed file count exceeds the total file count. [#95452](https://github.com/nova/nova/pull/95452) Thanks @buyitsydney, @liuhao1024.

#### Memory Wiki and long-term memory

- Durable memory promotion now keeps Nova's managed dreaming markers and adjacent managed content out of `MEMORY.md` when a recalled range touches a block boundary. [#83718](https://github.com/nova/nova/pull/83718) Thanks @grifjef.
- Inferred follow-up commitments now return to the queue after temporary model or network extraction failures, reducing missed reminders without duplicate processing. [#89817](https://github.com/nova/nova/pull/89817) Thanks @masatohoshino.
- Memory-core light dreaming no longer repeats an unchanged work-summary block in `DREAMS.md`, while genuine daily-note updates can still appear later. [#97446](https://github.com/nova/nova/pull/97446) Thanks @aaajiao, @qingminglong.
- Memory Wiki lint now ignores link-looking text inside inline and fenced code while continuing to report genuine broken links in prose. [#98095](https://github.com/nova/nova/pull/98095) Thanks @durambar, @vincentkoc, @zhangqueping.
- Memory-wiki source updates now preserve hand-written Notes when a temporary read failure prevents Nova from safely loading the existing page. [#98360](https://github.com/nova/nova/pull/98360) Related [#98345](https://github.com/nova/nova/issues/98345). Thanks @qingminglong, @vincentkoc, @yetval.
- Memory-wiki source sync can now recover when a page is missing or collides with a non-file, while preserving existing content when a retry remains unsafe. [#99276](https://github.com/nova/nova/pull/99276) Thanks @obviyus.
- Memory Wiki imports now continue when a source page collides with a protected vault entry instead of stopping the whole import. [76db9a3](https://github.com/nova/nova/commit/76db9a3376228db6a6f58cd705fc236aa697446c) Thanks @vincentkoc.
- Newly promoted long-term memories now omit raw transcript, summary, session-header, flush-prompt, and scoring clutter so useful notes are easier to find. [#94636](https://github.com/nova/nova/pull/94636) Thanks @josephur, @pinghe-learn, @tayoun.
- Dreaming now keeps deleted or reset transcript archives and cron-created child conversations out of its learned session set, reducing duplicate history and automation noise without removing retained archives from historical search. [#96517](https://github.com/nova/nova/pull/96517) Thanks @adam-researchh, @jalehman, @xialonglee.
- Memory Wiki import summaries now shorten ChatGPT text containing emoji without leaving corrupted replacement characters. [#97362](https://github.com/nova/nova/pull/97362) Thanks @mushuiyu886.
- Rerunning memory-wiki synthesis or ChatGPT imports no longer risks erasing handwritten notes, frontmatter, or import state when an existing page cannot be read briefly. [#98787](https://github.com/nova/nova/pull/98787) Thanks @vincentkoc, @yetval.
- Memory dreaming now records structured success or failure outcomes for light, REM, and deep phases so dashboards and health checks can monitor them reliably. [#97723](https://github.com/nova/nova/pull/97723) Thanks @lg320531124, @momothemage.
- `nova wiki lint` now ignores wikilink-like patterns inside code examples so real broken Memory Wiki links are easier to spot. [#97954](https://github.com/nova/nova/pull/97954) Thanks @durambar, @liuhao1024, @vincentkoc.
- `nova wiki lint` now recognizes valid imported Obsidian links by title, slug, fragment-free path, or source-path suffix, reducing false broken-link warnings. [#100017](https://github.com/nova/nova/pull/100017) Thanks @ishangodawatta, @k-kerrigan, @vincentkoc.
- Archived memories around user messages that begin with `[cron:]` remain searchable after a session reset or deletion, while genuine cron-generated archives stay hidden. [#101322](https://github.com/nova/nova/pull/101322) Thanks @ly-wang19.

#### Session continuity

- After `/new` or `/reset`, the previous conversation remains available for daily memory summaries and full-history searches through the session-logs skill. [#71537](https://github.com/nova/nova/pull/71537) Thanks @injinj.
- A group chat or Gateway session can now resume on the next visible request after a failed, timed-out, or killed turn without requiring `/new` or manual session-file edits. [#89045](https://github.com/nova/nova/pull/89045) Thanks @jerry-xin.
- Aborted or timed-out embedded runs now release their session write lock, so the next message can proceed without minutes of waiting or manual file cleanup. [#96100](https://github.com/nova/nova/pull/96100) Thanks @richwilson-bloom, @sallyom, @xialonglee.
- Replies that span an automatic daily or idle reset now remain together in one accessible transcript instead of losing later output. [#97164](https://github.com/nova/nova/pull/97164) Thanks @joshavant, @yetval.
- Resuming work from a project now opens only that project's saved agent session, preventing unrelated transcripts from being mixed together. [#97785](https://github.com/nova/nova/pull/97785) Related [#96542](https://github.com/nova/nova/issues/96542). Thanks @qingminglong, @yetval.
- Recurring provider-CLI cron jobs and local `nova agent` runs now keep their existing provider conversation across the daily reset boundary instead of silently losing context. [#98356](https://github.com/nova/nova/pull/98356) Thanks @yetval.
- Discord, WebChat, and other ongoing conversations can keep receiving replies when background activity touches the same session during reply startup, without a false initialization conflict or dropped message. [#98835](https://github.com/nova/nova/pull/98835) Related [#98672](https://github.com/nova/nova/issues/98672). Thanks @aaronfaby, @jalehman, @moguangyu5-design.
- Resetting a multi-agent room now restores message delivery promptly instead of blocking most agents' acknowledgement and queued replies for several minutes. [#99091](https://github.com/nova/nova/pull/99091) Thanks @gorkem2020, @zengwen-dt.
- Rapid follow-ups in the same chat no longer freeze both messages while the first automatic reply is finishing. [#99549](https://github.com/nova/nova/pull/99549) Thanks @shagrat2.
- Claude CLI-backed interactive replies now keep their saved session more consistently, preserving continuity and reducing repeated full-history replay. [#99595](https://github.com/nova/nova/pull/99595) Related [#99372](https://github.com/nova/nova/issues/99372). Thanks @obviyus.
- CLI-backed agents in multi-person group chats now retain conversational context when participants alternate, without expanding non-owner tool permissions. [#99640](https://github.com/nova/nova/pull/99640) Related [#99633](https://github.com/nova/nova/issues/99633). Thanks @obviyus.
- CLI-backed group agents now keep one warm conversation across mentioned and unmentioned follow-ups instead of resetting and losing context. [#99722](https://github.com/nova/nova/pull/99722) Related [#99696](https://github.com/nova/nova/issues/99696). Thanks @obviyus.
- CLI-backed agents now keep conversation continuity across prompt-only changes, avoiding needless cold starts while still resetting when security or runtime conditions require it. [#99822](https://github.com/nova/nova/pull/99822) Related [#99729](https://github.com/nova/nova/issues/99729). Thanks @obviyus.
- Temporary memory-maintenance failures no longer replace the agent reply, and persistently oversized sessions can recover in a fresh session while preserving the previous transcript. [#100618](https://github.com/nova/nova/pull/100618) Thanks @jerry-xin, @rhclaw.
- A first command-only interaction in an auto-reply flow now keeps its session update even when no session row existed beforehand. [76d686c](https://github.com/nova/nova/commit/76d686cf61f29b4b26ef67066d0b88f405ddfe5c)
- Sessions renamed with `/name` now keep that custom name in session lists instead of reverting to an automatic title or UUID-like label. [#98841](https://github.com/nova/nova/pull/98841) Related [#98742](https://github.com/nova/nova/issues/98742). Thanks @bsg2000, @sunnyshu0925.
- A successfully completed main-agent conversation now continues in the same session on the next message instead of unexpectedly resetting and archiving its transcript. [#99985](https://github.com/nova/nova/pull/99985) Thanks @sunnyshu0925.
- Dashboard session labels and display names now remain attached when a session rolls over after a day or idle period. [#101576](https://github.com/nova/nova/pull/101576) Thanks @merlin-zhou, @zengwen-dt.

#### CLI and Codex sessions

- Claude CLI conversations that exhaust their context now recover into a fresh reseeded session automatically, and timeout retries retain the temporary files they need to complete. [#98934](https://github.com/nova/nova/pull/98934) Related [#98897](https://github.com/nova/nova/issues/98897). Thanks @obviyus.
- Local Ollama-backed CLI agent turns can now continue when the context engine reports an already-compacted transcript, allowing the assistant or MCP tool result to reach the user. [#99136](https://github.com/nova/nova/pull/99136) Thanks @mushuiyu886, @peterskwang, @pkoserowski, @psedd.
- Existing Codex sessions can resume their bound threads more reliably after upgrades, resets, and compaction without depending on leftover transcript-side JSON files. [#101210](https://github.com/nova/nova/pull/101210)
- A Codex reply delivered through `sourceReplyDeliveryMode: "message_tool_only"` now completes its turn promptly instead of later ending as an incomplete reply. [#95942](https://github.com/nova/nova/pull/95942) Thanks @omarshahine.
- Codex app-server installations using the retired `on-failure` approval policy now upgrade to the supported `on-request` behavior without losing saved bindings. [70153f7](https://github.com/nova/nova/commit/70153f7f9c12be2ff025802c019e428047d1f579) Thanks @vincentkoc.
- Existing Codex app-server conversations with dynamic tools can resume through the tool-fingerprint format upgrade instead of starting an avoidable replacement thread. [3051748](https://github.com/nova/nova/commit/305174845f38f075bfd5096a0a4912b8d7d2559a) Thanks @vincentkoc.
- Legacy Codex bindings with large tool or MCP configurations can now migrate without overflowing plugin-state records or copying raw configuration secrets. [23228b6](https://github.com/nova/nova/commit/23228b67a47bf32fc9b662d13037757f51d329b8) Thanks @vincentkoc.
- Upgraded Codex installations can now finish legacy binding migration and archive old sidecars instead of repeatedly retaining them after an earlier partial import. [39fac06](https://github.com/nova/nova/commit/39fac06f48745dcd4d7a840f8261631614bb1926) Thanks @vincentkoc.
- Codex sessions created in beta 5 can keep their existing conversation after upgrade when the user MCP configuration is unchanged, without retaining its authorization token. [272750d](https://github.com/nova/nova/commit/272750daed354029c1968dce7cd6747163e0957a) Thanks @vincentkoc.
- Provider-owned CLI conversations now keep the same session and transcript across the daily default reset boundary unless an explicit reset policy or `/reset` applies. [#97931](https://github.com/nova/nova/pull/97931) Thanks @yetval.
- New Codex-backed threads now preserve configured plugin apps, can activate remote curated plugins, and run Guardian on the first eligible native OpenAI turn. [#98042](https://github.com/nova/nova/pull/98042) Thanks @kevinslin.
- A stuck Claude CLI startup now fails only the affected turn instead of exiting the Gateway, and heartbeat activity no longer causes the next user turn to lose its CLI conversation history. [#98933](https://github.com/nova/nova/pull/98933) Related [#98894](https://github.com/nova/nova/issues/98894), [#98895](https://github.com/nova/nova/issues/98895). Thanks @obviyus.
- Claude CLI agent runs now fail clearly when messaging tools are unavailable, recover when Claude exits without a result, retain more long-session continuity, and clean up prompt images and failed preparation files. [#99159](https://github.com/nova/nova/pull/99159) Related [#98946](https://github.com/nova/nova/issues/98946). Thanks @obviyus.
- The same-release Codex session-continuity work now covers app-server thread start and resume, with binding fingerprints kept bounded throughout. [78edf1c](https://github.com/nova/nova/commit/78edf1cec15c4a45881386b94e06c71c64f90fa4) Thanks @vincentkoc.

#### Transcripts and exports

- Shared group and channel transcripts now retain the sender ID, display name, and username for each durable user turn, making later history and memory processing correctly attribute participants. [#90552](https://github.com/nova/nova/pull/90552) Thanks @pick-cat.
- `/export-session` now warns when a CLI- or ACP-backed export contains only user messages and points users to the backend transcript for missing assistant, tool, usage, and cost details. [#90867](https://github.com/nova/nova/pull/90867) Thanks @tank-x3, @vincentkoc, @xydigit-sj.
- `nova export-trajectory` and `/export-trajectory` now include redacted messages from older version 1 sessions instead of producing a successful but empty transcript. [#93814](https://github.com/nova/nova/pull/93814) Thanks @yetval.
- Session-memory files created around `/new` and `/reset` now keep one copy of each assistant reply instead of duplicating reasoning-model responses. [#94401](https://github.com/nova/nova/pull/94401) Thanks @sallyom, @sunnyshu0925.
- Compacted agent history now lists genuine tool failures instead of repeatedly mislabeling successful subagent launches, including when older transcript records contain the incorrect error flag. [#96842](https://github.com/nova/nova/pull/96842) Thanks @nxmxbbd.
- Invalid transcript entries now raise a visible write error instead of becoming `undefined` JSONL lines that silently vanish after reload. [#97356](https://github.com/nova/nova/pull/97356) Thanks @miorbnli.
- `nova sessions cleanup --fix-missing` now preserves fresh cron sessions with valid transcripts and clearly reports repaired entries. [#97495](https://github.com/nova/nova/pull/97495) Thanks @qingminglong.
- Automatic recovery from provider role-ordering conflicts now archives the complete prior transcript as a timestamped JSONL file before replaying a shorter tail. [#97544](https://github.com/nova/nova/pull/97544) Thanks @yungchentang.
- Compacted group conversations now retain identical long messages from different participants while still removing accidental duplicate retries from the same sender. [#98336](https://github.com/nova/nova/pull/98336) Thanks @sunnyshu0925, @yetval.
- Transcript summary and import reads now close files reliably after malformed data, preventing long-running processes from gradually exhausting file handles. [#98493](https://github.com/nova/nova/pull/98493) Related [#98467](https://github.com/nova/nova/issues/98467). Thanks @wangmiao0668000666, @zhanglei99586.
- Older or imported sessions with plain-string assistant messages now replay correctly across provider and streaming paths instead of sending malformed conversation history. [#98908](https://github.com/nova/nova/pull/98908) Thanks @obviyus.
- Claude CLI chat history reloads no longer display Nova's internal reseed wrapper as if it were a message the user typed. [#99653](https://github.com/nova/nova/pull/99653) Related [#99646](https://github.com/nova/nova/issues/99646). Thanks @harjothkhara, @jeehut, @vincentkoc, @zoowh.
- Transcript-backed history now treats a missing file as empty while reporting real access, directory, or stream failures cleanly instead of leaving partial or unhandled results. [#100524](https://github.com/nova/nova/pull/100524) Thanks @cxbasdev, @zhanglei99586.
- Transient transcript read failures no longer destabilize session-log diagnostics or let an incomplete usage scan overwrite the last complete cost cache as though it were current. [#101062](https://github.com/nova/nova/pull/101062) Thanks @cxbasdev, @vincentkoc.
- Malformed transcript rows now produce an aggregate warning with skipped and loaded counts while the remaining usable session history continues to load. [#98669](https://github.com/nova/nova/pull/98669) Thanks @cxbasdev.
- Transcript tools can now identify channel delivery mirrors as Nova bookkeeping rather than mistaking them for OpenAI Responses output. [#99855](https://github.com/nova/nova/pull/99855) Thanks @vincentkoc.
- Debug-proxy ACP runs now shut down cleanly, mark capture sessions finished, and close their capture databases without reporting a spurious database error. [#100827](https://github.com/nova/nova/pull/100827) Thanks @amknight.
- `nova sessions tail` now rejects oversized trajectory snapshots and updates with a clear limit error before they can exhaust memory. [#101450](https://github.com/nova/nova/pull/101450) Thanks @cxbasdev, @vincentkoc.
- Long usage and session log messages now truncate emoji cleanly instead of displaying malformed character artifacts. [#101517](https://github.com/nova/nova/pull/101517) Thanks @maweibin.

#### Tool results, files, and media

- Reopened sessions can now replay older string or single-object tool results correctly instead of treating successful output as empty or failing on its stored shape. [#98891](https://github.com/nova/nova/pull/98891) Related [#98825](https://github.com/nova/nova/issues/98825). Thanks @obviyus.
- Agents in long-running WebChat, Discord, and other direct sessions can keep reading fresh command, file, browser, and status output instead of seeing it disappear or turn into an image placeholder. [#98955](https://github.com/nova/nova/pull/98955) Related [#98874](https://github.com/nova/nova/issues/98874). Thanks @lamkan0210, @momothemage.
- Imported Claude CLI history now keeps image-only and attachment-bearing turns visible when removing empty legacy reseed text. [#99839](https://github.com/nova/nova/pull/99839) Thanks @vincentkoc.
- Claude CLI model fallback now carries the prior tool-call trail alongside tool results, giving the replacement model enough context to continue coherently. [#99851](https://github.com/nova/nova/pull/99851) Thanks @vincentkoc.
- Long-running agents can now recover full command output and truncated `web_fetch` content after history cleanup, reducing repeated expensive work and lost page context. [#100135](https://github.com/nova/nova/pull/100135) Thanks @obviyus.
- Embedded agents now receive well-formed summaries of long media or JSON values instead of broken characters at Unicode truncation boundaries. [#101311](https://github.com/nova/nova/pull/101311) Thanks @alix-007.
- Media-provider audit details containing emoji now remain valid and readable when shortened, instead of ending with malformed characters. [#101298](https://github.com/nova/nova/pull/101298) Thanks @alix-007.
- Long agent prompt data containing emoji or other paired Unicode characters now stays well-formed when capped, avoiding broken text in agent and automation context. [#101303](https://github.com/nova/nova/pull/101303) Thanks @alix-007.

#### Long conversations and compaction

- Embedded agents now retain configured compaction reserve limits when runtime safeguards save settings, reducing unexpected context-budget shrinkage during long work. [#92237](https://github.com/nova/nova/pull/92237) Thanks @sercada.
- Telling an agent to remember a preference no longer triggers the unrelated warning used for promises to schedule an automatic reminder. [#93862](https://github.com/nova/nova/pull/93862) Thanks @arkyu2077.
- Sessions with large command output or summaries now compact before exceeding the model context, avoiding failed provider requests and misleading token budgets. [#97861](https://github.com/nova/nova/pull/97861) Thanks @yetval.
- Long tool-heavy or compacted sessions now budget the real size of command output and summaries before sending a prompt, reducing context overflow failures. [#97928](https://github.com/nova/nova/pull/97928) Related [#97927](https://github.com/nova/nova/issues/97927). Thanks @liuhao1024, @yetval.
- Edge-case fixes now preserve literal memory text and valid Unicode, improve voice-call cleanup and port checks, report Claude models and context limits accurately, and retain useful ClickClack connection errors. [#100204](https://github.com/nova/nova/pull/100204) Thanks @cxbasdev, @harjothkhara, @lilan0125, @lin-hongkuan, @liuhao1024, @mikasa0818, @pandah97, @sunlit-deng, @zoowh.
- Fresh Claude CLI workspaces now run a pending `BOOTSTRAP.md` on the first reply so required identity, memory, and setup steps are completed before normal conversation. [#100560](https://github.com/nova/nova/pull/100560) Thanks @bill-starfoundry, @kruegerb, @vincentkoc.
- Long-running agents are less likely to lose workspace instructions such as `AGENTS.md`, `SOUL.md`, or `MEMORY.md` for a turn during a temporary filesystem error. [#100910](https://github.com/nova/nova/pull/100910) Thanks @masatohoshino.
- Embedded agent runs that omit a session key now retain the intended fallback session context more reliably. [31a65e0](https://github.com/nova/nova/commit/31a65e0647ae85eb4c9048051145f07003722caf) Thanks @vincentkoc.
- A malformed custom tool in realtime Talk no longer removes the built-in consult tool or other valid custom tools from the session. [170150a](https://github.com/nova/nova/commit/170150a306e39204ebe1ab7be47450b73005de1f) Thanks @vincentkoc.
- Local-model conversations now retain reusable prompt work when switching between interactive chats and background jobs, avoiding repeated multi-minute warm-up delays. [#98267](https://github.com/nova/nova/pull/98267) Related [#98261](https://github.com/nova/nova/issues/98261). Thanks @headbouyjb.
- A response interrupted mid-tool-call no longer runs or saves that incomplete action, preventing accidental child sessions and other unintended side effects. [#97140](https://github.com/nova/nova/pull/97140) Thanks @galiniliev.
- Agents running on macOS 26 now receive the macOS product version in their runtime prompt instead of the Darwin kernel version. [#95225](https://github.com/nova/nova/pull/95225) Thanks @sunlit-deng.
- Level directives such as `/verbose` and `/think` no longer remove the first word of the user's message when both are sent together. [#97929](https://github.com/nova/nova/pull/97929) Thanks @yetval.
- Malformed surrogate HTML entities in provider output no longer corrupt agent tool arguments, transcripts, or URLs, while legitimate entities and emoji still decode normally. [#99564](https://github.com/nova/nova/pull/99564) Thanks @mikasa0818.
- Leaving one answer blank in a multi-question prompt no longer shifts the remaining typed answers onto the wrong questions. [#100832](https://github.com/nova/nova/pull/100832) Thanks @machine3at.
- ACP runtime controls can now truly clear saved model, thinking, working-directory, permission, timeout, mode, and backend-extra settings so later turns do not reuse stale values. [#101044](https://github.com/nova/nova/pull/101044) Thanks @mushuiyu886.
- Skill Workshop sessions now carry a clearer prompt with about 1.8KB less repeated prompt and schema overhead while retaining the same reviewable proposal flow. [#100481](https://github.com/nova/nova/pull/100481)
- Prompt caching and cache traces now fingerprint malformed incoming text consistently with the cleaned text providers receive, avoiding needless cache misses and misleading diagnostics. [#101009](https://github.com/nova/nova/pull/101009) Thanks @qingminglong.
- Operators now receive `payload.large` or `truncated` diagnostics and an accurate count whenever `chat.history` omits older messages, making hidden history trimming visible without changing client responses. [#96788](https://github.com/nova/nova/pull/96788) Thanks @zengwen-dt.

- With memory flush enabled, important conversation context now gets a chance to reach durable memory before automatic compaction, reducing silent gaps in saved notes. [#84792](https://github.com/nova/nova/pull/84792) Thanks @turbotheturtle.
- Long CJK-heavy sessions using a context engine such as lossless-claw no longer stop on a false `prompt too large` precheck after the engine has already managed the prompt. [#95342](https://github.com/nova/nova/pull/95342) Thanks @jalehman, @mpz4life.
- Large Chinese, Japanese, and Korean tool results are now estimated more accurately, reducing false context-overflow interruptions and premature compaction. [#95447](https://github.com/nova/nova/pull/95447) Thanks @moguangyu5-design, @vincentkoc.
- Prompts containing fullwidth East Asian characters now receive more accurate size estimates, allowing context management to start before an oversized request reaches the model. [#96442](https://github.com/nova/nova/pull/96442) Thanks @lin-hongkuan.
- Long conversations now recover compaction after transient provider disconnects instead of replacing useful history with a degraded placeholder summary. [#97504](https://github.com/nova/nova/pull/97504) Thanks @hugenshen.
- Long conversations using `historyLimit` or `dmHistoryLimit` now retain their saved earlier summary after compaction, helping the assistant remember prior context. [#97591](https://github.com/nova/nova/pull/97591) Thanks @liuhao1024, @yetval.
- Long Codex conversations with heavy tool use can now compact at a real history boundary and continue with relevant tool results summarized instead of retaining the full transcript. [#99391](https://github.com/nova/nova/pull/99391) Related [#99375](https://github.com/nova/nova/issues/99375). Thanks @imchloe92, @lzy3538.
- Local-model sessions now retain auto-compaction bookkeeping, reducing repeated context refills and the unresponsive behavior they could cause. [#99678](https://github.com/nova/nova/pull/99678) Related [#99677](https://github.com/nova/nova/issues/99677). Thanks @headbouyjb, @vincentkoc.
- Long, tool-heavy agent sessions now preserve the newest command, file, or browser result for the model while shortening older history first. [#99756](https://github.com/nova/nova/pull/99756) Thanks @acosx.
- Long cached Anthropic tool sessions now compact near the configured context threshold instead of interrupting work early because cumulative cache tokens looked like live context. [#99864](https://github.com/nova/nova/pull/99864) Thanks @jrex-jooni, @lzy3538, @vincentkoc.
- Long-lived agents with large context windows now retain fresh tool output, compact under aggregate pressure, and warn users to run `/compact` or `/new` if pressure persists. [#100077](https://github.com/nova/nova/pull/100077) Thanks @obviyus.
- Small-context local models can now begin and continue conversations without immediately entering an overflow-compaction loop before useful prompt space is available. [#100621](https://github.com/nova/nova/pull/100621) Thanks @vincentkoc.
- Long sessions that compact in stages now preserve clearer older-to-newer ordering when summaries are combined, reducing the chance that stale context appears equally recent. [#100684](https://github.com/nova/nova/pull/100684) Thanks @vincentkoc, @zw-xysk.
- Context-engine plugins can now identify the exact session that continues after compaction while older integrations using `sessionFile` remain compatible. [#101182](https://github.com/nova/nova/pull/101182) Thanks @jalehman.
- Preparing a reset for a long-running session now avoids scanning the entire transcript, reducing startup file activity and memory use as history grows. [#99335](https://github.com/nova/nova/pull/99335) Thanks @gmschasiepen, @momothemage.

#### Session storage and cleanup

- Gateway and embedded TUI startup now reclaim old session temporary files left by hard shutdowns, reducing hidden disk growth while preserving fresh or potentially recoverable state. [#90503](https://github.com/nova/nova/pull/90503) Thanks @sahibzada-allahyar.
- Long-running gateways can clear stale one-shot model-check sessions before they crowd out real conversation history, with dedicated CLI reporting for review. [#91057](https://github.com/nova/nova/pull/91057) Thanks @jalehman, @wangwllu.
- Mac users now get stronger protection for local Nova SQLite data after abrupt power loss or an operating-system crash, with no configuration change. [#99067](https://github.com/nova/nova/pull/99067) Thanks @ooiuuii.
- Session-memory diagnostics now show the correct workspace and memory-file paths for sibling directories whose names merely resemble the user's home path. [#101577](https://github.com/nova/nova/pull/101577) Thanks @cxbasdev.

### Gateway and Agent Reliability

The [Gateway](https://docs.nova.ai/gateway) now starts, connects, reloads, and reports health with clearer behavior across configuration, networking, task routing, and result delivery. Agents are less likely to lose their selected workspace or conversation, background work reaches the right destination more consistently, and tool failu