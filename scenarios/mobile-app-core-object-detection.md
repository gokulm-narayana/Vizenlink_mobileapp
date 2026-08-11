---
feature_id: FEAT-052
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Core Object Detection (Person/Vehicle/Animal/Package)

Covers the homeowner-facing side of FEAT-052: how correctly-classified local detections
(person, vehicle, animal, package/object) show up as alerts in the mobile app, including the
person-detection guarantee that doesn't require a visible face.

## Scenario: Person detected without a visible face

**Scenario ID:** SCN-209
**Feature ID:** FEAT-052

**Persona:** Marcus, a homeowner whose porch camera faces away from the street, catching people
mostly from behind or at an angle where their face isn't visible.

1. A delivery courier walks up the porch steps with their back to the camera the entire time.
2. Marcus's phone still receives a "Person detected" alert, tagged with the person class, even
   though no face was ever visible in the frame.
3. Opening the alert, Marcus sees the clip and can confirm it's a person (posture, motion,
   silhouette) even from the back.

**What the user expects:** the camera recognizes a person by their overall shape and movement,
not by needing to see a face — so it doesn't silently miss people who happen to be facing away,
wearing a hood, or otherwise not showing a clear face.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall classify a detected object as "person" using
  whole-body posture/motion cues, without requiring a visible or recognizable face as a
  precondition for the person class.
- **[mobile-app]** The app shall label an alert with its detected object class (person,
  vehicle, animal, package) as reported by the camera, and shall display that class
  consistently across the alert list and the alert detail view.

## Scenario: Vehicle correctly distinguished from an animal to avoid a nuisance alert

**Scenario ID:** SCN-210
**Feature ID:** FEAT-052

**Persona:** Marcus, whose driveway camera also has a stray cat that regularly walks through the
frame at night.

1. The cat crosses the driveway. The camera classifies it as "animal," not "vehicle" or
   "person."
2. Marcus, who has no active rule set to alert on animals in the driveway, gets no notification
   for the cat's pass-through.
3. Later that night, his car pulls into the driveway. The camera correctly classifies it as
   "vehicle," and — because he does have a vehicle-class rule on that zone — he gets the
   expected alert.

**What the user expects:** the four object classes are distinguished reliably enough that a
harmless nightly animal doesn't generate the same alert as an actual vehicle arrival, so his
rules can be scoped by class and trusted to behave accordingly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall distinguish between person, vehicle, animal, and
  package/object classes at the point of detection, so that class-scoped rules (see FEAT-066)
  can rely on the reported class rather than re-deriving it downstream.
- **[mobile-app]** The app shall only surface an alert for a detection when the class matches
  an active rule's configured class filter (or the rule has no class filter), so a
  correctly-classified but unwanted class doesn't reach the user as a notification.

## Scenario: Low-confidence detection near the edge of the frame

**Scenario ID:** SCN-211
**Feature ID:** FEAT-052

**Persona:** Marcus, whose side-yard camera catches a delivery box sitting at the very edge of
the frame, partly cut off.

1. A package is set down mostly out of frame, with only a corner of it visible.
2. The camera does not have enough of the object in view to classify it confidently, so it does
   not raise a package alert for that partial glimpse.
3. When the same package becomes more fully visible a few minutes later (e.g. the courier
   repositions it, or the angle changes), the camera then classifies and alerts on it normally.

**What the user expects:** the camera doesn't force a guess out of a partial, low-confidence
glimpse — it would rather wait for a confident view than fire off a wrong or premature alert.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall withhold classification (and therefore any
  class-scoped alert) for a detection whose confidence falls below the minimum threshold
  needed for a reliable class assignment, rather than reporting a low-confidence guess as if it
  were certain.
- **[mobile-app]** The app shall not display a class label for an event the camera reports as
  unclassified/low-confidence; such events, if surfaced at all, shall be shown generically
  (e.g. "Motion detected") rather than with a specific but unreliable class tag.
