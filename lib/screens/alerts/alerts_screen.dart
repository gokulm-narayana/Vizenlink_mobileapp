import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/alerts_controller.dart';
import '../../app_state/homes_controller.dart';
import '../../models/alert.dart';
import '../../models/alert_type_display.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'alert_detail_screen.dart';
import 'alert_settings_screen.dart';

enum _ReadFilter { all, unread, read }

const _allFilterLabel = 'All';

// SegmentedButton's default Material 3 height varies with text scale; 56
// covers the default plus some headroom rather than clipping on larger
// system font sizes.
const _segmentedButtonHeight = 56.0;

String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.alertsController,
    required this.homesController,
    this.initialCameraFilter,
    this.initialTypeFilter,
    this.initialUnreadOnly = false,
  });

  static const routeName = '/alerts';

  final AlertsController alertsController;
  final HomesController homesController;

  /// Pre-selects the Camera filter, e.g. when arriving from "Unread
  /// notifications — {camera}" on AlertDetailScreen.
  final String? initialCameraFilter;

  /// Pre-selects the Type filter alongside [initialCameraFilter], e.g.
  /// `AlertType.motion` when arriving from the "Unread notifications" row.
  final AlertType? initialTypeFilter;

  /// Pre-selects the Unread segment of the read-state toggle alongside
  /// [initialCameraFilter]/[initialTypeFilter].
  final bool initialUnreadOnly;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late _ReadFilter _readFilter = widget.initialUnreadOnly
      ? _ReadFilter.unread
      : _ReadFilter.all;
  String _homeFilter = _allFilterLabel;
  late Set<String> _cameraFilter = widget.initialCameraFilter == null
      ? {}
      : {widget.initialCameraFilter!};
  late AlertType? _typeFilter = widget.initialTypeFilter;
  DateTime? _dateFilter;

  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AlertsScreen lives in a StatefulShellBranch, so its State persists
    // across navigations within the tab — the `late` filter initializers
    // above only run once. Re-apply initialCameraFilter/initialTypeFilter/
    // initialUnreadOnly whenever a fresh value arrives (e.g. tapping
    // another "Unread notifications" card), so repeat visits actually
    // re-filter the list.
    if (widget.initialCameraFilter != null &&
        widget.initialCameraFilter != oldWidget.initialCameraFilter) {
      setState(() {
        _cameraFilter = {widget.initialCameraFilter!};
        _typeFilter = widget.initialTypeFilter;
        if (widget.initialUnreadOnly) _readFilter = _ReadFilter.unread;
      });
    }
  }

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// cameraId -> homeName, derived from HomesController so alerts (which
  /// only carry cameraId/cameraName) can be filtered by home.
  Map<String, String> _homeNameByCameraId() {
    final map = <String, String>{};
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        map[camera.id] = home.name;
      }
    }
    return map;
  }

  List<Alert> _filtered(List<Alert> alerts) {
    final homeByCamera = _homeNameByCameraId();
    return alerts.where((alert) {
      switch (_readFilter) {
        case _ReadFilter.unread:
          if (alert.isRead) return false;
        case _ReadFilter.read:
          if (!alert.isRead) return false;
        case _ReadFilter.all:
          break;
      }
      if (widget.alertsController.isCameraSnoozed(alert.cameraId)) {
        return false;
      }
      if (_homeFilter != _allFilterLabel &&
          homeByCamera[alert.cameraId] != _homeFilter) {
        return false;
      }
      if (_cameraFilter.isNotEmpty &&
          !_cameraFilter.contains(alert.cameraName)) {
        return false;
      }
      if (_typeFilter != null && alert.type != _typeFilter) return false;
      if (_dateFilter != null && !_isSameDate(alert.timestamp, _dateFilter!)) {
        return false;
      }
      return true;
    }).toList();
  }

  static String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

  bool get _hasActiveFilters =>
      _homeFilter != _allFilterLabel ||
      _cameraFilter.isNotEmpty ||
      _typeFilter != null ||
      _dateFilter != null;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ALERT-001'),
          title: const Text('Notifications'),
          // An empty `actions` list alone does NOT suppress Flutter's
          // auto-inserted endDrawer icon — AppBar only skips it when
          // `actions` is non-null AND non-empty. `automaticallyImplyActions:
          // false` is the actual switch, otherwise it duplicates the filter
          // icon already placed in the toggle row below.
          automaticallyImplyActions: false,
          actions: [
            IconButton(
              key: const Key('ALERT-022'),
              tooltip: 'Alert Settings',
              icon: const Icon(Icons.tune),
              onPressed: () => context.push(
                '${AlertsScreen.routeName}/${AlertSettingsScreen.routeName}',
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(_segmentedButtonHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<_ReadFilter>(
                      key: const Key('ALERT-002'),
                      segments: const [
                        ButtonSegment(
                          value: _ReadFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: _ReadFilter.unread,
                          label: Text('Unread'),
                        ),
                        ButtonSegment(
                          value: _ReadFilter.read,
                          label: Text('Read'),
                        ),
                      ],
                      selected: {_readFilter},
                      onSelectionChanged: (selection) =>
                          setState(() => _readFilter = selection.first),
                    ),
                  ),
                  IconButton(
                    key: const Key('ALERT-003'),
                    tooltip: 'Filter',
                    icon: Icon(
                      _hasActiveFilters
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ),
        endDrawer: ValueListenableBuilder(
          valueListenable: widget.alertsController,
          builder: (context, alerts, _) {
            final homeNames = [
              _allFilterLabel,
              ...{
                for (final home in widget.homesController.value.homes)
                  home.name,
              },
            ];
            final cameraNames = [
              for (final name in {for (final alert in alerts) alert.cameraName})
                name,
            ];
            final sortedCameraFilter = _cameraFilter.toList()..sort();

            return _FilterPanel(
              key: ValueKey(
                '$_homeFilter|${sortedCameraFilter.join(',')}|'
                '${_typeFilter?.name}|${_dateFilter?.toIso8601String()}',
              ),
              alerts: alerts,
              homeNames: homeNames,
              cameraNames: cameraNames,
              initialHome: _homeFilter,
              initialCameras: _cameraFilter,
              initialType: _typeFilter,
              initialDate: _dateFilter,
              onApply: (home, cameras, type, date) {
                setState(() {
                  _homeFilter = home;
                  _cameraFilter = cameras;
                  _typeFilter = type;
                  _dateFilter = date;
                });
              },
            );
          },
        ),
        body: ValueListenableBuilder(
          valueListenable: widget.alertsController,
          builder: (context, alerts, _) {
            final filtered = _filtered(alerts)
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return filtered.isEmpty
                ? Center(
                    child: Text(
                      key: const Key('ALERT-014'),
                      'No notifications yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : _GroupedAlertList(
                    alerts: filtered,
                    alertsController: widget.alertsController,
                    dateGroupLabel: _dateGroupLabel,
                    relativeTime: _relativeTime,
                    onTap: (alert) {
                      widget.alertsController.markRead(alert.id);
                      context.push(
                        '${AlertsScreen.routeName}/${AlertDetailScreen.routeName}',
                        extra: alert,
                      );
                    },
                  );
          },
        ),
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    super.key,
    required this.alerts,
    required this.homeNames,
    required this.cameraNames,
    required this.initialHome,
    required this.initialCameras,
    required this.initialType,
    required this.initialDate,
    required this.onApply,
  });

  final List<Alert> alerts;
  final List<String> homeNames;
  final List<String> cameraNames;
  final String initialHome;
  final Set<String> initialCameras;
  final AlertType? initialType;
  final DateTime? initialDate;
  final void Function(
    String home,
    Set<String> cameras,
    AlertType? type,
    DateTime? date,
  )
  onApply;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String _home = widget.initialHome;
  late Set<String> _cameras = Set.of(widget.initialCameras);
  late AlertType? _type = widget.initialType;
  late DateTime? _date = widget.initialDate;

  bool get _hasStagedFilters =>
      _home != _allFilterLabel ||
      _cameras.isNotEmpty ||
      _type != null ||
      _date != null;

  Future<void> _pickDate() async {
    final alertDates = {
      for (final alert in widget.alerts)
        DateTime(
          alert.timestamp.year,
          alert.timestamp.month,
          alert.timestamp.day,
        ),
    };
    if (alertDates.isEmpty) return;

    final sortedDates = alertDates.toList()..sort();
    final initial = _date != null && alertDates.contains(_date)
        ? _date!
        : sortedDates.last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: sortedDates.first,
      lastDate: sortedDates.last,
      selectableDayPredicate: alertDates.contains,
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  void _clearAll() {
    setState(() {
      _home = _allFilterLabel;
      _cameras = {};
      _type = null;
      _date = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('ALERT-015'),
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
                    'Filter notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_hasStagedFilters)
                    TextButton(
                      key: const Key('ALERT-020'),
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
                    key: const Key('ALERT-016'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Home',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: Text(_home),
                    children: [
                      RadioGroup<String>(
                        groupValue: _home,
                        onChanged: (value) => setState(() => _home = value!),
                        child: Column(
                          children: [
                            for (final home in widget.homeNames)
                              RadioListTile<String>(
                                key: Key('ALERT-016-$home'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(home),
                                value: home,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    key: const Key('ALERT-017'),
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
                          key: Key('ALERT-017-$name'),
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
                    key: const Key('ALERT-018'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Type',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: Text(_type?.label ?? _allFilterLabel),
                    children: [
                      RadioGroup<AlertType?>(
                        groupValue: _type,
                        onChanged: (value) => setState(() => _type = value),
                        child: Column(
                          children: [
                            RadioListTile<AlertType?>(
                              key: const Key('ALERT-018-all'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              secondary: const Icon(
                                Icons.category_outlined,
                                size: 20,
                              ),
                              title: const Text(_allFilterLabel),
                              value: null,
                            ),
                            for (final type in AlertType.values)
                              RadioListTile<AlertType?>(
                                key: Key('ALERT-018-${type.name}'),
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
                  const Divider(height: 24),
                  Text('Date', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('ALERT-019'),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _date == null ? 'Any date' : _formatDate(_date!),
                    ),
                    onPressed: _pickDate,
                  ),
                  if (_date != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _date = null),
                        child: const Text('Clear date'),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('ALERT-021'),
                  onPressed: () {
                    widget.onApply(_home, _cameras, _type, _date);
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

class _GroupedAlertList extends StatelessWidget {
  const _GroupedAlertList({
    required this.alerts,
    required this.alertsController,
    required this.dateGroupLabel,
    required this.relativeTime,
    required this.onTap,
  });

  final List<Alert> alerts;
  final AlertsController alertsController;
  final String Function(DateTime) dateGroupLabel;
  final String Function(DateTime) relativeTime;
  final void Function(Alert) onTap;

  void _deleteWithUndo(BuildContext context, Alert alert) {
    alertsController.deleteAlert(alert.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${alert.message}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => alertsController.restoreAlert(alert),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Alert>>{};
    for (final alert in alerts) {
      groups.putIfAbsent(dateGroupLabel(alert.timestamp), () => []).add(alert);
    }

    return ListView(
      key: const Key('ALERT-004'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            key: Key('ALERT-005-${entry.key}'),
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final alert in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: Key('ALERT-007-${alert.id}'),
                background: _SwipeBackground(
                  alignment: Alignment.centerLeft,
                  color: AppColors.cyan,
                  icon: Icons.mark_email_read_rounded,
                  label: 'Mark as read',
                ),
                secondaryBackground: _SwipeBackground(
                  alignment: Alignment.centerRight,
                  color: Theme.of(context).colorScheme.error,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    alertsController.markRead(alert.id);
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) => _deleteWithUndo(context, alert),
                child: _AlertListTile(
                  key: Key('ALERT-006-${alert.id}'),
                  alert: alert,
                  relativeLabel: relativeTime(alert.timestamp),
                  onTap: () => onTap(alert),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: color),
                Text(label, style: TextStyle(color: color)),
              ]
            : [
                Text(label, style: TextStyle(color: color)),
                Icon(icon, color: color),
              ],
      ),
    );
  }
}

class _AlertListTile extends StatelessWidget {
  const _AlertListTile({
    super.key,
    required this.alert,
    required this.relativeLabel,
    required this.onTap,
  });

  final Alert alert;
  final String relativeLabel;
  final VoidCallback onTap;

  void _openSnapshotPreview(BuildContext context) {
    // rootNavigator: true — this screen lives inside a StatefulShellRoute
    // branch with its own nested Navigator; pushing on the branch Navigator
    // alone would keep MainShell's bottom nav bar visible underneath.
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _SnapshotPreview(imageUrl: alert.snapshotUrl!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSnapshot = alert.snapshotUrl != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: alert.isRead
            ? null
            : Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      key: hasSnapshot
                          ? Key('ALERT-012-${alert.id}')
                          : Key('ALERT-008-${alert.id}'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.14),
                        shape: hasSnapshot
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: hasSnapshot
                            ? BorderRadius.circular(10)
                            : null,
                      ),
                      child: hasSnapshot
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => _openSnapshotPreview(context),
                                child: Image.network(
                                  alert.snapshotUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        alert.type.icon,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                ),
                              ),
                            )
                          : Icon(
                              alert.type.icon,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                    ),
                    if (hasSnapshot)
                      Positioned(
                        key: Key('ALERT-008-${alert.id}'),
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: Icon(
                            alert.type.icon,
                            size: 11,
                            color: colorScheme.primary,
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
                      key: Key('ALERT-009-${alert.id}'),
                      '${alert.message} — ${alert.cameraName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: alert.isRead
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      key: Key('ALERT-010-${alert.id}'),
                      relativeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!alert.isRead)
                Container(
                  key: Key('ALERT-011-${alert.id}'),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotPreview extends StatelessWidget {
  const _SnapshotPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('ALERT-013'),
      onTap: () => Navigator.of(context).pop(),
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0).abs() > 200) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
