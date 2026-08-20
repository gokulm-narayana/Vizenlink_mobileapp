# Camera Chatbot (assistant overlay)

- **Dart file:** `lib/widgets/camera_chatbot.dart`
- **Route:** none — opened via `showCameraChatbot(context, ...)`, documented here rather than as a routed screen (like [scan_cameras_screen.md](../scan/scan_cameras_screen.md)'s scanning popup)
- **Purpose:** A floating chat assistant reached from the Dashboard's `DASH-020` FAB. Replies use real on-device AI (Qwen3.5-0.8B, via `AiModelManager` / the `llamadart` package) — the chat itself only opens once the model is downloaded and ready; there is no canned-reply-only mode. Downloading the ~0.6GB model is strictly opt-in (see CLAUDE.md: no backend/AI dependency without explicit confirmation) — declining closes the whole flow rather than falling back to a non-AI chat, since the chatbot's entire purpose is the AI. **The model can also take real actions**, via `llamadart`'s OpenAI-style tool-calling support (`ChatSession.create(tools: ...)`) — see "Tool-calling (real actions)" below. **Every card the chat shows is the result of a real tool call — there is no keyword-matched shortcut anywhere in this screen** (an earlier version had a separate `_computeResultData` keyword-matching layer for event/video/image cards, running independently of and racing the real tool calls; removed because it could show stale/wrong data — e.g. a cached old thumbnail — ahead of or instead of a tool's real result). **The conversation itself lives in `ChatController`** (`lib/app_state/chat_controller.dart`, instantiated once in `main.dart` alongside the app's other `ValueNotifier` controllers) — not in this sheet's own `State` — so closing the sheet (including an accidental back-gesture dismiss) and reopening it resumes the same conversation instead of starting over; only a real app restart clears it, since nothing here is persisted to disk.

## Tool-calling (real actions)

`lib/app_state/chatbot_tools.dart`'s `buildCameraTools()` builds a catalog of `ToolDefinition`s (one per `camera_api` action a user could otherwise perform by navigating to the matching settings screen), passed into `AiModelManager.reply(text, tools: ...)`. `AiModelManager._replyStream` drives the full tool-call loop itself (streams tokens, collects tool-call deltas, invokes the matching tool's handler, feeds the result back as a tool-role message, lets the model continue — up to 10 rounds), mirroring `llamadart`'s own `basic_app` example service.

Every handler mirrors the exact `camera_api` call pattern its equivalent settings screen already uses (LAN first, WAN retry on failure when `connection.thingName` is known) — nothing here is a new/parallel way of talking to a camera. Kept to 20 tools deliberately — small on-device models measurably lose tool-selection accuracy as the schema grows, so `set_mode` (mode_type: privacy/video/anti_flicker) and `set_audio` (mic_gain/speaker_volume/recording_on, all optional — "only pass what changed", same shape as `set_imaging`) each consolidate what would otherwise be 3 single-field setters:

`list_cameras` (no params — name/home/room/online-offline/connection status for every camera already added to the app; the system prompt tells the model to call this first for any "what cameras do I have"/"is X online" question rather than answering from general knowledge), `scan_for_cameras` (no params — runs the real LAN WS-Discovery scan, `scanForCameras()` in `lib/app_state/camera_scan.dart`, the same scan `ScannedDevicesScreen` uses; for new/unconfigured cameras not yet added, distinct from `list_cameras`), `get_camera_settings` (reads back the cached `Camera` model fields — privacy/video/anti-flicker mode, mic gain, speaker volume, recording, image adjustments — no network round trip, since the app already has this state locally), `take_snapshot`, `open_live_view`, `trigger_deterrence` (siren/spotlight/warning), `set_mode`, `rename_camera`, `set_audio`, `set_imaging` (brightness/contrast/saturation/sharpness), `set_wifi`, `set_alert_type`, `list_alert_types`, `set_all_alerts`, `add_home`, `rename_home`, and four destructive ones: `reboot_camera`, `reset_camera_settings`, `factory_reset_camera`, `delete_camera`.

**Camera resolution** (`buildCameraTools`'s `findCamera`) tries an exact id/name match first, then falls back to a case-insensitive substring match ("front" matching "Front Door Camera") — but only when exactly one camera matches; an ambiguous substring returns "not found" rather than guessing. A tool's `camera` parameter description no longer embeds the full camera-name list (it used to, redundantly, in all ~20 tools' schemas every single turn) — it just points the model at `list_cameras`, which is both fresher (the old embedded list was captured once when the chat opened) and far cheaper on context budget. An unmatched name returns an `Error: no camera matching "…". Call list_cameras…` text result rather than throwing, same defensive-string-result convention every handler uses for a failed `camera_api` call.

**Fail-fast on offline cameras.** Every tool that needs a live round trip checks `camera.isOnline` (a cheap, already-cached signal) before attempting one, returning an immediate "camera is currently offline" instead of waiting out a real connect/timeout.

**Context-overflow fail-closed.** `ChatSession.lastRequestFitContext` (its own doc: *"a false value means even the active turn could not be compacted enough — callers that execute model-proposed side effects should fail closed"*) is checked after every round in `_replyStream`. If the conversation has grown too long to fit context, the loop aborts and tells the user to start a new chat, rather than executing a tool call generated from a truncated/garbled prompt.

A tool's handler can produce a `ChatToolEffect` (`lib/app_state/chatbot_tools.dart`) alongside its short text result, routed via `_handleToolEffect`/`_activeEffects`/`_activeMessageIndex` in `_CameraChatbotSheetState` and attached to `_ChatMessage.effects` — rendered by `_buildToolEffect`, the only source of any card shown alongside a reply:

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CHAT-027 | Snapshot effect card | `InkWell` + `Image.memory` | Result of `take_snapshot` — real freshly-captured bytes (`SnapshotClient.getSnapshot()`), not a cached `thumbnailUrl`. Tapping opens a full-screen preview (pinch-zoom, share, save) |
| CHAT-028 | Live View effect card | `OutlinedButton.icon` | Result of `open_live_view` — "Open {camera} Live View"; tapping closes the chat sheet and deep-links to the real `CameraLiveScreen` (`context.push('.../live/{cameraId}', extra: camera)`) rather than embedding a video player in the chat bubble (see this session's design discussion for why: avoids a second concurrent WebRTC connection question) |
| CHAT-032 | Scan Results effect card | `Card` | Result of `scan_for_cameras` — real LAN scan results (name, IP, configured/unconfigured "New" badge, up to 5 shown); "No cameras found on the network." when empty |
| CHAT-033 | Add cameras button (in CHAT-032) | `OutlinedButton.icon` | Only shown when results are non-empty; closes the chat sheet and deep-links to the real `ScannedDevicesScreen` (`context.push('.../scan', extra: cameras)`), passing the already-fetched results so it doesn't scan again — same deep-link pattern as CHAT-028 |
| CHAT-029 | Confirmation card | `Container` (error-tinted) | Result of any destructive tool (`reboot_camera`/`reset_camera_settings`/`factory_reset_camera`/`delete_camera`) — shows the tool's own title/message text (same wording `danger_zone_screen.md`'s equivalent dialogs use). **The real `camera_api` call never fires from the tool call itself** — the handler only stages a `ConfirmEffect` and returns "Awaiting user confirmation…" so the model doesn't treat the action as already done; execution only happens from CHAT-031's tap, entirely outside the LLM loop. Three real states, not two: idle (buttons shown) → in-progress (spinner + "Working…", once Confirm is tapped) → resolved ("Handled", only after the real `camera_api` call actually finishes) — a card no longer claims "Handled" while the reboot/reset/delete is still in flight |
| CHAT-030 | Cancel button (in CHAT-029) | `TextButton` | Marks the card resolved without executing anything; posts a "Cancelled." message |
| CHAT-031 | Confirm button (in CHAT-029) | `FilledButton`, error-colored | Moves the card to in-progress and calls the effect's `onConfirm()` — the actual `camera_api` call; only marks resolved once that call actually returns, then posts its result text as a new assistant message |

## Flow

Tapping `DASH-020` calls `showCameraChatbot`, which gates on `AiModelManager.status` before ever showing the chat:

1. **Not yet decided / previously declined** → CHAT-019 consent dialog.
   - **Not now** (CHAT-021) → `AiModelManager.decline()`, whole flow closes, nothing else opens.
   - **Accept & download** (CHAT-022) → `AiModelManager.accept()`, proceeds to step 2.
2. **Downloading / retrying** → CHAT-023 download-progress sheet (its own bottom sheet, not the chat). Auto-dismisses and proceeds to the chat once the model becomes ready; a Close button (CHAT-026) lets the user back out early (the download keeps running in the background via the `AiModelManager` singleton — reopening the chatbot later resumes wherever it left off). On failure, shows CHAT-025 with a Retry action instead of the progress bar.
3. **Ready** → the CHAT-001 chat sheet opens.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CHAT-019 | AI consent dialog | AlertDialog | shown before the chat if the model hasn't been accepted/declined yet, or was previously declined |
| CHAT-020 | Consent body text | Text | explains the one-time ~0.6GB Qwen3.5-0.8B download |
| CHAT-021 | Not now button (in CHAT-019) | TextButton | declines; closes the whole flow, no chat opens |
| CHAT-022 | Accept & download button (in CHAT-019) | FilledButton | accepts; starts the download and shows CHAT-023 |
| CHAT-023 | Download-progress sheet | Bottom sheet (own `showModalBottomSheet`, separate from CHAT-001) | `LinearProgressIndicator` + percentage while downloading; listens to `AiModelManager` and auto-pops (opening the chat) once ready |
| CHAT-025 | Download-failed message (in CHAT-023) | Text | shown in place of the progress bar if the download errors out |
| CHAT-026 | Close / Retry buttons (in CHAT-023) | TextButton / FilledButton | Close backs out (download continues in the background); Retry (failed state only) calls `AiModelManager.retry()` |
| CHAT-001 | Chat overlay | Container (bottom-sheet, 85% height, rounded top corners) | only reachable once `AiModelManager.status == ready` |
| CHAT-002 | Close button | IconButton | dismisses the overlay |
| CHAT-003 | Title | Text | "Ask about your cameras" |
| CHAT-004 | Empty state + quick-prompt chips | Column of `ActionChip`s | shown before the first message; tapping a chip sends it as a message immediately — chips are plain example messages sent through the normal chat path (e.g. "Scan for cameras"), not a shortcut around the model/tool-calling |
| CHAT-005 | Message list | `ListView.builder` | grows as the conversation continues; auto-scrolls to the latest message |
| CHAT-006 | User message bubble | Chat bubble (right-aligned, primary color) | echoes what the user typed/sent |
| CHAT-007 | Assistant message bubble | Chat bubble (left-aligned, surface color) | streamed token-by-token from the on-device model as it generates; grows from empty to the full reply |
| CHAT-012 | Text input field | TextField | placeholder "Ask a question…"; `onSubmitted` sends the message |
| CHAT-013 | Mic button | IconButton (mic icon, turns red for ~2s while "listening") | stub — no real speech-to-text; reverts automatically and shows a "Voice input isn't available yet" snackbar |
| CHAT-014 | Send button | IconButton | sends CHAT-012's text as a user message; disabled while a reply is in flight (`_isReplying`) — sending a second message before the first finished let two `_streamAiReply` calls run concurrently, both sharing the single effect-routing pointer, so a slow tool call (e.g. `take_snapshot`) from the first request could complete after the second had repointed it, attaching the first (older) result to the second (newer) message. CHAT-012 shows "Waiting for a reply…" and is disabled the same way |

The reply text always comes from `AiModelManager.reply()` (streamed from the on-device model) once the chat is open, since it only opens when the model is ready; a fixed `_fallbackReplyText` ("Sorry, I couldn't process that — please try again.") is shown only as a defensive fallback if a stream errors out or returns nothing at all.

Conversation state persists across closing/reopening the overlay (see `ChatController` in the Purpose section above) — reopening `CHAT-001` resumes the same conversation, it does not start a fresh one. It resets only on a real app restart. The downloaded model itself also persists (via `llamadart`'s model cache), so subsequent opens go straight to the ready chat without re-downloading.
