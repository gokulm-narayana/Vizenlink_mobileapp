# FEAT-225 — Full Camera Privacy Mode / Physical Shutter

**Origin:** Inferred — non-`§8` seed-doc prose (not from a seed ID row). Found during the final
gap-scan pass, scoped to basic-tier capabilities (SKU-A/SKU-B) per user request, excluding
premium/later-phase SKUs (SKU-E, SKU-F).

**Source passages quoted:**

- §1 Executive Summary, "Recommended launch focus" — does not list this directly, but the
  surrounding launch-focus bullets ("secure onboarding... role-based access, and audit") frame
  privacy as a launch-tier concern, consistent with §6.
- §6 Product structure and proposed SKUs, **SKU-A — Indoor Wi-Fi Camera** (the base, non-premium
  camera tier): "privacy mode or physical shutter where feasible" is listed as one of SKU-A's
  defining capabilities, alongside "microSD recording" and "person/pet/package events" — i.e.
  presented as a basic, expected capability of the entry-level indoor camera, not a premium
  add-on.

**Why it's judged necessary/basic rather than optional polish:** A full privacy mode/shutter
(completely disabling video and audio capture — not just masking regions) is standard,
expected trust functionality on basic consumer indoor cameras (e.g. Nest, Wyze, Eufy indoor
models) — the scenario is a user physically present at home who wants a hard guarantee "this
camera is not recording me right now," which a partial privacy mask cannot provide since the
rest of the frame keeps recording. SKU-A is explicitly the entry-level indoor tier, not a
premium SKU, so this is basic-tier by the seed doc's own SKU classification.

**Cross-check performed (per the Gap scan procedure):**
- Not already covered by any `§8.x` row worded differently — checked all `PRI-*` (§8.13) and
  `VID-*` (§8.1) rows; `VID-010`/`FEAT-009` (Privacy Masks) is the closest match but is
  explicitly a *region-masking* capability ("masking regions of the frame from view/recording/
  AI processing"), not a full-capture disable.
- Not listed in §3.3 Non-goals — that list covers AI-dispatch/access-denial/ANPR/biometric/
  sensitive-classification exclusions, unrelated to this.
- Not a `Gated` seed ID — no seed row addresses this at all, gated or otherwise.

**Priority:** P1 — a strong trust/differentiator expectation on the base indoor SKU, not
itself a P0 core security capability (the camera still functions and secures the property
without it).

**User-Facing:** yes — directly operated by the user (a toggle, or a physical shutter they
close by hand).

**FR Status:** Not started — no FR entry addresses a full capture-disable mode or physical
shutter.

**Status:** confirmed (2026-07-22).
