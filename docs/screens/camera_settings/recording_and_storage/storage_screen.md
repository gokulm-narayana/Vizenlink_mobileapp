# StorageScreen

- **Dart file:** `lib/screens/camera_settings/storage_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/storage`
- **Purpose:** Local SD storage settings, reached from the "Storage" row on [camera_settings_screen.md](../camera_settings_screen.md) (a top-level camera setting, not nested under Video & Display, matching Audio/Recording/Danger Zone). The "Enable SD Storage" toggle and retention duration are staged draft state, written through `HomesController.updateCamera` after Save — same pending-vs-confirmed pattern as [recording_screen.md](recording_screen.md). "Format SD Card" is an *immediate* action independent of Save, matching [danger_zone_screen.md](../danger_zone_screen.md)'s Soft/Hard Reset pattern (its own confirm dialog + simulated round-trip, not gated behind the screen's dirty state). Card capacity/used/free space, health, endurance rating, and any storage-failure condition are read-only device-reported fields (stub-seeded per camera in `HomesController`, same convention as Camera Info's device fields) — not editable here. No CCTV protocol/backend is wired up yet (see CLAUDE.md).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| STOR-001 | Screen title (AppBar) | Text | "Storage" |
| STOR-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget) | saves the staged "Enable SD Storage" toggle (STOR-003) and retention duration (STOR-009) |
| STOR-003 | "Enable SD Storage" toggle | SwitchListTile | staged; independent of whether a card is physically present |
| STOR-008 | Storage-failure banner | GlassCard with error icon, persistent | shown when `camera.storageFailure != StorageFailure.none`, naming the specific condition (Full / Card removed / Read-only / Unavailable) |
| STOR-004 | Card status row | Read-only text | capacity + used/free space (e.g. "64 GB card — 20 GB used, 44 GB free"), or "No SD card detected" when `sdCardPresent` is false |
| STOR-005 | "Estimated time remaining" row | Read-only text, computed live | `Camera.estimatedRecordingTimeRemaining` (free space ÷ `bitrateKbps`) via the shared `formatApproxDuration` helper (`lib/utils/duration_format.dart`); reflects the staged Enable-toggle value, not just the committed one; hidden when no card is present |
| STOR-006 | Card health row | Read-only text | wear-level percent + qualitative label (Good ≥80% / Fair ≥50% / Poor <50%); appends an end-of-life warning when Poor |
| STOR-007 | Non-endurance-card warning | GlassCard | shown when `!camera.sdCardEnduranceRated`; guidance text recommending a surveillance-rated card, non-blocking |
| STOR-009 | Retention duration control | RadioGroup of RadioListTile — 3/7/14/30/60 days | staged |
| STOR-010 | Retention feasibility warning | GlassCard | shown when the staged retention period exceeds what current free space + bitrate can realistically hold |
| STOR-011 | "Format SD Card" button | OutlinedButton.icon, destructive styling | immediate action, independent of Save |
| STOR-012 | Format confirmation dialog | AlertDialog | data-loss warning; Cancel/Format. On confirm, simulates a camera round-trip (`simulateCameraSave`) via the shared `SavingOverlay` ("Formatting…"), then resets `sdCardUsedGb` to 0 and clears `storageFailure` on success |
| STOR-013 | Deletion history section label | Text | |
| STOR-014 | Deletion history entry row | ListTile, static mock entries | "{n} clips removed — {date}, retention policy" — read-only log, not tied to any real deletion pipeline |
| STOR-015 | Unsaved-changes dialog | AlertDialog (shared `confirmDiscardOnLeave`, `lib/widgets/navigation_leave_guard.dart`) | shown when leaving while dirty |
| STOR-016 | Discard button (in STOR-015) | TextButton | |
| STOR-017 | Save button (in STOR-015) | FilledButton | |

## Data model

New `Camera` fields (`lib/models/camera.dart`): `sdStorageEnabled`, `sdCardPresent`, `sdCardCapacityGb`, `sdCardUsedGb`, `sdCardHealthPercent`, `sdCardEnduranceRated`, `retentionDays`, and `storageFailure` (`StorageFailure`: `none`/`full`/`cardRemoved`/`readOnly`/`unavailable`). Two derived getters shared with [recording_screen.md](recording_screen.md): `sdCardFreeGb` (capacity minus used, zero if disabled/absent) and `estimatedRecordingTimeRemaining` (a `Duration`, computed from free space and `bitrateKbps`).

Seed data (`HomesController`) intentionally varies these across the mock cameras so every state is visible without needing to change anything: `cam-2` (online) has a non-endurance card with poor health (42%) — this is the one camera that actually demonstrates the "Needs Attention" `CameraLiveStatus` while online, since `cam-3`'s poor health/failure is masked by it being offline (`Camera.liveStatus` treats offline as higher-priority than any health condition). `cam-3` (offline) has a `StorageFailure.full` condition and poor health. `cam-6` has no card present (`sdCardPresent: false`).
