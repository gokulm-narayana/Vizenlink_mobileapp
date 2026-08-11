---
feature_id: FEAT-186
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Signed & Privacy-Filtered Diagnostic Bundles

Covers FEAT-186 as a homeowner's support-contact flow: generating a device diagnostic bundle
that support can trust (signed) and that the user can trust won't leak their footage or
personal data (privacy-filtered) before it leaves the device.

## Scenario: Generating a diagnostic bundle to send to support

**Scenario ID:** SCN-616
**Feature ID:** FEAT-186

**Persona:** Priya's camera keeps dropping its connection intermittently; support asks her to
send a diagnostic bundle.

1. Priya opens Settings → Help → "Generate diagnostic report" for the affected camera.
2. The app requests the bundle from the camera and shows a short "Preparing report — removing
   footage and personal data" progress state rather than jumping straight to "ready to send."
3. Once ready, the app shows a plain confirmation that the bundle has been privacy-filtered
   (e.g. "No video, audio, or account data included") and is cryptographically signed, before
   offering to attach it to a support ticket or share it.
4. Priya sends it to support with a couple of taps, confident it doesn't include her camera
   footage.

**What the user expects:** she can help diagnose the problem without worrying she's handing over
private footage of her home to a stranger.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a "Generate diagnostic report" action per camera that
  requests a diagnostic bundle and shows an explicit "filtering personal data" progress state
  before the bundle is presented as ready.
- **[mobile-app]** The app shall show a plain-language confirmation that a diagnostic bundle
  excludes footage/audio/PII before offering to share it, not merely assume the user trusts this
  silently.
- **[camera-firmware]** The camera shall strip footage, audio, and other personally-identifying
  data from a diagnostic bundle before it is transmitted off-device, and cryptographically sign
  the filtered bundle so its integrity and origin can be verified afterward.

## Scenario: Support receives a bundle and verifies it wasn't tampered with

**Scenario ID:** SCN-617
**Feature ID:** FEAT-186

**Persona:** A VizenLink support engineer receives Priya's diagnostic bundle as an email
attachment forwarded from a ticket.

1. The support engineer opens the bundle with the internal tooling that checks its signature
   before parsing any content.
2. The signature check confirms the bundle came from a genuine VizenLink camera and was not
   modified after being generated.
3. If the signature check fails, the tooling refuses to parse the file as a trusted diagnostic
   and flags it instead — since an unsigned or altered bundle could otherwise be used to feed
   fabricated diagnostic data into the support process.

**What the user expects (in this case, on behalf of the support process protecting her too):**
a bundle claiming to be from her camera can actually be verified as genuine, so a bad actor
can't submit a forged "diagnostic" and mislead support into a wrong conclusion.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The diagnostic bundle's signature shall be verifiable by VizenLink's
  support tooling as originating from a specific camera and as unmodified since generation.
- **[cloud-components]** A diagnostic bundle whose signature fails verification shall be flagged
  as untrusted by supporting cloud/backend tooling rather than silently accepted as genuine.

## Scenario: Diagnostic generation fails partway on the camera

**Scenario ID:** SCN-618
**Feature ID:** FEAT-186

**Persona:** Priya again, this time her camera loses power mid-generation of the bundle.

1. Priya taps "Generate diagnostic report" but the camera reboots before finishing.
2. The app detects the incomplete/failed generation and reports it plainly ("Report generation
   failed — try again") rather than presenting a partial or corrupted bundle as if it were
   complete and ready to send.
3. Priya retries once the camera is back online, and a fresh, complete bundle is generated.

**What the user expects:** she's never handed something broken and told it's fine — a failed
generation is reported as a failure.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect an incomplete or failed diagnostic-bundle generation and
  report it as a failure requiring retry, rather than presenting a partial bundle as
  ready-to-send.
- **[camera-firmware]** The camera shall not emit a diagnostic bundle that is incomplete or was
  interrupted mid-generation as if it were a complete, valid bundle.
