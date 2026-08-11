# RecordingScreen

- **Dart file:** `lib/screens/camera_settings/recording_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/recording`
- **Purpose:** Configure the camera's local recording mode — Continuous, Scheduled, Event-Triggered, or Off — reached from the "Recording" row on [camera_settings_screen.md](../camera_settings_screen.md) (a top-level camera setting, not nested under Video & Display, matching Audio/Danger Zone). Mode and schedule are staged as local draft state and only written through `HomesController.updateCamera` after Save; Save simulates a camera round-trip (`simulateCameraSave`) via the shared `SavingOverlay`, matching the pending-vs-confirmed pattern used by Audio/Imaging — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so committed values persist in-memory only, ready for a real stream to read directly later.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| REC-001 | Screen title (AppBar) | Text | "Recording" |
| REC-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget) | disabled until dirty or while saving; on success shows a "Changes saved" snackbar, on failure an error snackbar with the button re-enabled |
| REC-003 | Mode selector | RadioGroup of RadioListTile — Continuous / Scheduled / Event-Triggered / Off | staged locally until Save; each option shows a one-line description of what it does |
| REC-004 | "Estimated footage retained" row | Read-only text | computed live from `Camera.estimatedRecordingTimeRemaining` (free SD space ÷ `bitrateKbps`, same computation [storage_screen.md](storage_screen.md) uses) via the shared `formatApproxDuration` helper (`lib/utils/duration_format.dart`); shows "No new footage is being recorded" when mode is Off, or "No local storage available — see Storage settings" when SD storage is disabled/absent |
| REC-009 | Event-Triggered warning banner | GlassCard with warning icon | shown only when the *staged* mode is Event-Triggered **and** none of the camera's motion/intrusion/line-crossing/person/vehicle detection toggles are enabled — a real check against the live `Camera` fields, not a stub |
| REC-010 | "Set up detection" button (in REC-009) | TextButton | navigates to [detections_screen.md](../detections/detections_screen.md), passing the same `Camera` |
| REC-005 | Schedule section label | Text | shown only when the staged mode is Scheduled |
| REC-006 | Schedule window row | ListTile (in GlassCard), one per window | shows day + start–end time; edit (opens REC-008 pre-filled) and delete icon buttons |
| REC-007 | "Add window" button | OutlinedButton.icon | opens REC-008 with default values (Monday, 8:00 AM–6:00 PM) |
| REC-008 | Add/edit schedule window dialog | AlertDialog (day dropdown + start/end `showTimePicker` rows) | validates end time > start time and rejects a window that overlaps an existing one on the same day (excluding the window being edited), showing an inline error instead of closing |
| REC-011 | Unsaved-changes dialog | AlertDialog (shared `confirmDiscardOnLeave`, `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| REC-012 | Discard button (in REC-011) | TextButton | discards the change and leaves |
| REC-013 | Save button (in REC-011) | FilledButton | saves via `_save()` before leaving |

## Data model

- `Camera.recordingStatus` (`RecordingStatus`: `continuous`, `scheduled`, `eventTriggered`, `off`) — renamed from the previous `continuous`/`motionOnly`/`off` set; `motionOnly` became `eventTriggered` since it now covers all detection types, not just motion. Previously read-only (shown on [camera_info_screen.md](../camera_info_screen.md)'s CAMINFO-007 row) — this screen is the first place it's actually editable, since `Camera.copyWith` didn't even accept a `recordingStatus` override before this screen was added.
- `Camera.recordingScheduleWindows` (`List<RecordingScheduleWindow>`) — new field, only meaningful while `recordingStatus == RecordingStatus.scheduled`. `RecordingScheduleWindow` is `{ day (Mon–Sun), startMinutes, endMinutes }` (minutes since midnight; no overnight-spanning windows — model two windows instead).
