---
feature_id: FEAT-206
status: draft
target_fr_docs: [FR-vms.md, FR-nuraeye-service.md]
---

# Scenario: VMS — Approved-Third-Party Event Integration (MQTT/Webhook/API)

Covers FEAT-206: letting an approved external system (building management software, a security
integrator's platform) subscribe to VizenLink events, gated to explicitly approved integrations
rather than open to anyone.

## Scenario: An admin approves and configures a new integration

**Scenario ID:** SCN-652
**Feature ID:** FEAT-206

**Persona:** Raj's community is bringing on a third-party security-integrator platform that
needs to receive motion/intrusion events from the site's cameras.

1. Raj opens Integrations in VMS and adds a new integration, choosing the delivery method
   (webhook URL, MQTT topic credentials, or event-API key) the integrator's platform supports.
2. VMS requires Raj to explicitly select which event types (e.g. intrusion, tamper) and which
   cameras this integration may receive — it is not automatically granted the whole fleet's
   events.
3. VMS generates the credentials/webhook secret for this integration and shows them once for Raj
   to hand to the integrator, and the integration shows as "Pending" until the integrator
   confirms receipt of a test event.

**What the user expects:** turning on a third-party integration is a deliberate, scoped
authorization — not a global switch that suddenly exposes every camera's events to whichever
external system asks.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an admin configure a third-party integration scoped to specific
  event types and specific cameras, rather than granting fleet-wide event access by default.
- **[cloud-components]** The event-delivery channel (MQTT/webhook/API) shall only deliver events
  matching an integration's approved scope, and shall require the integration's issued
  credentials for delivery.
- **[vms]** A newly configured integration shall verify connectivity (e.g. a test-event
  handshake) before being marked active.

## Scenario: Revoking an integration's access

**Scenario ID:** SCN-653
**Feature ID:** FEAT-206

**Persona:** The community ends its contract with the security integrator and Raj needs to cut
off their event access immediately.

1. Raj opens the integration's settings and selects Revoke.
2. VMS immediately invalidates the integration's credentials/webhook secret; any further event
   deliveries or API calls using the old credentials are rejected.
3. VMS shows the integration as "Revoked" in its list rather than removing all trace of it, so
   Raj retains a record of what was once authorized.

**What the user expects:** ending a relationship with a third party immediately and reliably cuts
off their data access — no lingering window where old credentials keep working.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Revoking an integration shall immediately invalidate its credentials such that any
  subsequent event delivery or API call using them is rejected.
- **[cloud-components]** The event-delivery backend shall check credential validity per delivery/
  request, not only at initial connection, so a revoked integration is cut off promptly rather
  than at the next reconnect.

## Scenario: An integration's webhook endpoint starts failing

**Scenario ID:** SCN-654
**Feature ID:** FEAT-206

**Persona:** The integrator's webhook server has an outage and stops accepting event deliveries.

1. VMS surfaces a "Delivery failing" status for that integration rather than silently continuing
   to attempt (and silently drop) deliveries with no visibility.
2. Raj can see recent delivery failure counts/timestamps and choose to pause the integration or
   wait for it to recover, with retries continuing on a backoff schedule in the meantime.

**What the user expects:** a broken downstream integration is visibly flagged rather than
failing invisibly — he shouldn't find out three weeks later that no events ever arrived.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall surface a visible delivery-health status per integration and recent
  failure counts, rather than silently dropping failed deliveries with no operator-facing
  signal.
- **[cloud-components]** Event delivery to a webhook endpoint shall retry on a backoff schedule
  on failure, and failures shall be recorded for the VMS delivery-health view to surface.
