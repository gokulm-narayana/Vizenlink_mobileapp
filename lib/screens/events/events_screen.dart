import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/events_controller.dart';
import '../../models/event.dart';
import '../../models/event_type_display.dart';
import '../../widgets/camera_timeline.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'event_detail_screen.dart';
import 'events_summary_screen.dart';

/// Mock recording-coverage data for the day's timeline band — a couple of
/// gaps included so the gray "no recording" dead zone is visible, until a
/// real recordings backend exists (see CLAUDE.md).
const _mockRecordedRanges = [
  TimelineRange(0, 0.25),
  TimelineRange(0.2708, 0.5833),
  TimelineRange(0.6042, 1),
];

const _allFilterLabel = 'All';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, required this.eventsController});

  static const routeName = '/events';

  final EventsController eventsController;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<String> _cameraFilter = {};
  EventType? _typeFilter;
  DateTime? _dayFilter;
  double _scrubFraction =
      (TimeOfDay.now().hour * 60 + TimeOfDay.now().minute) / (24 * 60);

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _dateGroupLabel(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  bool get _hasActiveFilters => _cameraFilter.isNotEmpty || _typeFilter != null;

  List<RecordedEvent> _filtered(List<RecordedEvent> events) {
    return events.where((event) {
      if (_cameraFilter.isNotEmpty &&
          !_cameraFilter.contains(event.cameraName)) {
        return false;
      }
      if (_typeFilter != null && event.type != _typeFilter) return false;
      return true;
    }).toList();
  }

  DateTime _resolvedDay(List<RecordedEvent> events) {
    if (_dayFilter != null) return _dayFilter!;
    if (events.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final latest = events
        .map((e) => e.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime(latest.year, latest.month, latest.day);
  }

  Future<void> _pickDay(List<RecordedEvent> events) async {
    final eventDates = {
      for (final event in events)
        DateTime(
          event.timestamp.year,
          event.timestamp.month,
          event.timestamp.day,
        ),
    };
    if (eventDates.isEmpty) return;

    final sortedDates = eventDates.toList()..sort();
    final day = _resolvedDay(events);
    final initial = eventDates.contains(day) ? day : sortedDates.last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: sortedDates.first,
      lastDate: sortedDates.last,
      selectableDayPredicate: eventDates.contains,
    );
    if (picked == null) return;
    setState(() => _dayFilter = picked);
  }

  void _openEventDetail(RecordedEvent event) {
    context.push(
      '${EventsScreen.routeName}/${EventDetailScreen.routeName}',
      extra: event,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('EVT-001'),
          title: const Text('Events'),
          actions: [
            IconButton(
              key: const Key('EVT-003'),
              tooltip: 'Filter',
              icon: Icon(
                _hasActiveFilters
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_outlined,
              ),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            IconButton(
              key: const Key('EVT-002'),
              tooltip: 'Summary',
              icon: const Icon(Icons.summarize_outlined),
              onPressed: () => context.push(
                '${EventsScreen.routeName}/${EventsSummaryScreen.routeName}',
                extra: EventsSummaryArgs(
                  events: widget.eventsController.value,
                  onSelectFilter: ({cameraName, type}) {
                    setState(() {
                      _cameraFilter = cameraName != null ? {cameraName} : {};
                      _typeFilter = type;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        endDrawer: ValueListenableBuilder(
          valueListenable: widget.eventsController,
          builder: (context, events, _) {
            final cameraNames = [
              for (final name in {for (final event in events) event.cameraName})
                name,
            ];
            return _EventFilterPanel(
              key: ValueKey(
                '${(_cameraFilter.toList()..sort()).join(',')}|${_typeFilter?.name}',
              ),
              cameraNames: cameraNames,
              initialCameras: _cameraFilter,
              initialType: _typeFilter,
              onApply: (cameras, type) {
                setState(() {
                  _cameraFilter = cameras;
                  _typeFilter = type;
                });
              },
            );
          },
        ),
        body: ValueListenableBuilder(
          valueListenable: widget.eventsController,
          builder: (context, events, _) {
            final filtered = _filtered(events);
            final day = _resolvedDay(events);
            final dayEvents = filtered
                .where((event) => _isSameDate(event.timestamp, day))
                .toList();
            final sortedFiltered = [...filtered]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  key: const Key('EVT-004'),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setState(
                          () => _dayFilter = day.subtract(
                            const Duration(days: 1),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDay(events),
                        child: Text(
                          _dateGroupLabel(day) == 'Today' ||
                                  _dateGroupLabel(day) == 'Yesterday'
                              ? _dateGroupLabel(day)
                              : _formatDate(day),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setState(
                          () => _dayFilter = day.add(const Duration(days: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CameraTimeline(
                    rulerKey: const Key('EVT-007'),
                    zoomOutKey: const Key('EVT-022'),
                    zoomInKey: const Key('EVT-023'),
                    timeLabelKey: const Key('EVT-005'),
                    legendKey: const Key('EVT-006'),
                    recordingBandKey: const Key('EVT-025'),
                    needleFraction: _scrubFraction,
                    onNeedleFractionChanged: (fraction) =>
                        setState(() => _scrubFraction = fraction),
                    recordedRanges: _mockRecordedRanges,
                    legend: const [
                      TimelineLegendEntry(
                        color: Color(0xFF3B82F6),
                        label: 'Motion',
                      ),
                      TimelineLegendEntry(
                        color: Color(0xFF10B981),
                        label: 'Person',
                      ),
                      TimelineLegendEntry(
                        color: Color(0xFFEF4444),
                        label: 'Alert',
                      ),
                      TimelineLegendEntry(
                        color: Color(0xFFF59E0B),
                        label: 'Other',
                      ),
                      TimelineLegendEntry(
                        color: kRecordedBandColor,
                        label: 'Recorded',
                      ),
                    ],
                    markers: [
                      for (final event in dayEvents)
                        TimelineMarker(
                          key: Key('EVT-008-${event.id}'),
                          startFraction:
                              (event.timestamp.hour * 3600 +
                                  event.timestamp.minute * 60 +
                                  event.timestamp.second) /
                              (24 * 3600),
                          endFraction:
                              (event.timestamp.hour * 3600 +
                                  event.timestamp.minute * 60 +
                                  event.timestamp.second +
                                  event.duration.inSeconds) /
                              (24 * 3600),
                          color: event.type.timelineColor,
                          icon: event.type.icon,
                          onTap: () => _openEventDetail(event),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: sortedFiltered.isEmpty
                      ? Center(
                          child: Text(
                            key: const Key('EVT-016'),
                            'No recorded events',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : _buildEventList(sortedFiltered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(List<RecordedEvent> events) {
    final groups = <String, List<RecordedEvent>>{};
    for (final event in events) {
      groups.putIfAbsent(_dateGroupLabel(event.timestamp), () => []).add(event);
    }

    return ListView(
      key: const Key('EVT-011'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            key: Key('EVT-012-${entry.key}'),
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final event in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventListTile(
                key: Key('EVT-013-${event.id}'),
                event: event,
                durationLabel: _formatDuration(event.duration),
                onPlay: () => _openEventDetail(event),
              ),
            ),
        ],
      ],
    );
  }
}

class _EventFilterPanel extends StatefulWidget {
  const _EventFilterPanel({
    super.key,
    required this.cameraNames,
    required this.initialCameras,
    required this.initialType,
    required this.onApply,
  });

  final List<String> cameraNames;
  final Set<String> initialCameras;
  final EventType? initialType;
  final void Function(Set<String> cameras, EventType? type) onApply;

  @override
  State<_EventFilterPanel> createState() => _EventFilterPanelState();
}

class _EventFilterPanelState extends State<_EventFilterPanel> {
  late Set<String> _cameras = Set.of(widget.initialCameras);
  late EventType? _type = widget.initialType;

  bool get _hasStagedFilters => _cameras.isNotEmpty || _type != null;

  void _clearAll() {
    setState(() {
      _cameras = {};
      _type = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('EVT-017'),
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_hasStagedFilters)
                    TextButton(
                      key: const Key('EVT-020'),
                      onPressed: _clearAll,
                      child: const Text('Clear all'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ExpansionTile(
                    key: const Key('EVT-018'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Camera',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: Text(
                      _cameras.isEmpty
                          ? _allFilterLabel
                          : _cameras.length == 1
                          ? _cameras.first
                          : '${_cameras.length} cameras',
                    ),
                    children: [
                      for (final name in widget.cameraNames)
                        CheckboxListTile(
                          key: Key('EVT-018-$name'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(name),
                          value: _cameras.contains(name),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _cameras.add(name);
                              } else {
                                _cameras.remove(name);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    key: const Key('EVT-019'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Type',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: Text(_type?.label ?? _allFilterLabel),
                    children: [
                      RadioGroup<EventType?>(
                        groupValue: _type,
                        onChanged: (value) => setState(() => _type = value),
                        child: Column(
                          children: [
                            RadioListTile<EventType?>(
                              key: const Key('EVT-019-all'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              secondary: const Icon(
                                Icons.category_outlined,
                                size: 20,
                              ),
                              title: const Text(_allFilterLabel),
                              value: null,
                            ),
                            for (final type in EventType.values)
                              RadioListTile<EventType?>(
                                key: Key('EVT-019-${type.name}'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: Icon(type.icon, size: 20),
                                title: Text(type.label),
                                value: type,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('EVT-021'),
                  onPressed: () {
                    widget.onApply(_cameras, _type);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({
    super.key,
    required this.event,
    required this.durationLabel,
    required this.onPlay,
  });

  final RecordedEvent event;
  final String durationLabel;
  final VoidCallback onPlay;

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPlay,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: event.thumbnailUrl == null
                        ? Container(
                            width: 72,
                            height: 72,
                            color: colorScheme.primary.withValues(alpha: 0.14),
                            child: Icon(
                              event.type.icon,
                              color: colorScheme.primary,
                            ),
                          )
                        : Image.network(
                            event.thumbnailUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 72,
                                  height: 72,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.14,
                                  ),
                                  child: Icon(
                                    event.type.icon,
                                    color: colorScheme.primary,
                                  ),
                                ),
                          ),
                  ),
                  Positioned.fill(
                    key: Key('EVT-015-${event.id}'),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    key: Key('EVT-014-${event.id}'),
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.type.label} — ${event.cameraName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relativeTime(event.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
