---
feature_id: FEAT-063
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Cross-Camera Appearance Correlation

Covers FEAT-063 (NVR/VMS only): suggesting where a person or vehicle likely went next by
matching appearance across cameras on the same site, presented as an investigative aid, never a
confirmed fact.

## Scenario: Investigator reviews a suggested cross-camera path

**Scenario ID:** SCN-221
**Feature ID:** FEAT-063

**Persona:** Wei, a security investigator reviewing an incident where a person was seen on the
front-gate camera and needs to figure out where they went next across a multi-camera site.

1. Wei opens the front-gate camera's event and selects "Find likely next appearance."
2. The VMS shows a ranked list of candidate appearances on other cameras around the same time
   window, each visibly labeled as a suggestion, with a similarity indicator — not presented as
   a confirmed match.
3. Wei reviews the top candidate's clip, confirms visually it's the same person, and adds it to
   the incident's timeline as a verified next sighting.
4. The VMS records that this specific link was investigator-confirmed, distinct from the
   system's original suggestion.

**What the user expects:** the system does the tedious cross-camera search for him, but the
call on whether it's really the same person is always his to make and is recorded as his
judgment, not the system's claim.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an investigator request candidate next-appearance matches for a
  selected person/vehicle event across other cameras on the same site, ranked by similarity
  and time proximity.
- **[vms]** The VMS shall visually and unambiguously label every candidate match as a
  suggestion, never as a confirmed identity match, and shall record separately when an
  investigator explicitly confirms a suggested link as part of an incident.

## Scenario: Low-confidence match is clearly flagged as uncertain

**Scenario ID:** SCN-222
**Feature ID:** FEAT-063

**Persona:** Wei, reviewing a case where the only candidate matches on a later camera are
poor-quality (partial view, bad lighting, different clothing layer).

1. Wei requests candidate matches and the VMS returns a short list, but every candidate's
   similarity score is low.
2. The VMS visibly marks the whole result set as low-confidence, rather than presenting the
   top-ranked candidate as if it were reliable just because it's the best available.
3. Wei treats the results as inconclusive and continues his investigation through other means
   (e.g. manually scrubbing nearby camera footage) rather than relying on the suggestion.

**What the user expects:** the system doesn't dress up a weak match to look authoritative just
because it's the best one it found — low confidence is visibly low confidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present a similarity/confidence score alongside every suggested
  cross-camera match, and shall visually distinguish a low-confidence result set from a
  high-confidence one rather than presenting all results with uniform visual authority.

## Scenario: No plausible match found on the site

**Scenario ID:** SCN-223
**Feature ID:** FEAT-063

**Persona:** Wei, investigating a person who was seen entering the site but apparently left
through a path with no camera coverage.

1. Wei requests candidate next-appearance matches for the front-gate event.
2. The VMS returns no candidates above a minimum plausibility floor and says so plainly ("No
   likely match found on other cameras"), rather than forcing a low-quality guess onto the list
   just to have something to show.
3. Wei understands the person likely left through an uncovered area and adjusts his
   investigation accordingly.

**What the user expects:** an honest "nothing found" is more useful than a manufactured
suggestion — the system doesn't pad results with implausible candidates just to appear useful.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall return an explicit "no likely match found" result when no candidate
  on any other camera meets a minimum plausibility floor, rather than always surfacing the
  best-available candidate regardless of how weak the match is.
