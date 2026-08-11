---
feature_id: FEAT-086
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Unusable Image Condition Detection

Covers the homeowner-facing side of FEAT-086: flagging sustained severe underexposure,
overexposure, or loss of focus as a distinct health condition, separate from a plain
"online/offline" status.

## Scenario: Camera goes badly out of focus after being bumped

**Scenario ID:** SCN-324
**Feature ID:** FEAT-086

**Persona:** Marcus's camera lens gets knocked slightly out of focus while a contractor is doing
unrelated work nearby, and stays blurry afterward.

1. After the image stays visibly blurry for a sustained period (not just a brief momentary
   refocus), Marcus gets a notification: "Image Quality Issue — Camera May Be Out of Focus."
2. The camera's status badge changes to an "attention" state even though the camera is otherwise
   online and recording normally — it's not treated as a connectivity problem.
3. Opening live view, Marcus can see for himself that the image is indeed blurry, confirming the
   alert wasn't a false positive.
4. He manually adjusts the camera's focus (or has it serviced), and once the image sharpens back
   up and stays that way, the alert clears on its own.

**What the user expects:** the camera catches its own image quality problems and tells him
specifically what kind of problem it is, rather than leaving him to notice a blurry feed by
accident days later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct "image quality" health alert (naming the
  specific condition — underexposed, overexposed, or out-of-focus) separately from
  connectivity-related status, while the camera otherwise remains online.
- **[mobile-app]** The app shall automatically clear an image-quality alert once the camera
  reports the condition has resolved and remained resolved for a sustained period.
- **[camera-firmware]** The camera shall continuously assess captured frames for sustained severe
  underexposure, overexposure, or focus loss, and raise a distinct image-quality event only once
  the condition persists past a minimum duration (to avoid flagging brief transients).

## Scenario: Severe overexposure from direct sun glare at a fixed time of day

**Scenario ID:** SCN-325
**Feature ID:** FEAT-086

**Persona:** Marcus's east-facing camera gets blown out by direct morning sun every day for
about 20 minutes, then returns to normal on its own.

1. The first time this happens, Marcus gets an "Image Quality Issue — Overexposed" alert.
2. Because the condition reliably self-resolves within the expected window each day, the app
   doesn't keep re-alerting him every single morning once he's seen the pattern — after
   dismissing it once as a known, recurring, self-clearing condition, subsequent short
   recurrences are logged quietly in history rather than pushed as fresh notifications.
3. If the condition ever lasts unusually long (well beyond the normal ~20 minutes), the app does
   escalate with a fresh alert, since that would indicate something has actually changed.

**What the user expects:** the app is smart enough not to spam him daily about a known, brief,
self-resolving glare pattern, while still catching it if the same-looking condition suddenly
behaves differently (lasting much longer than usual).

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user acknowledge a recurring, self-resolving image-quality
  condition so that subsequent short recurrences are logged in history without generating a new
  push notification each time.
- **[mobile-app]** The app shall re-alert if an acknowledged recurring condition persists
  significantly longer than its established typical duration, treating that as a new,
  unacknowledged occurrence.
- **[camera-firmware]** The camera shall report both the occurrence and the duration of each
  image-quality event, so the app (or cloud) can distinguish a known brief recurrence from an
  abnormally prolonged one.
