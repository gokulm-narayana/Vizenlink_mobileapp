---
feature_id: FEAT-180
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Published Security-Update Support Period

Covers FEAT-180: a customer being able to see, from within the app, how long their specific
camera will keep receiving security updates, and what happens once that window ends.

## Scenario: Checking how long a camera will keep receiving security updates

**Scenario ID:** SCN-614
**Feature ID:** FEAT-180

**Persona:** Arjun is considering buying a second VizenLink camera and wants to know it won't be
abandoned in a couple of years.

1. In the app's Device Info screen for his existing camera, Arjun finds a "Security updates"
   line showing the support end date, computed from this camera's purchase/activation date plus
   the published minimum support period.
2. The same information (the general policy, not tied to a specific device) is also reachable
   from Settings → About → Security, for someone evaluating the product before buying.

**What the user expects:** a plain, findable answer to "how long will this thing actually be
supported," not a policy buried in a webpage he'd have to go searching for.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app's Device Info screen shall display each camera's computed
  security-update support end date (activation/purchase date plus the published minimum
  support period).
- **[mobile-app]** The app's Settings → About shall link to the published, general
  security-update support-period and end-of-life policy, independent of any specific owned
  device.

## Scenario: A camera reaches the end of its security-update window

**Scenario ID:** SCN-615
**Feature ID:** FEAT-180

**Persona:** Arjun, a few years later, owns a camera that has reached its published
security-update support end date.

1. The app's Device Info screen for that camera now shows its status as "Security updates
   ended" rather than silently continuing to look identical to a still-supported device.
2. The app links to the published end-of-life policy explaining what this means (e.g. no further
   security patches, recommended replacement guidance) rather than leaving Arjun to guess.
3. The camera continues to function for its existing features — reaching end-of-life does not
   itself disable the device.

**What the user expects:** he's told plainly when support has ended and what that means, instead
of finding out the hard way after an unpatched issue surfaces.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall visibly distinguish a camera past its security-update support
  end date from one still within its support window, rather than showing identical status for
  both.
- **[mobile-app]** The app shall link an out-of-support camera's status to the published
  end-of-life policy describing what continues to work and what does not.
