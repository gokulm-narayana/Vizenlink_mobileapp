# EventsSummaryScreen

- **Dart file:** `lib/screens/events/events_summary_screen.dart`
- **Route:** `/events/summary` (pushed as a child of `/events`, `extra: EventsSummaryArgs`)
- **Purpose:** Summary/analytics view of recorded events — a time-range selector, headline stat tiles (total events, total recorded duration, busiest camera), breakdowns by type and by camera, and a per-day activity chart. Reached via the Summary icon (EVT-002) on [events_screen.md](events_screen.md). Mock/local data only — no backend/CCTV protocol integration yet (see CLAUDE.md).

## Navigation payload

`EventsSummaryArgs` (defined in this file, also imported by `main.dart`'s router):
- `events` — a snapshot of **all** of `EventsController`'s events, unfiltered by day/camera/type. This screen applies its own time-range filter (Today/This Week/This Month) independently of whatever filters happen to be active on EventsScreen.
- `onSelectFilter({cameraName, type})` — callback into `EventsScreen`'s own filter state. Tapping a breakdown row (EVTSUM-008/009) calls this then pops back to EventsScreen, so the row's camera/type becomes the active filter there.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| EVTSUM-001 | App bar title ("Events Summary") | AppBar | |
| EVTSUM-002 | Back button | BackButton | Returns to EventsScreen without changing its filters |
| EVTSUM-004 | Time range selector | `SegmentedButton` — Today / This Week / This Month | Defaults to This Week. Rescoped everything below (stats, breakdowns, chart) to events within the selected range |
| EVTSUM-005 | Total events stat tile | `_StatTile` | Count of events within the selected range |
| EVTSUM-006 | Recorded duration stat tile | `_StatTile` | Sum of `RecordedEvent.duration` within the range, formatted as "Xh Ym" or "Xm Ys" |
| EVTSUM-007 | Busiest camera stat tile | `_StatTile`, full width | Camera name with the most events in range, plus its count; "—" if no events |
| EVTSUM-008 | Event-type breakdown | `_BreakdownTile` list inside a `GlassCard`, one row per `EventType` present in range | Icon + color from `EventTypeDisplay`; each row's bar length is proportional to the top entry (busiest type is full-width); sorted descending by count; tapping a row calls `onSelectFilter(type: ...)` and pops back to EventsScreen |
| EVTSUM-009 | Per-camera breakdown | `_BreakdownTile` list inside a `GlassCard`, one row per camera present in range | Same layout as EVTSUM-008; tapping a row calls `onSelectFilter(cameraName: ...)` and pops back to EventsScreen |
| EVTSUM-010 | Activity-over-time chart | `_ActivityChart` — one bar per day, single hue (`colorScheme.primary`), height proportional to that day's event count | Hidden when the range is "Today" (a 1-day bar chart isn't meaningful). Day labels shown only in the 7-day (This Week) view — the 30-day (This Month) view omits labels to avoid crowding. Each bar has a `Tooltip` (long-press/hover) showing the exact date and count |
| EVTSUM-011 | Empty state | Text | "No events in this range" — shown instead of all stats/breakdowns/chart when the range has zero events |

## Design notes

- Single-hue bar chart (EVTSUM-010): this is a one-series magnitude-over-time chart, so it uses one color at varying height rather than a categorical palette — no legend needed for a single series.
- The type/camera breakdown color choices intentionally reuse existing app conventions: `EventTypeDisplay.timelineColor` (already the fixed categorical color for each `EventType`, used elsewhere on the Events timeline) for EVTSUM-008, and the theme's primary color for every row of EVTSUM-009 (cameras aren't a categorical dimension with pre-assigned colors elsewhere in the app).
- No new package/dependency — the bar chart and progress-bar breakdown rows are hand-rolled (`Container`/`FractionallySizedBox`/`LinearProgressIndicator`), consistent with the rest of the app's charts (e.g. the Playback/Events timelines).
