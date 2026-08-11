# Research Digest — scenario-gap-audit

Condensed extraction of the seed doc, `features/FEAT-*.md`, and `scenarios/mobile-app-*.md`, built from a full cold-start read. Paired with `manifest.json` (path/mtime/size per source file). On the next audit run, re-stat each source file; if mtime+size match the manifest entry, trust this digest instead of re-reading that file.

## Seed doc summary (`VizenLink_Home_Community_CCTV_Feature_Seed_v0.1.md`)

A v0.1 research seed (not an approved spec) proposing ViZenLink's direction for a home/apartment/community security camera product: "local-first, AI-assisted security camera platform with consumer-grade usability and professional-grade reliability" for villas, apartment communities, and small offices. Four components: AI Camera (edge detection, local capture, health monitoring), NVR (multi-camera storage/coordination), VMS (event review, investigation, org admin), Mobile App (setup, live view, playback, alerts, sharing, recovery). Core principles: local-first operation, evidence-before-automation (AI produces candidate events requiring human verification), reduced nuisance alerts, consumer-simple/installer-capable design, privacy as a system property, separation of detection from policy, ONVIF-based standards integration, security throughout the lifecycle.

Recommended P0 release scope: person/vehicle/animal/package detection; configurable zones/line-crossing/after-hours rules; tamper/health monitoring; local continuous/event recording with offline buffering; live view/playback/export/sharing; secure onboarding and role-based access; WiFi and PoE/NVR deployment; household vs. organization role models. Explicitly excluded from initial scope: face recognition, high-speed ANPR, "suspicious behavior" scoring, automatic law-enforcement escalation, automatic access denial.

Six SKU classes, five deployment domains, nine personas (Home Owner, Family Viewer, Community/Site Admin, Security Operator, Resident/Tenant Viewer, Small Office Manager, Installer, Support Technician, Auditor). §8 is a prioritized (P0/P1/P2/Gated) requirements catalog across video/imaging, audio/deterrence, recording/storage/evidence, edge AI, security rules, camera health, offline sync, mobile/VMS workflow, live viewing, access control, onboarding, cybersecurity, privacy/governance, interoperability — these seed the FEAT-* files.

## Feature files (`features/FEAT-*.md`)

| Feature | Title | Component | Mobile UI implication |
|---|---|---|---|
| FEAT-014 | JPEG Snapshot Capture | both | Snapshot button on live view (authenticated) |
| FEAT-015 | OSD Overlay | mobile-app | Camera settings: text/timestamp/logo overlay editor, burned into stream |
| FEAT-017 | ISP Image-Quality Controls | mobile-app | Image Quality panel: brightness/contrast/saturation/sharpness/white-balance/exposure |
| FEAT-019 | Mirror/Flip Orientation | mobile-app | Off/Mirror/Flip/Both control in camera settings |
| FEAT-020 | Image Rotation / Corridor Format | mobile-app | 90°/270° rotation selector (not started even at firmware/ONVIF layer) |
| FEAT-027 | Buzzer Auto-Stop Safety Timer | mobile-app | Buzzer status (active/inactive + remaining time) + Stop button |
| FEAT-028 | Rule-Driven Automatic Buzzer Alert Channel | mobile-app | Per-rule "trigger buzzer automatically" toggle |
| FEAT-029 | Speaker/Mic Volume Control | mobile-app | Speaker volume + mic gain sliders (genuine capability gap, not started) |
| FEAT-030 | AEC for Two-Way Talk | none (User-Facing: no) | Backend audio pipeline only |
| FEAT-045 | Manual Clip Capture from Live Stream | mobile-app | "Capture Clip" button on live view |
| FEAT-046 | Multi-Camera Grid View | VMS/NVR only | N/A to mobile app |
| FEAT-047 | Media Sharing / Share-Link | VMS/NVR only | N/A to mobile app |
| FEAT-048 | Cloud Snapshot/Thumbnail Upload for Notifications | mixed | Thumbnail in push notifications + alert-history list |
| FEAT-049 | Camera-Side Storage Capacity Estimation | mobile-app | Storage panel: free space + estimated remaining recording time |
| FEAT-051 | SD Card Format Action | mobile-app | "Format SD Card" button, confirmation-gated |
| FEAT-082 | Per-Rule Enable/Disable Toggle | mobile-app | Enable/disable switch per rule in rules list |
| FEAT-096 | WiFi Signal Strength Indicator | mobile-app | Signal-strength indicator, shown only on WiFi |
| FEAT-097 | Active Network Interface Indicator | mobile-app | WiFi/Ethernet label pairing with FEAT-096 |
| FEAT-098 | User-Triggered Camera Restart w/ Health Confirmation | mobile-app | "Restart Camera" button + post-restart health outcome |
| FEAT-111 | Cloud/MQTT Connection Auto-Recovery | mobile-app | No explicit control; passive status reflection |
| FEAT-112 | WiFi Auto-Reconnect | mobile-app | Automatic offline→online transition, no manual re-provisioning |
| FEAT-113 | Buffered-Event Timestamp Reconciliation | none (User-Facing: no) | No new UI; corrected timestamp shown via existing event display |
| FEAT-225 | Full Camera Privacy Mode / Physical Shutter | mobile-app | Prominent Privacy Mode toggle, full video+audio disable, SKU-A tier |

## Scenario files (`scenarios/mobile-app-*.md`, 126 files)

Format: File — FeatureID — one-line capability — UI needed (concrete).

- 24-hour-offline-event-retention-target — FEAT-108 — documented 24h offline retention target + disclosed loss messaging — help content + dropped-event disclosure banner.
- access-audit-log — FEAT-150 — read-only chronological access/permission audit log — "Access history" screen.
- accessible-status-severity-indicators — FEAT-220 — icon+text (never color-only) status/severity indicators, screen-reader operable — accessibility annotations across all status badges.
- active-network-interface-indicator — FEAT-097 — WiFi/Ethernet interface line, signal row only on WiFi — device-details "Connected via" line.
- after-hours-rule-template — FEAT-069 — prebuilt "After-Hours Activity" rule template — Rule Templates screen/flow.
- alert-evidence-snapshot-clip — FEAT-056 — every alert opens with snapshot + "Watch clip" w/ processing/ready/unavailable states — alert detail 3-state clip control.
- alert-quality-measurement-gating — FEAT-218 — thumbs-up/down accuracy feedback per alert — lightweight feedback control.
- approval-workflow-sensitive-access — FEAT-154 — broad-scope grants route through owner approval — pending-approval screen w/ approve/decline.
- audio-recording-toggle — FEAT-022 — independent audio-recording toggle + persistent mic indicator — dedicated toggle separate from video, default-off policy variants.
- buzzer-auto-stop-safety-timer — FEAT-027 — bounded self-terminating buzzer, restart-not-stack, status+stop control — buzzer status view + Stop control.
- camera-dashboard — FEAT-114 — dashboard grid/list w/ status/recording/health/unread badges — dashboard w/ real-time card updates.
- camera-offline-detection-recovery-logging — FEAT-085 — logged offline occurrences w/ start/recovery/duration — camera history log entries.
- camera-side-recording-modes — FEAT-031 — Continuous/Scheduled/Event-Triggered recording mode config — recording-mode settings screen + schedule editor.
- camera-side-storage-capacity-estimation — FEAT-049 — approximate remaining SD recording time — storage settings screen w/ live estimate.
- camera-tamper-detection — FEAT-083 — distinct "view blocked" vs "view moved" tamper alerts — dashboard tamper badge + reference-view comparison + confirm-intentional flow.
- cellular-data-usage-awareness — FEAT-145 — WiFi/cellular indicator + pre-stream confirmation on cellular — connection-type indicator + confirmation prompt.
- cloud-mqtt-connection-auto-recovery — FEAT-111 — automatic MQTT/push/control recovery — passive status only, no manual reconnect UI.
- cloud-snapshot-thumbnail-upload-for-notifications — FEAT-048 — push/alert-history thumbnails w/ "image unavailable" fallback — thumbnail + fallback state.
- concurrent-multi-viewer-live-view — FEAT-142 — multiple viewers up to a cap, explicit "limit reached" message — live view + limit-reached error state.
- configurable-retention-verified-deletion — FEAT-190 — per-camera retention config + verified deletion + deletion history — Storage & Retention screen + Deletion history log.
- core-object-detection — FEAT-052 — correctly classed alerts (person/vehicle/animal/package), class filtering, low-confidence hedging — class labels on alert list/detail, generic "Motion detected" fallback.
- corrective-action-guidance — FEAT-094 — plain-language corrective action + mark-done + verify + escalate — health-alert detail w/ action section + escalation CTA.
- cross-user-event-status-sync — FEAT-133 — real-time cross-user event status sync w/ attribution — event detail real-time status + refresh-on-reconnect.
- current-access-roster — FEAT-157 — "who has access" roster w/ role/scope + inline revoke + camera filter — roster screen.
- daily-security-digest — FEAT-128 — daily digest at configurable time, incl. "all quiet" — digest screen + delivery-time/opt-out settings.
- data-freshness-indicator — FEAT-122 — Live/Delayed/Last known/Local-only/unavailable badge — freshness badge across live view, dashboard, playback.
- data-handling-policy — FEAT-188 — per-deployment-type data policy, ack'd at setup, reviewable later — onboarding policy step + Settings → Privacy screen + change-impact diff.
- day-night-mode — FEAT-005 — Auto/Day/Night display + manual override, live effective-state indicator — mode indicator distinct from configured mode + selector + error state.
- deep-link-live-view — FEAT-115 — notification/card/event tap deep-links to live view — deep-link routing + unreachable-camera fallback state.
- detection-sensitivity-tuning — FEAT-054 — per-camera sensitivity slider — sensitivity control scoped per camera.
- deterrence-confirmation-gate — FEAT-024 — siren/spotlight/warning trigger gated by confirmation — confirmation dialog + active-state indicator + failure state.
- device-health-telemetry — FEAT-088 — uptime/firmware/model/last-recording + reboot-pattern flag — Device Info screen + reboot-pattern callout.
- diagnostic-bundles — FEAT-186 — signed privacy-filtered diagnostic bundle for support — "Generate diagnostic report" action + progress/share states.
- digital-zoom — FEAT-011 — pinch-to-zoom in live+playback, labeled digital — zoom gesture + "digital zoom" badge.
- direct-camera-to-cloud-live-view — FEAT-144 — standalone-camera direct cloud live view, may be gated — transparent live view entry + gated "not available, check firmware" message.
- dirty-lens-haze-fogging-detection — FEAT-090 — gradual lens haze alert, distinct from sudden faults, markable recurring — "Lens May Need Cleaning" alert w/ before/after image + mark-recurring.
- dropped-downgraded-event-accounting — FEAT-106 — honest accounting of dropped/downgraded events + monthly summary — distinct timeline entry for downgraded events + loss summary view.
- dwell-loitering-detection — FEAT-071 — zone dwell/loitering threshold alert w/ brief-exit tolerance — dwell-threshold field on zone rule + distinct "Loitering" alert.
- edge-event-creation-latency — FEAT-213 — near-instant event appearance in timeline (backend perf) — auto-refreshing timeline, no manual pull-to-refresh.
- event-bookmarks-incident-collections — FEAT-127 — bookmark events + named incident collections — bookmark toggle + collections screen.
- event-clip-pre-roll-post-roll — FEAT-036 — configurable pre-roll/post-roll around trigger — clip player marker + duration settings.
- event-detail-screen — FEAT-116 — type/camera/zone/time/snapshot/clip/confidence/rule context — event detail screen w/ hedged confidence wording + processing state.
- event-filtering — FEAT-119 — multi-dimensional AND filtering + saved presets — filter panel (camera/type/class/zone/severity/status/date) + presets.
- event-lock-evidence-protection — FEAT-041 — lock/unlock clip from retention deletion, works even when storage full — lock toggle + persistent lock badge.
- evidence-export-integrity-manifest — FEAT-040 — export bundled w/ metadata + cryptographic integrity manifest — export action + verification flow.
- export-watermarking-redaction-indicator — FEAT-195 — burned-in watermark + "Redacted" indicator + gated unredacted export — export preview watermark + Redacted badge + gated override.
- factory-reset-label-reserved — FEAT-161 — "Factory Reset" label reserved for fully destructive reset, multi-step confirm — distinct Restart vs Factory Reset actions + multi-step confirm.
- full-color-low-light-mode — FEAT-010 — IR B&W vs full-color night mode, capability-gated, spotlight warning — Night Vision mode selector + capability gating + warning dialog.
- full-privacy-mode-physical-shutter — FEAT-225 — full video/audio-disable Privacy Mode, synced across users — persistent "Privacy Mode: ON" badge + confirmed-vs-sent shutter states + cross-user notification.
- gate-door-left-open — FEAT-076 — sustained-open gate/door region alert — region-marking rule config + distinct alert type.
- generic-digital-io-relay — FEAT-207 — relay output + digital input config, capability-gated visibility — I/O settings screen (hidden on unsupported SKUs).
- health-state-model — FEAT-084 — Online / Online-Remote-Access-Limited / Offline 3-state model — 3-state status badge + drill-down explanation.
- household-vs-organization-roles — FEAT-146 — fixed household roles vs richer org roles, account/site switcher — "People with access" screen variants + switcher.
- image-rotation-corridor-format — FEAT-020 — 90°/270° rotation for portrait mounts — rotation control + portrait-aware viewer.
- indexed-playback-time-event — FEAT-039 — time-jump + event-indexed navigation — playback time-jump control + event next/prev nav.
- installation-reference-view-capture — FEAT-165 — capture reference snapshot at commissioning, owner can re-set — commissioning "Set as reference view" step + owner re-set action.
- installer-support-no-default-footage-access — FEAT-152 — Installer/Support default to device-only access, footage access explicitly granted/audited — role-permission display + explicit grant flow + audit log entries.
- installer-test-mode-notification-suppression — FEAT-166 — commissioning "Test Mode" suppresses end-user notifications, bounded duration — Test Mode toggle + banner + "Complete Installation" confirm.
- isp-image-quality-controls — FEAT-017 — brightness/contrast/saturation/sharpness/white-balance/exposure + reset — Image Quality settings screen.
- jpeg-snapshot-capture — FEAT-014 — capture still JPEG from live view — snapshot button + explicit failure state.
- lan-live-view-startup-latency — FEAT-215 — ~2s p95 first-frame, "connection is slow" beyond threshold — loading indicator + slow-connection message.
- last-access-active-sessions — FEAT-155 — last-access time + active sessions + remote termination + unrecognized-session password prompt — Account Security screen.
- lens-dewarping — FEAT-012 — fisheye vs dewarped view toggle, capability-gated — view-mode control, per-camera preference persisted.
- local-event-evidence-buffering — FEAT-100 — WAN-outage local buffering + correct-timestamp backfill + capacity-exceeded disclosure — backfill banner note + disclosure in outage summary.
- local-microsd-storage — FEAT-033 — enable/disable SD storage independent of card presence — storage on/off toggle + "no card" status.
- localization-architecture — FEAT-221 — English-only now, architecture supports future languages — Settings → Language screen (even if only English today).
- manual-clip-capture-from-live-stream — FEAT-045 — manual "Capture Clip" button during live view — capture button + retry-able error on failure.
- mirror-flip-orientation — FEAT-019 — horizontal/vertical flip, persists — independent flip toggles + live preview.
- mobile-live-view-substream — FEAT-002 — automatic lightweight mobile substream — fast live view + reconnecting overlay + explicit fallback-to-main-stream option.
- network-recovery — FEAT-124 — distinct "Reconnect Camera" flow after router/WiFi change, preserves ownership — Reconnect Camera flow separate from Add Camera + shortened password-only path.
- night-vision-usability-monitoring — FEAT-087 — "Night Vision Unusable" alert, sustained low quality, mark-as-monitoring — distinct alert + monitoring suppression + auto-clear.
- notification-preferences — FEAT-120 — per-camera/type/severity/schedule/per-user notification config — notification settings w/ default-vs-customized indicator.
- object-tracking — FEAT-062 — continuous presence = one alert, not repeated — single continuous-event alert/timeline entry.
- online-but-unusable-health-display — FEAT-089 — "Needs Attention" for connected-but-degraded cameras — dashboard badge replacing plain "Online" + detail listing all conditions.
- optional-cloud-event-backup — FEAT-043 — opt selected event types/severities into cloud backup — backup settings + per-event badge + quota warning.
- osd-overlay — FEAT-015 — timestamp + custom-label overlay burned into stream — overlay settings toggle + text field.
- ownership-transfer-decommission — FEAT-125 — high-friction Transfer Ownership / Decommission flows, wipe credentials — distinct flows w/ re-confirmation + pending-until-confirmed state.
- package-arrival-removal — FEAT-075 — distinct "package detected"/"package removed" alerts — distinct alert types separate from Person.
- parking-duration-rule — FEAT-072 — vehicle parked-past-threshold alert — duration-threshold field on vehicle rule + distinct "Vehicle parked" alert.
- per-action-permission-enforcement — FEAT-147 — each action independently permission-enforced, mid-action revocation halts — controls hidden (not disabled) per permission + interruption message.
- per-site-per-camera-access-scope — FEAT-148 — role grants scoped to site + camera subset — per-user site/camera scope picker, out-of-scope cameras omitted.
- post-mount-commissioning-checklist — FEAT-164 — guided installer checklist before marking install complete — Commissioning flow w/ ordered checklist, gated Mark Complete.
- post-upload-clip-integrity-verification — FEAT-103 — Uploading→Verifying→Verified before trusted/exportable — sync-status indicator + gated export.
- predictive-failure-trend-analysis — FEAT-095 — proactive time-to-failure warning before hard failure — predictive-warning banner + trend graph.
- privacy-masks — FEAT-009 — admin-only permanent blackout mask regions — mask editor (admin-only) + masked view for all viewers.
- prompt-access-revocation — FEAT-149 — revocation immediately terminates active sessions — instant termination message + reconnect-rejected state.
- push-notification-delivery-latency — FEAT-214 — seconds-level push + deep-link on tap — tap→direct navigation to event/live view.
- qr-assisted-device-registration — FEAT-160 — QR-scan auto-fill of serial/pairing info — QR scanner + manual-entry fallback.
- queue-full-policy-definition — FEAT-104 — disclosed finite offline-queue capacity + drop policy — setup/help disclosure + post-outage drop report.
- recording-storage-failure-detection — FEAT-038 — critical, specific, persistent storage-failure health state — push + persistent critical banner naming condition.
- repetitive-event-grouping — FEAT-121 — burst of similar events collapse into one grouped notification — grouped notification opening individual-event list.
- resumable-sync-without-duplication — FEAT-102 — interrupted uploads resume, no duplicate timeline entries — dedup timeline + stall/resume sync indicator.
- retention-policy-configuration — FEAT-037 — simplified retention duration control + feasibility warning + locked-clip protection — retention settings + locked-clip indicator.
- role-gated-event-actions — FEAT-117 — per-event action buttons filtered by role, server-enforced — role-filtered action set + permission-denied error.
- rule-driven-buzzer-alert — FEAT-028 — per-rule buzzer alert-channel toggle — Buzzer toggle on rule config, alongside push channel.
- rule-enable-disable-toggle — FEAT-082 — per-rule enable/disable, distinct from schedule/deletion — toggle + distinct status indicators in rules list.
- rule-object-class-filter — FEAT-066 — rule scoped to object class(es), unset = explicit "Any" — class-filter control + "Any" badge.
- rule-recalibration-view-change — FEAT-081 — suspend rules on view change, prompt recalibration — notice listing suspended rules + per-rule confirm/redraw.
- rule-scheduling — FEAT-067 — recurring schedule + temporary date-range exceptions — schedule editor + temporary-exception add-on.
- rule-test-mode — FEAT-070 — Test mode logs would-be events without notifying, before Live — Test/Live toggle + test-event log + duration nudge.
- sd-card-format-action — FEAT-051 — manual/auto-offered SD format w/ destructive warning — "Format Card" action + confirmation dialogs.
- security-critical-update-messaging — FEAT-187 — distinct urgent messaging for security-critical OTA vs routine, escalating reminders — red/amber critical banner + escalating reminder cadence.
- security-update-support-period — FEAT-180 — camera's security-update support end date + policy link — Device Info "Security updates" line + About link.
- severity-based-eviction-priority — FEAT-105 — disclose higher-severity events prioritized in offline queue, honest overload disclosure — two-variant post-outage disclosure message.
- site-type-installation-templates — FEAT-169 — site-type template picker at commissioning (villa/gate/parking/lobby/corridor/office) — template picker step + editable-after-apply.
- smart-home-ecosystem-integration — FEAT-210 — opt-in link/unlink to Alexa/Google/HomeKit, force-revocable — Smart Home Integrations screen + force-revoke notice.
- speaker-mic-volume-control — FEAT-029 — independent speaker volume + mic gain, persisted — two sliders in audio settings.
- storage-failure-alert-prioritization — FEAT-123 — storage-failure alerts pinned, bypass quiet hours, persist until ack — pinned red-banner health section + explicit ack action.
- storage-media-endurance — FEAT-224 — guide toward endurance-rated SD cards, wear-health indicator, EOL warning — setup guidance + storage-health indicator.
- stronger-admin-authentication — FEAT-151 — MFA required for Owner/admin + remote sessions, Viewer-tier exempt — MFA setup screen + remote re-auth prompt.
- sync-state-display — FEAT-101 — per-event sync lifecycle state shown live — sync-state badge (Uploading/Verified/Failed/Discarded).
- time-bounded-access-grants — FEAT-153 — explicit expiration on temporary access, auto-expires — expiration field in grant flow + "Access expired" message.
- timestamp-integrity — FEAT-008 — trusted-by-default timestamps, "uncertain time" flag after prolonged NTP loss — uncertain-time indicator + marked affected recordings.
- two-way-talk — FEAT-023 — permission-gated push-to-talk, single-speaker-at-a-time — talk control + transmit indicator + contention state.
- unified-timeline — FEAT-118 — single scrubbable timeline w/ event markers + explicit gap labeling — timeline w/ tap-to-jump, zoom, labeled no-recording gaps.
- unusable-image-condition-detection — FEAT-086 — sustained exposure/focus fault as distinct "Image Quality" health alert, smart-suppression of recurring conditions — distinct alert + acknowledge-recurring action.
- unverified-ai-event-messaging-guardrail — FEAT-131 — hedged wording for unverified AI detections until human confirms — consistent hedged-copy templates + Confirm/False Alert action.
- user-invitation-access-grant — FEAT-156 — invite by phone/email + role/scope in one flow, deep-link through install — Invite flow + pending/accepted status + install→accept deep link.
- user-triggered-camera-restart — FEAT-098 — on-demand restart w/ tracked state + post-restart health outcome — Restart button + Restarting state + outcome report.
- vulnerability-disclosure-process — FEAT-178 — "Report a security issue" entry linking to disclosure process — Settings → About/Legal entry.
- wdr-backlight-handling — FEAT-006 — simple WDR on/off, capability-gated — WDR toggle in image settings.
- wifi-auto-reconnect — FEAT-112 — camera auto-reconnects after outage, no re-provisioning — standard offline/online badge only, no re-provisioning prompt.
- wifi-ble-provisioning-completion-time — FEAT-223 — BLE provisioning ~30s target, Soft-AP fallback at 60s — Add Camera flow w/ live progress + fallback guidance + failure screen.
- wifi-signal-strength-indicator — FEAT-096 — live signal meter w/ qualitative label + corrective suggestion — signal meter during setup + ongoing device status.
- zone-line-rule-authoring — FEAT-065 — draw polygon zones/directional lines w/ validation — zone/line drawing tools + validation errors.
- zone-trigger-types — FEAT-068 — per-rule trigger type (entry/exit/crossing/presence) — trigger-type selector + alert labeled by trigger type.
