import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../models/event_type_display.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

enum _SummaryRange { today, week, month }

/// Payload for navigating into [EventsSummaryScreen]: a snapshot of all
/// events (unfiltered by day/camera/type — the summary applies its own time
/// range) plus a callback that applies a camera/type filter back on
/// [EventsScreen] when a breakdown row is tapped.
class EventsSummaryArgs {
  const EventsSummaryArgs({required this.events, required this.onSelectFilter});

  final List<RecordedEvent> events;
  final void Function({String? cameraName, EventType? type}) onSelectFilter;
}

/// Summary/analytics view of recorded events: a time-range selector, total
/// events/duration/busiest-camera stat tiles, breakdowns by type and by
/// camera (tapping a row jumps back to EventsScreen filtered by it), and a
/// per-day activity chart. Mock/local data only — no backend/CCTV protocol
/// integration yet (see CLAUDE.md).
class EventsSummaryScreen extends StatefulWidget {
  const EventsSummaryScreen({super.key, required this.args});

  static const routeName = 'summary';

  final EventsSummaryArgs args;

  @override
  State<EventsSummaryScreen> createState() => _EventsSummaryScreenState();
}

class _EventsSummaryScreenState extends State<EventsSummaryScreen> {
  _SummaryRange _range = _SummaryRange.week;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _rangeStart {
    final today = _dateOnly(DateTime.now());
    return switch (_range) {
      _SummaryRange.today => today,
      _SummaryRange.week => today.subtract(const Duration(days: 6)),
      _SummaryRange.month => today.subtract(const Duration(days: 29)),
    };
  }

  int get _dayCount => switch (_range) {
    _SummaryRange.today => 1,
    _SummaryRange.week => 7,
    _SummaryRange.month => 30,
  };

  List<RecordedEvent> get _scopedEvents => widget.args.events
      .where((event) => !event.timestamp.isBefore(_rangeStart))
      .toList();

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    final seconds = duration.inSeconds.remainder(60);
    return '${duration.inMinutes}m ${seconds}s';
  }

  void _openFilteredEvents({String? cameraName, EventType? type}) {
    widget.args.onSelectFilter(cameraName: cameraName, type: type);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final events = _scopedEvents;
    final totalDuration = events.fold<Duration>(
      Duration.zero,
      (sum, event) => sum + event.duration,
    );

    final byType = <EventType, int>{};
    for (final event in events) {
      byType[event.type] = (byType[event.type] ?? 0) + 1;
    }
    final sortedTypes = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final byCamera = <String, int>{};
    for (final event in events) {
      byCamera[event.cameraName] = (byCamera[event.cameraName] ?? 0) + 1;
    }
    final sortedCameras = byCamera.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final busiestCamera = sortedCameras.isEmpty ? null : sortedCameras.first;

    final byDay = <DateTime, int>{};
    for (final event in events) {
      final day = _dateOnly(event.timestamp);
      byDay[day] = (byDay[day] ?? 0) + 1;
    }
    final today = _dateOnly(DateTime.now());
    final days = List.generate(
      _dayCount,
      (i) => today.subtract(Duration(days: _dayCount - 1 - i)),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('EVTSUM-001'),
          title: const Text('Events Summary'),
          leading: BackButton(key: const Key('EVTSUM-002')),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<_SummaryRange>(
              key: const Key('EVTSUM-004'),
              segments: const [
                ButtonSegment(value: _SummaryRange.today, label: Text('Today')),
                ButtonSegment(
                  value: _SummaryRange.week,
                  label: Text('This Week'),
                ),
                ButtonSegment(
                  value: _SummaryRange.month,
                  label: Text('This Month'),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.first),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    key: const Key('EVTSUM-011'),
                    'No events in this range',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatTile(
                        key: const Key('EVTSUM-005'),
                        icon: Icons.event_note_rounded,
                        label: 'Total events',
                        value: '${events.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        key: const Key('EVTSUM-006'),
                        icon: Icons.timelapse_rounded,
                        label: 'Recorded',
                        value: _formatDuration(totalDuration),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StatTile(
                key: const Key('EVTSUM-007'),
                icon: Icons.videocam_rounded,
                label: 'Busiest camera',
                value: busiestCamera == null
                    ? '—'
                    : '${busiestCamera.key} (${busiestCamera.value})',
              ),
              const SizedBox(height: 24),
              Text('By type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('EVTSUM-008'),
                  children: [
                    for (var i = 0; i < sortedTypes.length; i++)
                      _BreakdownTile(
                        icon: sortedTypes[i].key.icon,
                        color: sortedTypes[i].key.timelineColor,
                        label: sortedTypes[i].key.label,
                        count: sortedTypes[i].value,
                        maxCount: sortedTypes.first.value,
                        isLast: i == sortedTypes.length - 1,
                        onTap: () =>
                            _openFilteredEvents(type: sortedTypes[i].key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('By camera', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('EVTSUM-009'),
                  children: [
                    for (var i = 0; i < sortedCameras.length; i++)
                      _BreakdownTile(
                        icon: Icons.videocam_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        label: sortedCameras[i].key,
                        count: sortedCameras[i].value,
                        maxCount: sortedCameras.first.value,
                        isLast: i == sortedCameras.length - 1,
                        onTap: () => _openFilteredEvents(
                          cameraName: sortedCameras[i].key,
                        ),
                      ),
                  ],
                ),
              ),
              if (_range != _SummaryRange.today) ...[
                const SizedBox(height: 24),
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GlassCard(
                  key: const Key('EVTSUM-010'),
                  child: _ActivityChart(days: days, counts: byDay),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One row of a breakdown list: icon + label, a proportional bar (relative
/// to the top entry, so the busiest row is always full-width), and the raw
/// count — tapping jumps back to EventsScreen filtered by this row.
class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.isLast,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final int maxCount;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 12 : 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-day event-count bar chart — a single series (magnitude over time), so
/// one hue (the theme's primary color) at varying bar height, no legend
/// needed. Each bar is tappable (via [Tooltip], long-press/hover) to reveal
/// its exact date and count.
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.days, required this.counts});

  final List<DateTime> days;
  final Map<DateTime, int> counts;

  String _shortLabel(DateTime day) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);
    final showLabels = days.length <= 7;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: '${_shortLabel(day)}: ${counts[day] ?? 0}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: maxCount == 0
                                ? 0
                                : (counts[day] ?? 0) / maxCount,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 4),
                        Text(
                          _shortLabel(day).split(' ').last,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
