# FEAT-019 — Mirror/Flip Orientation Control

**Origin:** Inferred — existing FR/code (no seed row). Surfaced when the user asked whether
image flip/mirror/rotation (raised as a general "necessary for a basic CCTV camera" domain
candidate, not from the seed doc or the earlier code/FR audit) was already implemented —
verified against the actual ONVIF and BSP source rather than assumed.

**Why it's necessary/basic:** Image mirror/flip is a baseline installation necessity for any
CCTV camera — a camera mounted upside-down (ceiling) or mirrored needs its image corrected in
software, since the sensor's native orientation rarely matches every mounting position. This
is already implemented end-to-end (ONVIF-configurable Off/Mirror/Flip/Both, applied through
the camera BSP's imaging-parameter path down to the ISP), but has no entry in
`FR-camera-firmware.md` or `FR-onvif-stack.md` — a genuine documentation gap for a real,
shipped capability.

**Cross-check performed:** Grepped the firmware/ONVIF source directly (not the FR docs, which
don't mention it at all) before proposing this — confirmed implemented rather than assumed
missing.

**Priority:** P0 — needed on day one of any installation with a non-standard mount
orientation.

**User-Facing:** yes — an installer sets this during commissioning.

**FR Status:** Existing in code (ONVIF + BSP + ISP), but **no FR entry yet** — this Feature
should drive adding a proper `FR-CF-*`/`FR-OV-*` entry documenting it, rather than being
treated as already fully tracked.

**Status:** confirmed (2026-07-21).
