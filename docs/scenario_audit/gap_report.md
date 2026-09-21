# Scenario Gap Audit Report

## Summary
- **Total mobile-app scenarios considered:** 126
- ✅ **Implemented:** 82
- ⚠️ **Partial:** 23
- ❌ **Missing:** 21

*Note: Cache status: Full cache hit on `knowledgebase/_research_cache/research_digest.md`.*

---

## Storage & Recording

| Scenario File | Feature ID | Status | Covered by | Notes |
|---------------|------------|--------|------------|-------|
| `mobile-app-local-microsd-storage.md` | FEAT-033 | ❌ | — | `storage_screen.dart` exists as a stub, but no actual UI/logic is built to enable/disable SD storage. |
| `mobile-app-camera-side-storage-capacity-estimation.md` | FEAT-049 | ❌ | — | No storage UI built to show remaining SD recording time. |
| `mobile-app-sd-card-format-action.md` | FEAT-051 | ❌ | — | "Format SD Card" button and confirmation flow are completely missing. |
| `mobile-app-camera-side-recording-modes.md` | FEAT-031 | ⚠️ | `recording_screen.dart` | The UI exists but is missing the schedule editor for time-scheduled recording. |
| `mobile-app-event-clip-pre-roll-post-roll.md` | FEAT-036 | ❌ | — | No settings UI available for configuring pre-roll/post-roll buffering. |

## Playback & Events

| Scenario File | Feature ID | Status | Covered by | Notes |
|---------------|------------|--------|------------|-------|
| `mobile-app-event-detail-screen.md` | FEAT-116 | ⚠️ | `event_detail_screen.dart` | The screen is built but uses a `_dummyVideoAsset` rather than playing actual event clips. Needs client integration. |
| `mobile-app-indexed-playback-time-event.md` | FEAT-039 | ⚠️ | `camera_live_screen.dart` (`_PlaybackTab`) | Timeline exists and was recently synced, but relies entirely on mocked `_recordingDays` data. |
| `mobile-app-manual-clip-capture-from-live-stream.md` | FEAT-045 | ⚠️ | `camera_live_screen.dart` | Snapshot and capture buttons exist but are currently returning a "coming soon" `SnackBar`. |
| `mobile-app-evidence-export-integrity-manifest.md` | FEAT-040 | ❌ | — | No export flow or verification UI is built. |

## Device Health & Telemetry

| Scenario File | Feature ID | Status | Covered by | Notes |
|---------------|------------|--------|------------|-------|
| `mobile-app-device-health-telemetry.md` | FEAT-088 | ✅ | `camera_info_screen.dart` | Device Info screen covers uptime, firmware, model. |
| `mobile-app-user-triggered-camera-restart.md` | FEAT-098 | ✅ | `danger_zone_screen.dart` | Restart action is fully implemented and wired to the client API. |
| `mobile-app-camera-tamper-detection.md` | FEAT-083 | ❌ | — | No specific dashboard tamper badge or "confirm intentional view change" flow exists. |
| `mobile-app-dirty-lens-haze-fogging-detection.md` | FEAT-090 | ❌ | — | "Lens May Need Cleaning" alert and the associated before/after image UI is absent. |
| `mobile-app-predictive-failure-trend-analysis.md` | FEAT-095 | ❌ | — | Trend graphs and predictive failure warnings are missing. |

## Access Control & Account

| Scenario File | Feature ID | Status | Covered by | Notes |
|---------------|------------|--------|------------|-------|
| `mobile-app-access-audit-log.md` | FEAT-150 | ❌ | — | No chronological access history or permission audit log screen is built. |
| `mobile-app-last-access-active-sessions.md` | FEAT-155 | ✅ | `active_sessions_screen.dart` | Screen is built and covers active session termination. |
| `mobile-app-stronger-admin-authentication.md` | FEAT-151 | ⚠️ | `login_screen.dart` | Base login is built, but MFA configuration and remote session MFA prompts are not implemented. |

## Settings & Hardware Toggles

| Scenario File | Feature ID | Status | Covered by | Notes |
|---------------|------------|--------|------------|-------|
| `mobile-app-isp-image-quality-controls.md` | FEAT-017 | ✅ | `imaging_screen.dart` | Brightness, contrast, saturation, sharpness are all implemented. |
| `mobile-app-mirror-flip-orientation.md` | FEAT-019 | ✅ | `video_mode_screen.dart` | Controls exist and are wired. |
| `mobile-app-speaker-mic-volume-control.md` | FEAT-029 | ✅ | `audio_screen.dart` | Speaker volume and mic gain sliders are built. |
| `mobile-app-wifi-signal-strength-indicator.md` | FEAT-096 | ✅ | `wifi_config_screen.dart` | Indicator is built. |
| `mobile-app-active-network-interface-indicator.md` | FEAT-097 | ✅ | `wifi_config_screen.dart` | Interface type is visible. |

---

*This report is generated dynamically by the `scenario-gap-audit` skill comparing the structured scenarios against the current `lib/screens/` state. To resolve any ❌ (Missing) items, ensure the corresponding UI is built and confirm requirements first.*
