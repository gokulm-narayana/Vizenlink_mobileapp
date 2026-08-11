---
feature_id: FEAT-221
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Localization Architecture for Indian Languages (English First)

Covers FEAT-221's user-perceptible manifestation: the app ships in English at first, but its
underlying string architecture is built so a regional language can be added later without a UI
rework — the user-visible outcome being that, when a language ships, the whole app actually
speaks it, not just half of it.

## Scenario: Using the app in English at initial launch

**Scenario ID:** SCN-676
**Feature ID:** FEAT-221

**Persona:** Priya installs the app today, before any regional language is offered.

1. The app runs entirely in English — every screen, label, and notification.
2. Nothing about this scenario looks unusual; there's no visible sign of the underlying
   localization architecture at this stage.

**What the user expects:** a complete, natural English experience today, with no half-finished
placeholder strings anywhere.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** All user-visible strings (UI labels, notification text, error messages) shall
  be sourced from a centralized string-resource layer rather than hardcoded inline, so a future
  language can be added by supplying translated resources without code changes to the screens
  themselves.

## Scenario: A regional language is added later and the whole app switches

**Scenario ID:** SCN-677
**Feature ID:** FEAT-221

**Persona:** Some time later, VizenLink adds Hindi as a supported language; Priya's father, who
prefers Hindi, sets it as his app language.

1. He opens Settings → Language and selects Hindi.
2. Every screen, including ones added to the app after this Feature was first built, actually
   renders in Hindi — not just the screens that existed when localization architecture was
   first put in place, and not a mix of translated and still-English screens.
3. Notifications (e.g. "Person detected at Front Door") also arrive in Hindi, not just in-app
   text.

**What the user expects:** switching language is a complete, consistent experience across the
entire app, including push notifications — not a partial translation that leaves some screens
in English.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** A newly added supported language shall apply consistently across every screen
  in the app, including screens added after the localization architecture was first
  established, with no code change required per screen to pick up the new language.
- **[cloud-components]** Push-notification text shall be generated in the user's selected
  language, sourced from the same centralized string-resource layer used by the app itself.
