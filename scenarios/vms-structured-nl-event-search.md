---
feature_id: FEAT-129
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Structured & Natural-Language Event Search

Covers FEAT-129: searching events using structured phrases and, further out, open-ended
natural-language search over indexed metadata/approved visual embeddings.

## Scenario: Structured phrase search across a site's event history

**Scenario ID:** SCN-487
**Feature ID:** FEAT-129

**Persona:** Marcus wants to find every person detected at a specific gate after a certain time,
without manually building up a multi-field filter.

1. Marcus types a structured phrase into the search box: "people at Gate 2 after 10 PM."
2. The search parses this into the equivalent structured filters (object class = Person, zone =
   Gate 2, time range = after 22:00 across the queried date range) and returns matching events.
3. The results view shows Marcus the interpreted filters alongside the results, so he can see
   exactly how his phrase was understood and adjust if it's wrong.

**What the user expects:** he can search the way he'd describe what he's looking for in plain
language, without learning the filter panel's exact field names first.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall accept a structured natural-language search phrase and parse it into
  the equivalent structured event filters (object class, zone, camera, time range, etc.),
  returning matching events.
- **[vms]** The search results view shall display the filters the query was interpreted as, so
  the operator can verify or correct the interpretation.

## Scenario: A structured search phrase matches no events

**Scenario ID:** SCN-488
**Feature ID:** FEAT-129

**Persona:** Marcus searches for "vehicles at Gate 2 after 10 PM" on a day when no vehicle
event actually occurred there.

1. The results view shows a clear "no events match this search" state along with the
   interpreted filters, so Marcus can tell the search worked correctly and simply found nothing,
   rather than suspecting the query wasn't understood.
2. Marcus can adjust the interpreted filters directly (e.g. widen the time range) without
   retyping the whole phrase.

**What the user expects:** a genuine zero-result search is distinguishable from a
misunderstood or broken query.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The search results view shall distinguish a genuine zero-match result (query
  understood, nothing found) from a query the system failed to parse at all.
- **[vms]** The operator shall be able to adjust the interpreted structured filters directly
  from a zero-result search without re-entering the original phrase.

## Scenario: Open-ended natural-language search over visual content

**Scenario ID:** SCN-489
**Feature ID:** FEAT-129

**Persona:** Marcus wants to find an event described more visually than structurally, e.g. "a
person carrying a large box near the loading dock."

1. Marcus enters the open-ended description into the same search box.
2. The system searches indexed metadata and any approved visual embeddings for a best-effort
   match, clearly labeling these results as approximate/best-effort (e.g. ranked by relevance,
   not exact filter matches) so Marcus doesn't mistake them for guaranteed-precise structured
   results.
3. Marcus can review each candidate result's clip to confirm whether it's actually relevant.

**What the user expects:** he can search more loosely when he doesn't know the exact
structured terms, understanding the results are suggestions to review, not certainties.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support open-ended natural-language search over indexed event
  metadata and approved visual embeddings, returning ranked, best-effort candidate results.
- **[vms]** Open-ended search results shall be visually distinguished from structured-filter
  search results, making clear they are relevance-ranked approximations requiring human review,
  not exact matches.

## Scenario: An ambiguous query falls back to a clarification prompt

**Scenario ID:** SCN-490
**Feature ID:** FEAT-129

**Persona:** Marcus enters a phrase too ambiguous to parse confidently (e.g. a garbled or
contradictory description).

1. Rather than guessing and silently returning a poor-quality result set, the search prompts
   Marcus to clarify or offers the closest structured-filter interpretation it could infer for
   him to confirm or edit.
2. Marcus can always fall back to building the search manually with the structured filter panel
   if natural-language parsing isn't giving him what he wants.

**What the user expects:** the system is honest when it can't confidently understand a query,
rather than confidently returning something that doesn't actually match his intent.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The search feature shall detect low-confidence query parsing and prompt the
  operator for clarification or present its best-guess interpreted filters for confirmation,
  rather than silently executing a low-confidence interpretation.
- **[vms]** The structured filter panel (FEAT-119) shall remain available as a fallback at all
  times, independent of natural-language search.
