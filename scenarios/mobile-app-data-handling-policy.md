---
feature_id: FEAT-188
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Data Handling Policy per Deployment Type

Covers FEAT-188: the app surfacing a data-handling policy (purpose, retention, access, deletion)
that varies depending on whether the camera is set up as a home, community, or office
deployment.

## Scenario: Choosing a deployment type during setup shows the matching policy

**Scenario ID:** SCN-625
**Feature ID:** FEAT-188

**Persona:** Priya is setting up a new camera and is asked, as part of onboarding, what kind of
deployment this is.

1. During setup, the app asks Priya to choose a deployment type: Home, Community (e.g. a
   building lobby/common area), or Office.
2. Based on her choice (Home), the app shows a short summary of the applicable data-handling
   policy: what's recorded, how long it's retained by default, who can access it, and how to
   request deletion — specific to a home deployment, not a generic one-size-fits-all blurb.
3. Priya can tap through to the full policy text before completing setup, and must acknowledge
   she's seen the summary to proceed.

**What the user expects:** the policy she's shown actually matches how her camera is being used,
rather than a boilerplate notice that doesn't distinguish a private home camera from a shared
community one.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall ask for a deployment type (Home / Community / Office) during
  setup and present the data-handling policy summary matching that specific type.
- **[mobile-app]** The app shall require the user to acknowledge having seen the applicable
  policy summary before completing setup.

## Scenario: Reviewing the policy later from Settings

**Scenario ID:** SCN-626
**Feature ID:** FEAT-188

**Persona:** Priya, months later, wants to re-check what her camera's data policy actually says
about retention.

1. Priya opens Settings → Privacy → Data Handling Policy for her camera.
2. The screen shows the policy matching her camera's current deployment type, not the one she
   might have seen at initial setup if it has since changed (see next scenario).

**What the user expects:** the policy is always available to re-read, not just shown once during
onboarding and forgotten.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall make the current data-handling policy for a camera reachable
  from Settings at any time, not only during initial setup.

## Scenario: Changing a camera's deployment type updates the applicable policy

**Scenario ID:** SCN-627
**Feature ID:** FEAT-188

**Persona:** Priya relocates her camera from her home to a community clubhouse she helps manage,
and updates the deployment type accordingly.

1. Priya changes the deployment type from Home to Community in Settings.
2. The app shows the differences that matter (e.g. retention period, who can access footage) so
   she understands what's changing, before confirming.
3. Once confirmed, the camera's applicable policy and any policy-driven behavior (e.g. default
   retention) update to the Community type going forward.

**What the user expects:** switching deployment type is a deliberate, informed action, not a
silent toggle that changes her data's handling without her noticing the practical consequences.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show the practical differences (retention, access, purpose)
  between the current and newly-selected deployment type before applying a change, requiring
  explicit confirmation.
- **[camera-firmware]** The camera's default policy-driven behaviors (e.g. default retention
  period) shall update to match a newly-confirmed deployment type going forward.
