# Camera Chatbot (assistant overlay)

- **Dart file:** `lib/widgets/camera_chatbot.dart`
- **Route:** none — opened via `showCameraChatbot(context, ...)`, documented here rather than as a routed screen (like [scan_cameras_screen.md](../scan/scan_cameras_screen.md)'s scanning popup)
- **Purpose:** A floating chat assistant reached from the Dashboard's `DASH-020` FAB. Replies use real on-device AI (Qwen3.5-0.8B, via `AiModelManager` / the `llamadart` package) — the chat itself only opens once the model is downloaded and ready; there is no canned-reply-only mode. Event/video/image result cards alongside a reply are still built from existing local mock data (`EventsController`, `HomesController`'s selected home) via keyword matching, regardless of the AI text. Downloading the ~0.6GB model is strictly opt-in (see CLAUDE.md: no backend/AI dependency without explicit confirmation) — declining closes the whole flow rather than falling back to a non-AI chat, since the chatbot's entire purpose is the AI.

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
| CHAT-004 | Empty state + quick-prompt chips | Column of `ActionChip`s | shown before the first message; tapping a chip sends it as a message immediately |
| CHAT-005 | Message list | `ListView.builder` | grows as the conversation continues; auto-scrolls to the latest message |
| CHAT-006 | User message bubble | Chat bubble (right-aligned, primary color) | echoes what the user typed/sent |
| CHAT-007 | Assistant message bubble | Chat bubble (left-aligned, surface color) | streamed token-by-token from the on-device model as it generates; grows from empty to the full reply |
| CHAT-009 | Event result card | Small card (event-type icon + label + camera name), horizontally scrollable row under an assistant bubble | pulled from `EventsController`, sorted most-recent-first, optionally filtered to a mentioned camera name; tapping navigates to that event's detail screen (`context.push('/events/detail', extra: event)`) and closes the overlay |
| CHAT-010 | Video result card | Thumbnail + play icon + duration chip, horizontally scrollable row | stub — reuses `RecordedEvent` mock data as a stand-in for a real clips backend; tapping shows a "Playback preview not available yet" snackbar |
| CHAT-011 | Image result card | Thumbnail, horizontally scrollable row | pulled from the selected home's camera `thumbnailUrl`s; tapping opens the CHAT-015 full-screen preview |
| CHAT-015 | Image preview dialog | `Dialog.fullscreen` (black background) | opened by tapping a CHAT-011 card; image is wrapped in an `InteractiveViewer` (pinch-to-zoom, 1x–4x, same pattern as [camera_live_screen.md](../camera_live/camera_live_screen.md)'s video zoom) |
| CHAT-016 | Close button (in CHAT-015) | IconButton | dismisses the preview |
| CHAT-017 | Share button (in CHAT-015) | IconButton | downloads the image bytes to a temp file and shares via `SharePlus` (same pattern as `EventDetailScreen`'s EVTDET-013 share action) |
| CHAT-018 | Save button (in CHAT-015) | IconButton | saves the image to the device gallery via `Gal.putImageBytes` (same pattern as `EventDetailScreen`'s EVTDET-012 download action) |
| CHAT-012 | Text input field | TextField | placeholder "Ask a question…"; `onSubmitted` sends the message |
| CHAT-013 | Mic button | IconButton (mic icon, turns red for ~2s while "listening") | stub — no real speech-to-text; reverts automatically and shows a "Voice input isn't available yet" snackbar |
| CHAT-014 | Send button | IconButton | sends CHAT-012's text as a user message |

## Result-card matching (still keyword-based, independent of the AI text)

`_computeResultData` in `_CameraChatbotSheetState` checks the user's text (lowercased) for keywords, in this order:
1. "video"/"clip"/"record" → up to 2 most-recent events as CHAT-010 video cards.
2. "image"/"photo"/"snapshot"/"picture" → up to 3 camera thumbnails from the selected home as CHAT-011 image cards.
3. "event"/"motion"/"alert"/"today", or the text mentions a camera name → up to 3 events as CHAT-009 event cards, filtered to the mentioned camera if one matches.
4. Otherwise → no result cards, just the AI's text reply.

The reply text itself always comes from `AiModelManager.reply()` (streamed from the on-device model) once the chat is open, since it only opens when the model is ready; `_cannedReplyText` remains only as a defensive fallback if a stream errors out mid-reply.

No conversation state persists once the overlay is closed — reopening `CHAT-001` starts a fresh, empty chat. The downloaded model itself does persist (via `llamadart`'s model cache), so subsequent opens go straight to the ready chat without re-downloading.
