# FEAT-017 — ISP Image-Quality Controls

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by an ad hoc code/FR-reality
audit against §8.1 Video and imaging's 15 `VID-*` rows, at the user's request — distinct from
the skill's standard seed-doc-prose "Gap scan."

**Why it's necessary/basic:** The ONVIF Imaging service already exposes general ISP
image-quality tuning — brightness, contrast, saturation, sharpness, white-balance mode, and
manual exposure (gain/exposure time) — beyond what any `VID-*` row covers. `VID-007` (WDR)
and `VID-006` (day/night/IR) are already tracked as `FEAT-006`/`FEAT-005`; `VID-008` covers
*encoder* parameters (bitrate/fps/GOP/resolution/quality profile), not ISP image tuning. See
`FR-onvif-stack.md` §2.5 Imaging Service for the implementation-level detail.

**Cross-check performed:** Re-read all 15 `VID-*` rows; none mention brightness, contrast,
saturation, sharpness, white balance, or manual exposure.

**Priority:** P1 — a real, already-implemented capability, but secondary to the core
resolution/codec/recording requirements.

**User-Facing:** yes — installer/admin directly tunes these settings.

**FR Status:** Existing → [FR-OV-050](../FR-onvif-stack.md#25-imaging-service-profile-s-t).

**Status:** confirmed (2026-07-21).
