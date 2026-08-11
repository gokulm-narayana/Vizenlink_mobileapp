---
title: "ViZenLink Home / Apartment / Community Security Camera — Feature Seed"
version: "0.1"
status: "Research seed — not an approved product specification"
date: "2026-07-14"
owner: "Product"
intended_use: "Seed document for feature requirements, architecture discussion, prioritization, prototyping, and field validation"
---

# ViZenLink Home / Apartment / Community Security Camera  
## Product Feature Seed — Version 0.1

> **Status:** This is a research seed, not a committed roadmap or final engineering specification.  
> Every feature selected for development must be converted into a dedicated feature specification with measurable acceptance criteria.

---

## 1. Executive summary

ViZenLink should position this product family between two established categories:

1. **Consumer smart cameras**, which provide polished onboarding, mobile alerts, two-way talk, AI event summaries, and easy sharing, but often depend heavily on subscriptions and cloud storage.
2. **Professional CCTV/NVR systems**, which provide continuous recording, PoE reliability, multi-camera operation, local storage, configurable zones, interoperability, and installer controls, but often have weaker consumer usability and fragmented mobile workflows.

The proposed ViZenLink direction is:

> **A local-first, AI-assisted security camera platform with consumer-grade usability and professional-grade reliability for villas, apartment communities, and small offices.**

The product should remain useful when the internet is unavailable, detect relevant events at the edge, store evidence locally, provide secure on-demand remote viewing, support both household and organization roles, and integrate with an NVR/VMS through standards-based video and metadata interfaces.

### Recommended launch focus

The first release should prioritize dependable security rather than a large catalog of experimental AI features:

- person, vehicle, animal/pet, and package/object detection;
- configurable activity zones, line crossing, intrusion, and after-hours rules;
- camera tamper, blocked-view, moved-view, recording, storage, and network-health monitoring;
- local continuous/event recording and offline event buffering;
- fast event review, live view, playback, export, sharing, and alert controls;
- secure onboarding, device identity, signed software updates, role-based access, and audit;
- Wi-Fi standalone and PoE/NVR deployment paths;
- household sharing for homes and a separate organization role model for communities/offices.

Features such as face recognition, high-speed ANPR, “suspicious behavior,” automatic law-enforcement escalation, and automatic access denial should not be part of the initial scope. They require separate hardware, accuracy, legal, privacy, and human-review decisions.

---

## 2. Research basis

### 2.1 ViZenLink KB direction

The KB establishes four integrated components:

| Component | Primary responsibility |
|---|---|
| AI Camera | Real-time edge detection, local video capture, local event generation, basic health monitoring |
| NVR | Multi-camera coordination, continuous local storage, advanced search, local rules, remote-stream mediation |
| VMS | Event review, investigation, reporting, organization administration |
| Mobile App | Setup, live view, playback, alerts, sharing, recovery, daily operation |

The KB also establishes or proposes the following principles:

- real-time detection should run near the camera;
- heavier search, cross-camera analysis, and long-term analytics should run on the NVR/VMS/cloud;
- remote viewing should be on demand rather than continuously sending all video to the cloud;
- local recording and AI should continue during an internet outage;
- Wi-Fi recovery must not erase recordings, ownership, or configuration;
- household sharing and business/community authorization are different models;
- AI alerts are candidate events and must not be treated as final proof of crime or unauthorized activity;
- broad “Intelligence” documents must be decomposed into individually testable feature specifications.

### 2.2 External benchmark conclusion

Current products show several market directions:

- 2K and 4K capture are now common across consumer camera tiers.
- Local AI increasingly includes person, vehicle, pet, package, tracking, and activity-zone filtering.
- Local storage and “no mandatory subscription” are strong differentiators for Eufy, Tapo, and Reolink.
- Ring, Nest, and Arlo emphasize polished event UX, cloud history, AI descriptions/search, and ecosystem integration, but many advanced capabilities require subscriptions.
- Dual-lens coverage, pan/tilt tracking, floodlights, radar/PIR fusion, and natural-language event search are emerging premium differentiators.
- Professional interoperability increasingly depends on ONVIF Profile T for video, events, audio, and controls, and Profile M for analytics metadata and events.
- India cybersecurity testing and privacy obligations must be addressed as product-release requirements, not added after development.

### 2.3 Product opportunity

ViZenLink should not compete only on megapixels. Its defensible combination should be:

- **Local-first operation**
- **Low nuisance-alert rate**
- **Fast, explainable event review**
- **Professional multi-camera reliability**
- **Simple household and community access**
- **India-context AI and deployment presets**
- **Standards-based integration**
- **Transparent privacy and security lifecycle**

---

## 3. Scope

### 3.1 Target deployment domains

| Domain | Typical deployment | Main security need |
|---|---|---|
| Villa / independent home | 2–8 indoor/outdoor cameras; optional home NVR | perimeter, gate, driveway, entrance, delivery, family access |
| Apartment resident | 1–4 cameras where permitted | entrance, private parking, indoor safety, simple sharing |
| Apartment community | 16–300+ cameras with PoE/NVR/VMS | gates, perimeter, lobbies, lifts, parking, common areas, operator workflows |
| Small office | 4–32 cameras with local recorder | entrance, after-hours, restricted areas, visitor activity, evidence review |
| Community security room | Multi-monitor or VMS workstation | incident queue, multi-camera health, search, export, operator audit |

### 3.2 Primary personas

1. **Home Owner** — owns cameras, configures alerts, manages family access.
2. **Family Viewer** — views assigned cameras and receives selected alerts.
3. **Community/Site Administrator** — owns site policy, users, retention, cameras, and audit.
4. **Security Operator** — monitors events, verifies alerts, annotates and escalates incidents.
5. **Resident/Tenant Viewer** — sees only explicitly assigned cameras or approved shared views.
6. **Small Office Manager** — manages after-hours rules, staff access, event history, and export.
7. **Installer** — commissions devices, validates field of view, networking, recording, and night performance.
8. **Service/Support Technician** — sees health diagnostics without automatically gaining footage access.
9. **Auditor/Reviewer** — reads approved logs and exported evidence without changing configuration.

### 3.3 Non-goals for the first release

- autonomous police or emergency-service dispatch based only on AI;
- automatic gate opening or access denial based only on camera classification;
- high-speed road ANPR using a general-purpose rolling-shutter camera;
- biometric watchlists or cross-community face sharing;
- age, caste, ethnicity, gender, or other sensitive personal classification;
- an undefined “suspicious person” score;
- cloud-only operation with loss of recording during internet failure;
- one household sharing model reused unchanged for apartment staff or offices.

---

## 4. Product principles

### PRN-001 — Local-first security

The camera/NVR must continue recording and generating supported local AI events when cloud connectivity is lost.

### PRN-002 — Evidence before automation

AI produces a candidate event with supporting evidence. High-impact actions require human verification or a separately approved sensor-backed policy.

### PRN-003 — Reduce nuisance, not merely detect motion

The product must prefer relevant person/vehicle/animal/object events over generic pixel-motion notifications.

### PRN-004 — Consumer-simple, installer-capable

A homeowner should complete setup without networking expertise, while an installer must have access to advanced diagnostics, calibration, stream, storage, and rule controls.

### PRN-005 — Privacy is a system property

Role permissions, retention, masking, audio settings, access logs, export, deletion, and device decommissioning must be designed together.

### PRN-006 — Separate detection from policy

Example: the camera detects a vehicle; a site rule determines whether vehicle presence after hours is alert-worthy. Access authorization is a separate workflow.

### PRN-007 — Shared AI foundations

Person, vehicle, animal, and object detectors should be reusable foundations. Vertical features should combine them with zones, direction, schedules, duration, and site policy instead of duplicating models.

### PRN-008 — Honest capability boundaries

Marketing and UI must state the supported conditions for night, distance, angle, speed, occlusion, and camera placement.

### PRN-009 — Secure throughout product life

Unique identity, secure onboarding, signed updates, rollback controls, encrypted transport/storage, vulnerability response, and secure decommissioning are launch requirements.

### PRN-010 — Standards at system boundaries

Use standards such as ONVIF for compatible video, events, metadata, audio, discovery, and NVR/VMS integration where product security permits.

---

## 5. Competitive benchmark

> The table describes product/ecosystem direction as observed in July 2026. Exact features, plans, and availability can change.

| Ecosystem / archetype | Notable strengths | Common limitations | ViZenLink implication |
|---|---|---|---|
| Ring | Simple app, real-time alerts, two-way talk, polished cloud event history, AI video search in higher plans | Subscription dependence for recording and advanced AI; cloud-oriented economics | Match alert and playback simplicity, but make local recording and essential AI useful without a mandatory cloud plan |
| Google Nest | Strong timeline UX, event descriptions, conversational search, familiar-face ecosystem | Cloud-centric; limited local storage; advanced AI tied to service plans | Build a clean timeline and summaries, while preserving NVR/local ownership |
| Arlo | Good wireless/battery experience, activity zones, broad smart-home integration, strong image quality | Subscription-dependent advanced alerts/history; battery trade-offs | Offer a wireless home SKU later, but do not let battery constraints define community products |
| Eufy | 4K, local HomeBase storage, radar/PIR fusion, local recognition, no mandatory subscription | Closed ecosystem; performance varies by camera/hub combination | Local AI + expandable local storage is a key consumer expectation |
| Tapo | Aggressive value, local microSD, free basic AI, dual-lens/PTZ models, Ethernet/PoE options | Some cloud features remain optional add-ons; premium models may compromise frame rate | Price/performance matters, but ViZenLink should prioritize security motion quality and predictable NVR behavior |
| Reolink | Local storage, PoE/Wi-Fi range, no-subscription positioning, line/loitering analytics, AI search in newer systems | UX consistency and advanced cross-device workflows may vary | Strong benchmark for local-first hardware and installer-friendly product breadth |
| Qubo / India smart-security direction | India-market positioning, on-device AI direction, face/movement/behavior marketing | Public announcements require field verification; ecosystem maturity must be benchmarked | India-context data, local support, regulatory readiness, and clear capability validation can differentiate |
| Installer-grade ONVIF CCTV | PoE, continuous recording, NVR storage, configurable rules, multi-camera operation, open VMS integration | Setup complexity, inconsistent apps, fragmented metadata and user models | Combine professional reliability with a unified app, event model, health model, and role system |

### 5.1 Competitive requirements derived from the benchmark

1. Essential person/vehicle/pet/object alerts should not require a paid subscription.
2. Local recording must be a first-class path, not a degraded fallback.
3. Cloud should add remote convenience, summaries, backup, and multi-site operation—not be required for basic security.
4. Event review must be faster than manually scrubbing a continuous timeline.
5. Premium SKUs may use dual-lens, tracking, radar/PIR, spotlight, or color-night technology, but the platform must remain usable with fixed cameras.
6. ONVIF support should be verified through conformance testing, not described only as “compatible.”
7. The system must expose clear health states: locally online, cloud unreachable, not recording, view blocked, storage degraded, and fully offline.
8. ViZenLink needs a role model beyond “owner + family” for communities and small offices.

---

## 6. Product structure and proposed SKUs

This seed proposes capability classes rather than final commercial names.

### SKU-A — Indoor Wi-Fi Camera

- indoor home/small-office use;
- wide field of view;
- two-way audio;
- privacy mode or physical shutter where feasible;
- microSD recording;
- person/pet/package events;
- optional NVR pairing.

### SKU-B — Outdoor Wi-Fi / Ethernet Camera

- villa gate, driveway, entrance, small-office perimeter;
- weather-resistant enclosure;
- IR night vision and optional spotlight/color night;
- local storage;
- person/vehicle/animal detection;
- siren/two-way audio in selected models;
- Ethernet option preferred even when Wi-Fi is present.

### SKU-C — Community PoE Turret/Dome Camera

- apartment common areas, lobbies, parking, corridors;
- PoE;
- continuous NVR recording;
- vandal-resistant option;
- no mandatory speaker/microphone;
- edge metadata and tamper/health monitoring;
- ONVIF Profile T target and Profile M evaluation.

### SKU-D — Community PoE Bullet Camera

- perimeter, driveway, boundary, long corridor, parking approach;
- lens options matched to scene distance;
- strong IR/night image;
- line-crossing and intrusion rules;
- weather protection;
- NVR-first operation.

### SKU-E — Gate / Controlled-Lane Camera, later phase

- narrow scene and controlled vehicle speed;
- lens/illumination optimized for vehicle/plate capture;
- candidate plate OCR only after hardware and field validation;
- access-control integration remains separate;
- not marketed for road-speed ANPR without a dedicated global-shutter/ANPR design.

### SKU-F — Smart Tracking / Dual-Lens Premium Camera, later phase

- fixed overview plus pan/tilt or telephoto detail;
- coordinated target tracking;
- premium villa/community entrance use;
- must preserve an overview stream while tracking.

---

## 7. Priority model

| Priority | Meaning |
|---|---|
| P0 | Required for a dependable first commercial release |
| P1 | Strong differentiator after P0 stability |
| P2 | Advanced/later feature requiring additional compute, workflow, or validation |
| Gated | Requires separate legal, privacy, safety, hardware, or executive approval |

---

# 8. Feature requirements

## 8.1 Video and imaging

| ID | Priority | Requirement |
|---|---:|---|
| VID-001 | P0 | Provide a primary stream of at least 4 MP at 20 fps; target 25 fps where sensor/SoC bandwidth permits. |
| VID-002 | P1 | Premium camera target: 8 MP/4K at at least 15 fps, with 20 fps preferred for moving subjects. |
| VID-003 | P0 | Provide an independently configurable mobile substream, initially targeting 720p at 10–15 fps. |
| VID-004 | P0 | Support H.265 for storage efficiency and H.264 for broad compatibility and WebRTC paths. |
| VID-005 | P0 | Support at least two simultaneous encoded streams without stopping local recording. |
| VID-006 | P0 | Provide day/night switching, IR-cut control, and usable IR night video. |
| VID-007 | P0 | Provide WDR/backlight handling suitable for entrances and gates; final numeric WDR claim must be laboratory validated. |
| VID-008 | P0 | Expose configurable bitrate, frame rate, GOP, resolution, and quality profiles to installer/admin roles. |
| VID-009 | P0 | Maintain correct timestamps through NTP and local RTC fallback; mark uncertain time after prolonged clock failure. |
| VID-010 | P0 | Support privacy masks configured by an authorized administrator. |
| VID-011 | P1 | Support full-color low-light or spotlight-assisted color mode in selected outdoor SKUs. |
| VID-012 | P1 | Provide digital zoom for live and playback; clearly label it as digital. |
| VID-013 | P1 | Provide dewarping or corrected view only for lenses/SKUs where calibration is validated. |
| VID-014 | P2 | Coordinate fixed overview and PTZ/telephoto detail in dual-lens premium SKUs. |
| VID-015 | P0 | Continue primary recording while a remote user opens live view. |

### Imaging validation conditions

Every camera/lens combination must be tested for:

- daytime, night IR, color low light, backlight, headlight glare, rain, dust, insects, spider webs;
- walking and running subjects;
- partial occlusion;
- near/far zones;
- Indian two-wheelers, auto rickshaws, cars, vans, buses, trucks, delivery vehicles, animals, and common clothing conditions;
- exposure recovery when moving between bright and dark scenes.

---

## 8.2 Audio and deterrence

| ID | Priority | Requirement |
|---|---:|---|
| AUD-001 | P0 for selected SKUs | Provide microphone and speaker support for home/office SKUs; community SKUs may omit audio by policy or hardware variant. |
| AUD-002 | P0 | Make audio recording independently configurable from video recording. |
| AUD-003 | P0 | Show clear indication in app/VMS when audio recording is enabled. |
| AUD-004 | P0 | Support secure, permission-checked two-way talk. |
| AUD-005 | P1 | Support siren, spotlight, or prerecorded warning in deterrence-capable SKUs. |
| AUD-006 | P1 | Require a confirmation step or policy rule before activating a siren remotely. |
| AUD-007 | P2 | Detect selected acoustic events such as glass break, smoke-alarm tone, or sustained scream only after false-positive validation. |
| AUD-008 | Gated | Baby cry, private-conversation analysis, aggression analysis, or broad continuous audio classification requires separate product/privacy approval. |

---

## 8.3 Recording, storage, and evidence

| ID | Priority | Requirement |
|---|---:|---|
| REC-001 | P0 | Support continuous, scheduled, and event-based recording. |
| REC-002 | P0 | Support local camera storage where the SKU includes microSD. |
| REC-003 | P0 | Support NVR recording for all PoE/community SKUs and optional NVR recording for home SKUs. |
| REC-004 | P0 | Continue recording during WAN/cloud outage when power, local network, and storage are available. |
| REC-005 | P0 | Generate event clips with configurable pre-roll and post-roll; initial target is 5 seconds pre-roll and 10 seconds post-roll. |
| REC-006 | P0 | Provide retention policies by camera, stream, event severity, and storage destination. |
| REC-007 | P0 | Detect storage full, unavailable, read-only, write failure, file-system error, and recording-service failure. |
| REC-008 | P0 | Avoid silent recording loss; display a critical health condition when expected recording is not occurring. |
| REC-009 | P0 | Support indexed playback by time and by event. |
| REC-010 | P0 | Export a selected clip with camera, site, time, and integrity metadata. |
| REC-011 | P1 | Generate a cryptographic hash for exported evidence and include it in an export manifest. |
| REC-012 | P1 | Support event-lock/protection to prevent priority incidents from normal retention overwrite. |
| REC-013 | P1 | Support local encrypted storage where hardware performance permits; keys must not be stored in plain text beside the encrypted footage. |
| REC-014 | P1 | Allow cloud backup of selected events as an optional service, not as a requirement for basic recording. |
| REC-015 | P0 | Define behavior when camera SD and NVR contain overlapping copies; avoid duplicate event presentation. |

---

## 8.4 Edge AI foundation

### Initial object classes

P0 detector classes:

- person;
- vehicle;
- animal/pet;
- package/general delivery object.

Recommended India-context vehicle subclasses for P1 model refinement:

- car;
- van;
- bus;
- truck;
- motorcycle/scooter;
- bicycle;
- auto rickshaw/three-wheeler;
- tractor;
- cart.

Recommended animal subclasses for later refinement:

- dog;
- cat;
- cattle;
- goat/sheep;
- pig;
- horse/donkey;
- bird;
- monkey;
- snake.

| ID | Priority | Requirement |
|---|---:|---|
| AIF-001 | P0 | Run basic person, vehicle, animal, and package/object detection locally on supported cameras or local NVR. |
| AIF-002 | P0 | Do not require face visibility for person detection. |
| AIF-003 | P0 | Emit timestamp, camera ID, model version, class, confidence, bounding box, track ID where available, and zone intersections. |
| AIF-004 | P0 | Support per-camera confidence and persistence tuning with safe defaults. |
| AIF-005 | P0 | Avoid generating an alert from every detection; detections feed rule and policy evaluation. |
| AIF-006 | P0 | Preserve an event snapshot and clip reference for every alert-worthy event. |
| AIF-007 | P0 | Continue supported edge detection during loss of cloud connectivity. |
| AIF-008 | P0 | Version AI models independently but record compatible firmware/model combinations. |
| AIF-009 | P0 | Support staged model rollout and rollback after health/accuracy checks. |
| AIF-010 | P0 | Provide user feedback labels such as Confirmed, Not relevant, False alert, and Unsure. |
| AIF-011 | P1 | Use review feedback for analytics and controlled retraining, subject to explicit data policy. |
| AIF-012 | P1 | Support short-term object tracking to reduce duplicate alerts. |
| AIF-013 | P2 | Support cross-camera appearance correlation only on local NVR/VMS and present it as a candidate trail. |
| AIF-014 | Gated | Do not train or expose sensitive demographic classification without separate approval. |

---

## 8.5 Security event rules

| ID | Priority | Requirement |
|---|---:|---|
| RUL-001 | P0 | Let authorized users draw polygon activity/intrusion zones. |
| RUL-002 | P0 | Let authorized users draw directional line-crossing rules. |
| RUL-003 | P0 | Allow rule filtering by object class. |
| RUL-004 | P0 | Allow schedules, weekdays, holidays, and temporary exceptions. |
| RUL-005 | P0 | Support zone entry, exit, crossing, and presence. |
| RUL-006 | P0 | Support after-hours person and vehicle activity. |
| RUL-007 | P0 | Support event persistence to suppress single-frame false detections. |
| RUL-008 | P0 | Let an installer run a rule in test mode before notifications are enabled. |
| RUL-009 | P0 | Require recalibration or confirmation after a significant view change. |
| RUL-010 | P1 | Support dwell/loitering threshold in configured zones. |
| RUL-011 | P1 | Support stopped-vehicle/parking-duration rules in configured areas. |
| RUL-012 | P1 | Support people and vehicle counting across a calibrated line. |
| RUL-013 | P1 | Support crowd/occupancy threshold events for lobbies and community areas. |
| RUL-014 | P1 | Support package-arrived and package-removed candidates for suitable entrance views. |
| RUL-015 | P1 | Support gate/door-left-open events when a visual state is reliable or a physical sensor is integrated. |
| RUL-016 | P2 | Support wrong-way vehicle movement on configured internal roads/ramps. |
| RUL-017 | P2 | Support climbing-like behavior only in a configured boundary zone after pose/trajectory validation. |
| RUL-018 | Gated | Do not label a person “suspicious” from appearance alone. |
| RUL-019 | Gated | Do not automatically call police, confront a subject, deny access, or generate an accusation based only on a video model. |

---

## 8.6 Camera tamper and health intelligence

| ID | Priority | Requirement |
|---|---:|---|
| HLT-001 | P0 | Distinguish local online, cloud unreachable, NVR unreachable, and fully offline states. |
| HLT-002 | P0 | Detect camera offline and record offline/recovery times. |
| HLT-003 | P0 | Detect recording failure independently from connectivity status. |
| HLT-004 | P0 | Detect storage degradation/full/write failure. |
| HLT-005 | P0 | Detect sudden blocked/covered view. |
| HLT-006 | P0 | Detect significant view movement or redirection using a saved installation reference. |
| HLT-007 | P0 | Detect sustained unusable image conditions such as severe underexposure, overexposure, or loss of focus. |
| HLT-008 | P0 | Monitor day/night transition and flag persistent unusable night vision. |
| HLT-009 | P0 | Monitor uptime, repeated reboot, firmware version, model version, and last successful recording. |
| HLT-010 | P0 | Show “online but unusable” prominently rather than reporting only “online.” |
| HLT-011 | P1 | Detect gradual dirty-lens/haze/fogging degradation. |
| HLT-012 | P1 | Use accelerometer/tamper sensor in SKUs where BOM permits and correlate with image view change. |
| HLT-013 | P1 | Monitor temperature and hardware telemetry with warning/critical thresholds. |
| HLT-014 | P1 | Provide per-site fleet health summary and maintenance history. |
| HLT-015 | P1 | Provide recommended corrective action without hiding raw diagnostics. |
| HLT-016 | P2 | Predict likely storage, thermal, or image-quality failure from trends. |

### Health-state examples

- Healthy
- Degraded image
- View blocked
- Camera moved
- Local online / cloud offline
- Not recording
- Storage degraded
- Updating
- Reboot loop
- Fully offline
- Maintenance mode

---

## 8.7 Offline operation and synchronization

| ID | Priority | Requirement |
|---|---:|---|
| OFF-001 | P0 | Continue local video recording and supported AI detection when WAN/cloud is unavailable. |
| OFF-002 | P0 | Assign a stable unique ID to each event before cloud synchronization. |
| OFF-003 | P0 | Buffer event metadata locally; buffer snapshots/clips according to storage policy. |
| OFF-004 | P0 | Display local-only, sync-pending, uploading, verified, failed, and discarded states. |
| OFF-005 | P0 | Resume interrupted synchronization without duplicating events. |
| OFF-006 | P0 | Verify clip integrity after upload. |
| OFF-007 | P0 | Define queue-full behavior; do not claim unlimited or zero-loss retention. |
| OFF-008 | P0 | Protect higher-severity evidence before lower-priority routine events when storage pressure occurs. |
| OFF-009 | P0 | Record any dropped, downgraded, or overwritten event. |
| OFF-010 | P0 | Throttle backlog upload so it does not starve live view or current recording. |
| OFF-011 | P1 | Initial engineering target: retain at least 24 hours of event metadata during WAN outage under the defined event-rate test profile. |
| OFF-012 | P1 | Expose oldest unsynced event age, queue size, and storage pressure to admin/support roles. |
| OFF-013 | P0 | A paired system may work offline; offline operation must not bypass ownership or onboarding validation. |

---

## 8.8 Mobile app and VMS event workflow

| ID | Priority | Requirement |
|---|---:|---|
| APP-001 | P0 | Show sites/cameras in a list or grid with online, recording, health, and unread-event status. |
| APP-002 | P0 | Open live view from a notification, camera card, or event detail. |
| APP-003 | P0 | Show event type, camera, zone, local time, snapshot, clip, confidence presentation, and rule context. |
| APP-004 | P0 | Support Confirm, Dismiss, False alert, Save, Share/Export, and Escalate actions according to role. |
| APP-005 | P0 | Provide a unified timeline with continuous-recording and AI-event navigation. |
| APP-006 | P0 | Filter events by site, camera, type, object class, zone, severity, review status, and date/time. |
| APP-007 | P0 | Configure notifications by camera, rule, event type, schedule, severity, and user. |
| APP-008 | P0 | Group repetitive events to avoid notification storms while retaining the underlying evidence. |
| APP-009 | P0 | Clearly distinguish live, delayed, last-known, local-only, and unavailable data. |
| APP-010 | P0 | Show recording/storage failure more prominently than ordinary activity alerts. |
| APP-011 | P0 | Support two-way talk where the device and role permit it. |
| APP-012 | P0 | Support owner/admin-controlled sharing and revocation. |
| APP-013 | P0 | Provide Network Recovery without erasing recordings or ownership. |
| APP-014 | P0 | Provide secure ownership transfer/decommission flow separate from Network Recovery. |
| APP-015 | P1 | Support event annotations, incident status, assignee, and operator notes for community/office deployments. |
| APP-016 | P1 | Support event bookmarks and multi-clip incident collections. |
| APP-017 | P1 | Provide a daily security digest summarizing verified/relevant activity and health issues. |
| APP-018 | P1 | Allow users to search using structured phrases such as “people at Gate 2 after 10 PM.” |
| APP-019 | P2 | Provide grounded natural-language search over indexed metadata and approved visual embeddings. |
| APP-020 | P2 | Provide an e-map/site-map view for community deployments. |
| APP-021 | P2 | Support candidate cross-camera trail assembly for an investigator. |
| APP-022 | P0 | Mobile UI must not imply that an unverified AI event is a confirmed crime or identity. |

---

## 8.9 Remote live viewing

| ID | Priority | Requirement |
|---|---:|---|
| LIV-001 | P0 | Use on-demand remote live sessions rather than continuously sending every stream to the cloud. |
| LIV-002 | P0 | Authenticate the user and authorize site/camera/live-view permission before session creation. |
| LIV-003 | P0 | Prefer NVR-mediated remote viewing for NVR deployments. |
| LIV-004 | P0 | Stop the cloud media session on explicit close, timeout, authorization loss, or abandoned-session detection. |
| LIV-005 | P0 | Continue local recording during remote live view. |
| LIV-006 | P0 | Provide adaptive mobile stream bitrate/resolution without changing the primary recording stream. |
| LIV-007 | P0 | Audit user/device, camera, session start/stop, duration, and failure reason. |
| LIV-008 | P0 | Support STUN/TURN behavior for NAT/CGNAT conditions and measure relay percentage/cost. |
| LIV-009 | P1 | Initial target under qualified network conditions: first remote frame within 3 seconds at p95. |
| LIV-010 | P1 | Support multiple authorized viewers subject to explicit per-camera/NVR/site limits. |
| LIV-011 | P1 | Define safe fallback for NVR offline but standalone-capable camera online. |
| LIV-012 | P2 | Support direct camera-to-cloud live view for standalone SKUs after separate firmware/security validation. |

---

## 8.10 Household and organization access

### Home roles

| Role | Suggested rights |
|---|---|
| Owner | Full camera/site control, sharing, settings, retention, export, decommission |
| Family Viewer | Assigned live view, selected playback, selected alerts, optional two-way talk |
| Temporary Guest | Time-limited access to selected camera/live view only |

### Community / office roles

| Role | Suggested rights |
|---|---|
| Site Owner / Community Admin | All site policy, user, retention, camera, export, audit |
| Security Supervisor | Operator management, incident review, escalation, selected configuration |
| Security Operator | Live, playback, event review, annotate/escalate; no ownership/security changes |
| Resident / Tenant Viewer | Explicitly assigned private/shared views only |
| Office Manager | Site events, users, schedules, playback/export within assigned office |
| Installer | Commissioning and diagnostics; footage access only when expressly granted |
| Support Technician | Device health/log access; no footage by default |
| Auditor | Read-only audit/export verification |

| ID | Priority | Requirement |
|---|---:|---|
| IAM-001 | P0 | Maintain a distinct organization role model; do not reuse the four-family-phone design for communities/offices. |
| IAM-002 | P0 | Enforce permissions separately for live, playback, audio, export, settings, rules, users, and audit. |
| IAM-003 | P0 | Support per-site and per-camera scope. |
| IAM-004 | P0 | Revoke access promptly at backend/NVR authorization points. |
| IAM-005 | P0 | Log grants, changes, revocations, exports, deletion, and high-impact configuration actions. |
| IAM-006 | P0 | Require stronger authentication for administrators and remote access. |
| IAM-007 | P0 | Prevent installer/support roles from automatically viewing footage. |
| IAM-008 | P1 | Support time-bounded permissions for contractors, temporary guards, guests, or support sessions. |
| IAM-009 | P1 | Support approval workflow for sensitive export or broad camera access. |
| IAM-010 | P1 | Show last access and active sessions to owner/admin. |

---

## 8.11 Onboarding, recovery, and installation

| ID | Priority | Requirement |
|---|---:|---|
| ONB-001 | P0 | Every device must have a unique factory identity and bootstrap secret/certificate. |
| ONB-002 | P0 | No universal default administrator password is permitted. |
| ONB-003 | P0 | Pairing must require physical possession or an equivalent trusted installer workflow. |
| ONB-004 | P0 | Support QR-assisted onboarding and secure credential exchange. |
| ONB-005 | P0 | Support Wi-Fi Network Recovery without erasing recordings, ownership, rules, or calibration. |
| ONB-006 | P0 | Reserve “Factory Reset” for a destructive ownership/decommission/service operation. |
| ONB-007 | P0 | Preserve local recording during recoverable WAN/Wi-Fi failure. |
| ONB-008 | P0 | Support NVR plug-and-play discovery/pairing for native cameras. |
| ONB-009 | P0 | Discover third-party ONVIF cameras but require explicit credentials/authorization. |
| ONB-010 | P0 | Provide installation checks for image, focus, angle, night view, time, recording, storage, network, firmware, and AI zones. |
| ONB-011 | P0 | Save an installation reference view for moved-camera detection. |
| ONB-012 | P0 | Provide installer test events and notification suppression during commissioning. |
| ONB-013 | P1 | Support bulk onboarding and naming for community deployments. |
| ONB-014 | P1 | Support NVR-mediated network recovery for wired/multi-camera sites. |
| ONB-015 | P1 | Provide site templates for villa, gate, parking, lobby, corridor, and small-office installation. |

---

## 8.12 Cybersecurity and software lifecycle

| ID | Priority | Requirement |
|---|---:|---|
| SEC-001 | P0 | Assign a unique cryptographic identity to every device. |
| SEC-002 | P0 | Validate firmware authenticity at boot using secure boot. |
| SEC-003 | P0 | Sign firmware and AI model update packages. |
| SEC-004 | P0 | Implement rollback protection or an explicitly approved compensating control. |
| SEC-005 | P0 | Encrypt remote control, video, metadata, and update traffic in transit. |
| SEC-006 | P0 | Store private keys and long-term device secrets in protected hardware/OTP/secure storage. |
| SEC-007 | P0 | Disable unnecessary services, ports, debug interfaces, and default credentials in production. |
| SEC-008 | P0 | Apply least privilege between camera services, NVR services, cloud, app, and support tooling. |
| SEC-009 | P0 | Verify update integrity and recover safely from interrupted update. |
| SEC-010 | P0 | Support staged OTA rollout, health check, rollback policy, and version inventory. |
| SEC-011 | P0 | Publish a vulnerability disclosure and security-contact process. |
| SEC-012 | P0 | Maintain an SBOM and third-party component/version inventory. |
| SEC-013 | P0 | Define a security-update support period; proposed target is at least five years from last sale. |
| SEC-014 | P0 | Rate-limit authentication and pairing attempts and log suspicious failures. |
| SEC-015 | P0 | Protect local credentials/tokens using OS secure storage on mobile and protected storage on NVR. |
| SEC-016 | P0 | Support secure ownership transfer and verifiable deletion/decommissioning. |
| SEC-017 | P0 | Treat physical tamper, debug access, boot path, and removable storage as part of the threat model. |
| SEC-018 | P0 | Complete India CCTV cybersecurity/certification due diligence for every model and material firmware variant before sale. |
| SEC-019 | P1 | Conduct independent penetration testing before production launch and after major architecture changes. |
| SEC-020 | P1 | Provide signed diagnostic bundles with privacy filtering for support. |

---

## 8.13 Privacy and governance

| ID | Priority | Requirement |
|---|---:|---|
| PRI-001 | P0 | Define purpose, lawful/authorized use, retention, access, and deletion policy per deployment type. |
| PRI-002 | P0 | Minimize collection and cloud transfer; retain only required metadata and evidence. |
| PRI-003 | P0 | Provide configurable retention and verified deletion. |
| PRI-004 | P0 | Make audio separately controllable and disabled by default in deployments where policy requires it. |
| PRI-005 | P0 | Apply role checks to live, playback, search, export, face/plate data, and incident notes. |
| PRI-006 | P0 | Maintain audit logs for sensitive access and export. |
| PRI-007 | P0 | Provide static privacy zones and prevent unauthorized users from removing them. |
| PRI-008 | P1 | Support role-dependent face masking for selected shared/public views. |
| PRI-009 | P1 | Support shorter retention and stronger permissions for plate, face, and movement-history metadata. |
| PRI-010 | P1 | Provide export watermarking and a visible indication when footage is redacted. |
| PRI-011 | Gated | Face recognition, familiar-person galleries, and watchlists require separate legal/privacy/security approval. |
| PRI-012 | Gated | Cross-site identity sharing is prohibited unless explicitly approved under a dedicated governance design. |
| PRI-013 | Gated | Do not use an LLM response as the sole basis for safety, access, accusation, or emergency action. |

---

## 8.14 Interoperability and integrations

| ID | Priority | Requirement |
|---|---:|---|
| INT-001 | P0 | Target ONVIF Profile T capabilities for applicable camera/NVR SKUs: video, imaging controls, motion/tamper events, metadata, audio, and PTZ where supported. |
| INT-002 | P1 | Evaluate ONVIF Profile M for interoperable analytics metadata/events. |
| INT-003 | P0 | Support authenticated RTSP/RTSPS or the selected secured equivalent for local integrations. |
| INT-004 | P0 | Do not expose unauthenticated video streams or universal credentials. |
| INT-005 | P0 | Define a versioned ViZenLink event metadata schema. |
| INT-006 | P1 | Support MQTT/webhook/event API integration for approved site systems. |
| INT-007 | P1 | Support digital input/output or relay events where hardware supports them. |
| INT-008 | P1 | Integrate door, gate, alarm, and access-control events through a local adapter rather than inferring every physical state from video. |
| INT-009 | P1 | Provide export/API rate limits, scopes, and audit. |
| INT-010 | P2 | Integrate selected smart-home ecosystems only after security and maintenance-cost review. |

---

# 9. Event and metadata model

A single event model should serve camera, NVR, VMS, cloud, and app.

## 9.1 Required fields

```text
event_id
site_id
camera_id
source_device_id
event_type
object_class
object_subclass
event_start_utc
event_end_utc
display_timezone
confidence
rule_id
rule_version
zone_id / line_id
direction
dwell_duration
bounding_boxes / track_reference
snapshot_reference
clip_reference
recording_location
local_cloud_state
severity
review_status
reviewer_id
review_action
review_note
model_name
model_version
firmware_version
created_at
synced_at
integrity_status
retention_class
privacy_classification
```

## 9.2 Review status

- New
- Viewed
- Confirmed relevant
- Confirmed incident
- Not relevant
- False alert
- Escalated
- Closed
- Evidence locked

## 9.3 Severity

| Severity | Meaning | Example |
|---|---|---|
| Info | Useful record, no immediate action | normal vehicle entry |
| Warning | Review when available | loitering/dwell, dirty lens |
| High | Prompt human review | after-hours person, line crossing |
| Critical | Immediate attention to system or safety | camera blocked during intrusion rule, recording failure on critical camera |

Severity must be determined by rule and site context—not solely by object class.

---

# 10. Deployment presets

## 10.1 Villa perimeter preset

- person and vehicle detection;
- exterior zones only;
- outside-to-inside line crossing;
- after-hours schedule;
- animal suppression or separate pet alert;
- immediate tamper and recording-failure alerts;
- owner and family sharing;
- local SD plus optional NVR.

## 10.2 Villa entrance and delivery preset

- person and package candidate;
- entry-zone event;
- two-way talk;
- package-arrived and package-removed candidate;
- activity schedule;
- fast live view from notification.

## 10.3 Apartment gate preset

- vehicle/person detection;
- entry/exit direction;
- queue/dwell candidate;
- operator event review;
- continuous NVR recording;
- gate-sensor/access-system correlation;
- slow/stopped vehicle plate capture only in an approved gate SKU.

## 10.4 Parking/basement preset

- person and vehicle;
- directional line crossing;
- wrong-way candidate;
- no-parking/dwell zones;
- camera-block/view-change alerts;
- night/low-light validation.

## 10.5 Lobby/common-area preset

- person presence;
- crowd threshold;
- after-hours activity;
- privacy masking for shared display;
- no face recognition by default;
- operator workflow and retention policy.

## 10.6 Small office after-hours preset

- entrance and restricted-zone person detection;
- schedule and holiday exceptions;
- door sensor correlation;
- owner/manager alert;
- evidence clip and incident annotation;
- recording and storage health.

## 10.7 Installer commissioning preset

- no user notification during test;
- walk-test for zones/lines;
- day/night image checklist;
- reference-view capture;
- NVR recording verification;
- network fail/recovery test;
- health and firmware report.

---

# 11. Architecture allocation

| Function | Camera | NVR | VMS / Local server | Cloud / Backend | Mobile app |
|---|---:|---:|---:|---:|---:|
| Video capture/encode | Primary | — | — | — | Display |
| Basic person/vehicle/animal/object detection | Primary | Optional fallback/heavier model | Optional | Not required | Configure/view |
| Line/zone event rule | Camera or NVR | Primary for multi-camera policy | Optional | Policy sync | Configure |
| Local continuous recording | SD option | Primary | Optional | No | Playback |
| Event buffer during WAN loss | Yes | Yes/authority | Optional | Receive/index | Show status |
| Multi-camera search | Metadata only | Primary | Primary | Optional advanced | Query/result |
| Remote live session | Stream source | Preferred mediator | Optional | Auth/signaling/relay | Viewer |
| Account and authorization | Device enforcement | Local enforcement | Organization policy | Primary authority | User interface |
| Push notifications | Event source | Aggregate | Optional | Primary | Receive |
| Fleet health | Telemetry | Aggregate | Dashboard | Multi-site aggregate | Summary |
| Daily summaries | Event metadata | Local summary | Primary | Optional AI | Display |
| Cross-camera correlation | No | Primary | Primary | Optional | Review |
| Face/plate sensitive workflows | Gated capture | Gated local processing | Gated | Gated | Restricted |

### 11.1 Edge-first rule

A feature should run locally when any of the following is true:

- reaction must be immediate;
- it must work without internet;
- sending raw video continuously would be costly or privacy-invasive;
- the camera/NVR has sufficient compute;
- only compact metadata needs to leave the site.

### 11.2 Cloud-use rule

Use cloud compute when it adds clear value:

- account authorization and revocation;
- remote signaling and optional relay;
- push notifications;
- optional cloud backup;
- multi-site dashboards;
- opt-in natural-language summaries/search;
- fleet update orchestration;
- support and health analytics with privacy controls.

---

# 12. Non-functional requirements and initial targets

These are engineering targets for validation, not marketing claims.

| ID | Area | Initial target |
|---|---|---|
| NFR-001 | Edge event latency | Qualifying event created within 2 seconds at p95 under validated scene conditions |
| NFR-002 | Online notification latency | Push notification delivered within 5 seconds at p95, excluding external mobile push-provider delay where separately measured |
| NFR-003 | Local live start | First frame within 2 seconds at p95 on a healthy LAN |
| NFR-004 | Remote live start | First frame within 3 seconds at p95 under qualified WAN/mobile conditions |
| NFR-005 | Recording continuity | Opening live view or running AI must not stop the primary recording stream |
| NFR-006 | WAN outage | Continue local recording and P0 AI throughout outage while storage is available |
| NFR-007 | Event synchronization | No duplicate cloud event after interrupted/retried synchronization |
| NFR-008 | Time | Camera/NVR timestamps remain aligned within the defined tolerance; all audit times stored in UTC |
| NFR-009 | Recovery | Automatically resume normal recording and detection after recoverable reboot/network restoration |
| NFR-010 | Alert quality | Measure precision, recall, missed event rate, and nuisance alerts per camera-day by preset; numeric release gates set after pilot baseline |
| NFR-011 | Resource budget | Every model publishes CPU/NPU, RAM, flash, bandwidth, thermal, and power cost |
| NFR-012 | Accessibility | Do not rely only on color for health/severity; support readable labels and accessible controls |
| NFR-013 | Localization | English first; architecture and string system must support Indian languages |
| NFR-014 | Audit | High-impact actions are attributable to a user/device and protected against ordinary editing |
| NFR-015 | Update safety | Interrupted update must not leave the camera unable to boot into a known-good image |

### 12.1 Do not define one universal AI accuracy number

Accuracy depends on:

- mounting height and angle;
- pixels on target;
- day/night mode;
- motion speed and blur;
- weather and illumination;
- class balance and regional data;
- occlusion;
- zone geometry;
- sensitivity and persistence settings.

Each feature specification must define its own test distribution and release thresholds.

---

# 13. Validation plan

## 13.1 Laboratory tests

- resolution, frame rate, bitrate, encoder stability, stream concurrency;
- WDR/backlight and exposure transition;
- IR-cut switching, IR range, spotlight behavior;
- thermal and sustained AI load;
- SD/NVR write interruption and corruption recovery;
- power cycle and brownout;
- firmware/model update interruption;
- secure boot and unsigned-image rejection;
- network loss, DNS failure, cloud failure, router replacement, CGNAT;
- microphone/speaker echo and latency;
- enclosure water/dust/vandal tests appropriate to SKU.

## 13.2 AI scene tests

- people at near, medium, and far ranges;
- partial person, umbrella, raincoat, helmet, mask;
- child-sized and crouched person without age classification;
- dogs, cats, cattle, monkeys, birds, insects near lens;
- cars, two-wheelers, auto rickshaws, buses, trucks, tractors;
- day, IR night, color night, glare, rain, shadows, trees, headlights;
- entry/exit, crossing, dwell, reversing, tailgating;
- delivery person and package placement/removal;
- camera covered slowly and suddenly;
- camera redirected, shaken, unfocused, dirty, fogged.

## 13.3 Field pilots

At minimum:

1. independent villa;
2. villa community gate/perimeter;
3. apartment lobby;
4. apartment basement/parking;
5. small office entrance/interior;
6. security-room multi-camera operation.

For each pilot collect:

- events by type;
- confirmed relevant events;
- missed events;
- false alerts;
- nuisance notifications per camera-day;
- notification and live-start latency;
- recording gaps;
- storage consumption;
- WAN outage behavior;
- operator review time;
- support/install issues;
- privacy/user complaints;
- camera-health findings.

---

# 14. Feature-specification template

Before development commitment, create one document per feature containing:

1. **Feature name and ID**
2. **Problem and customer value**
3. **Target deployment/persona**
4. **In-scope and out-of-scope behavior**
5. **Definitions and terminology**
6. **Inputs**
   - video stream;
   - sensor input;
   - zone/line;
   - schedule;
   - object classes;
   - access-system event.
7. **Detection/rule logic**
8. **Outputs and event schema**
9. **Configuration**
10. **Runtime allocation**
    - camera;
    - NVR;
    - VMS;
    - cloud.
11. **Offline behavior**
12. **Failure and degraded modes**
13. **Privacy/security controls**
14. **Permissions and audit**
15. **UX flows**
16. **Telemetry**
17. **Performance/resource budget**
18. **Accuracy metrics**
19. **Test dataset and field scenarios**
20. **Acceptance criteria**
21. **Known limitations**
22. **Rollout/rollback plan**
23. **Dependencies**
24. **Open decisions**

---

# 15. Recommended roadmap

## Phase 0 — Platform foundation

- device identity and secure onboarding;
- secure boot/signed OTA;
- video pipeline and two streams;
- local SD and NVR recording;
- camera/NVR event schema;
- app camera grid/live/playback;
- health telemetry;
- network recovery;
- role/authorization foundations;
- ONVIF interoperability prototype;
- installation/calibration workflow.

## Phase 1 — Dependable security MVP

- person, vehicle, animal, package/object detection;
- zone, line crossing, direction, after-hours;
- camera blocked/moved, recording/storage/network health;
- event clip and push notification;
- event timeline and filters;
- owner/family sharing;
- organization roles for small office/community;
- offline event buffering and synchronization;
- on-demand remote live view;
- evidence export and audit;
- villa, gate, parking, lobby, and office presets.

## Phase 2 — Product differentiation

- loitering/dwell;
- people/vehicle counting;
- parking/no-parking rules;
- door/gate sensor correlation;
- active deterrence;
- privacy masking by role;
- daily security summaries;
- structured/natural-language event search;
- fleet health dashboard;
- bulk community commissioning;
- optional cloud event backup;
- dual-lens/tracking premium SKU.

## Phase 3 — Advanced and gated

- cross-camera candidate trails;
- lost object/pet investigation;
- slow/stopped gate ANPR with dedicated camera;
- audio event detection;
- fall detection;
- e-map;
- predictive maintenance;
- familiar-face/face recognition only after formal approval;
- advanced generative AI only with grounded evidence and human control.

---

# 16. Open product decisions

1. Is the first commercial package a standalone Wi-Fi camera, an NVR kit, or both?
2. What is the baseline imaging target: 4 MP/25 fps, 4K/15–20 fps, or separate tiers?
3. Which target SoC/NPU can run the P0 detector set concurrently with encoding and health analytics?
4. Which models have Wi-Fi, PoE, Ethernet, microSD, speaker, spotlight, and tamper sensors?
5. What is the final household sharing limit and guest-access design?
6. What exact organization roles and approval workflows are required for apartment communities?
7. Is the NVR always the authority for recording, event synchronization, and remote streaming in multi-camera sites?
8. What local retention packages and HDD sizes are offered?
9. Which essential features are subscription-free?
10. Which optional cloud services are commercially viable?
11. What are the approved India certification and component-sourcing paths for each SKU?
12. What firmware changes trigger certification or regression retesting?
13. Is audio enabled in community deployments, and under what notice/consent policy?
14. Is face recognition excluded from the product line or reserved as a separately governed option?
15. Is slow/stopped gate ANPR viable with a dedicated lens/illumination SKU?
16. Which ONVIF profiles are release requirements and which are later targets?
17. What is the security-update support period and end-of-life policy?
18. How are installer/support diagnostics separated from access to customer footage?
19. What false-alert and miss-rate thresholds are acceptable for each preset?
20. Which field pilot sites represent the first release market?

---

# 17. Recommended immediate next actions

1. Select the first two commercial deployment packages:
   - villa/home;
   - apartment community or small office.
2. Freeze the P0 feature list.
3. Create individual specifications for:
   - person event;
   - vehicle event;
   - activity zone/line crossing;
   - after-hours rule;
   - camera-block/view-change health;
   - local recording and outage sync;
   - event review;
   - household sharing;
   - organization RBAC;
   - secure onboarding/network recovery.
4. Build a common event schema and state model before implementing multiple app screens.
5. Select camera hardware targets and run a concurrent workload test:
   - encoding;
   - recording;
   - P0 detection;
   - event clip;
   - remote substream;
   - health checks.
6. Establish India-context evaluation datasets and field pilot metrics.
7. Define the India certification plan, secure-update process, SBOM workflow, and security support lifecycle.
8. Prototype ONVIF Profile T integration and Profile M metadata mapping.
9. Run villa, gate, parking, and small-office field pilots before adding higher-risk AI features.
10. Convert validated outcomes into formal product decisions and feature requirements.

---

# 18. Sources

## 18.1 ViZenLink KB

- `wiki/system-architecture.md`
- `wiki/scenario-domain-application-taxonomy.md`
- `wiki/family-sharing.md`
- `wiki/network-recovery.md`
- `wiki/nvr-plug-and-play.md`
- `decisions/2026-07-08_remote-viewing-backend-architecture.md`
- `decisions/2026-07-09_ai-cctv-platform-architecture.md`
- `scenarios/2026-07-09_ai-cctv-mobile-app.md`
- `scenarios/2026-07-09_human-detection.md`
- `scenarios/2026-07-09_intrusion-perimeter-security.md`
- `scenarios/2026-07-09_vehicle-intelligence.md`
- `scenarios/2026-07-09_camera-health-intelligence.md`
- `scenarios/2026-07-07_offline-ai-and-cloud-sync.md`
- `scenarios/2026-07-09_privacy-preserving-face-masking.md`
- `scenarios/2026-07-09_generative-ai-copilot.md`

## 18.2 External benchmark sources, accessed 2026-07-14

- ONVIF, **Profile T**
- ONVIF, **Profile M**
- NIST IR 8259A, **IoT Device Cybersecurity Capability Core Baseline**
- Reuters, **India’s alarm over Chinese spying rocks surveillance industry**, 2025-05-28
- Reuters, **India strengthens privacy law with new data collection rules**, 2025-11-14
- The Verge, Ring Outdoor Cam Plus announcement and product overview
- Tom’s Guide, Google Nest Cam Indoor (3rd generation) review
- WIRED, Arlo Pro 5 review
- The Verge, EufyCam S3 Pro overview
- T3 and Tom’s Guide, TP-Link Tapo dual-lens camera coverage/review
- Reolink product/review coverage for local AI, tracking, line/loitering rules, and local storage
- Times of India, Qubo AI Guard announcement
- Current 2026 smart-security camera comparison coverage from established technology publications

---

## 19. Document control

This seed intentionally distinguishes:

- **KB-backed direction**
- **external market observations**
- **recommended requirements**
- **open decisions**

It should not be published as a final specification until Product, Hardware, Firmware, AI, Mobile/VMS, Security, Privacy/Legal, Installation, and Support owners review the P0 requirements and assign measurable release gates.
