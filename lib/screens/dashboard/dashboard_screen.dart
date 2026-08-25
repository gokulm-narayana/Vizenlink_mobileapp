import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/ai_model_manager.dart';
import '../../app_state/alerts_controller.dart';
import '../../app_state/camera_sync.dart';
import '../../app_state/chat_controller.dart';
import '../../app_state/debug_transport_override.dart';
import '../../app_state/events_controller.dart';
import '../../app_state/homes_controller.dart';
import '../../app_state/live_view_controller.dart';
import '../../app_state/route_observer.dart';
import '../../models/camera.dart';
import '../../models/home.dart';
import '../../widgets/camera_chatbot.dart';
import '../../widgets/camera_tile.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_fab.dart';
import '../camera_live/camera_live_screen.dart';
import '../homes/manage_homes_screen.dart';
import '../multiview/multiview_screen.dart';
import '../scan/add_camera_manually_dialog.dart';
import '../scan/scanned_devices_screen.dart';
import '../scan/scanning_popup.dart';

const _manageHomesMenuValue = '__manage_homes__';
const _allTabLabel = 'All';
const _favouritesTabLabel = 'Favourites';
const _unassignedRoomLabel = 'Unassigned';

/// How often the Dashboard silently re-fetches a live snapshot for every
/// camera with a saved connection, so tiles don't go stale while the user
/// just sits on this screen without manually hitting Refresh anywhere.
const _thumbnailRefreshInterval = Duration(minutes: 5);

/// How often the Dashboard checks whether each camera is still reachable —
/// deliberately much tighter than [_thumbnailRefreshInterval] since this
/// only pings (see [pingCameraReachability]) rather than fetching a full
/// snapshot image, so a camera going offline while the user is sitting on
/// this screen shows up within seconds instead of up to 5 minutes later.
const _reachabilityCheckInterval = Duration(seconds: 15);

enum _CollectionLayout { grid, list }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.homesController,
    required this.alertsController,
    required this.eventsController,
    required this.aiModelManager,
    required this.chatController,
  });

  static const routeName = '/dashboard';

  final HomesController homesController;
  final AlertsController alertsController;
  final EventsController eventsController;
  final AiModelManager aiModelManager;
  final ChatController chatController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, RouteAware {
  late TabController _collectionTabController;
  List<String> _tabLabels = const [];
  _CollectionLayout _layout = _CollectionLayout.grid;
  bool _isReorderMode = false;
  bool _isFabExpanded = true;
  Timer? _thumbnailRefreshTimer;
  Timer? _reachabilityCheckTimer;

  @override
  void initState() {
    super.initState();
    _tabLabels = _tabLabelsFor(widget.homesController.value.selectedHome);
    _collectionTabController = TabController(
      length: _tabLabels.length,
      vsync: this,
    );
    widget.homesController.addListener(_onHomesChanged);
    _startBackgroundTimers();
  }

  void _startBackgroundTimers() {
    _thumbnailRefreshTimer ??= Timer.periodic(
      _thumbnailRefreshInterval,
      (_) => _refreshAllThumbnails(),
    );
    _reachabilityCheckTimer ??= Timer.periodic(
      _reachabilityCheckInterval,
      (_) => _checkAllReachability(),
    );
  }

  void _stopBackgroundTimers() {
    _thumbnailRefreshTimer?.cancel();
    _thumbnailRefreshTimer = null;
    _reachabilityCheckTimer?.cancel();
    _reachabilityCheckTimer = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  /// Dashboard's reachability/thumbnail polling covers every camera in
  /// every home — while a screen like Camera Live is pushed on top (e.g. an
  /// active WebRTC/WAN session for one of those same cameras), these two
  /// timers would otherwise keep contending with it for the same camera's
  /// LAN bandwidth/embedded HTTP server for no benefit, since the user can't
  /// see the Dashboard tiles they'd be refreshing anyway. Paused for exactly
  /// as long as this screen is covered, not stopped for good — resumes the
  /// moment the user navigates back.
  @override
  void didPushNext() => _stopBackgroundTimers();

  @override
  void didPopNext() => _startBackgroundTimers();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    widget.homesController.removeListener(_onHomesChanged);
    _collectionTabController.dispose();
    _stopBackgroundTimers();
    super.dispose();
  }

  /// Silently re-fetches a live snapshot for every camera (across every
  /// home, not just the one currently selected) that has a saved connection
  /// — same underlying call as each camera's own manual "Refresh preview"
  /// button, just fired on a timer instead of a tap. Fire-and-forget:
  /// per-camera failures are dropped rather than surfaced, exactly like a
  /// missed manual refresh would be — the next tick tries again.
  void _refreshAllThumbnails() {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        final connection = camera.connection;
        if (connection == null) continue;
        unawaited(
          refreshCameraSnapshot(
            homesController: widget.homesController,
            cameraId: camera.id,
            connection: connection,
          ),
        );
      }
    }
  }

  /// Cheap online/offline check for every camera (across every home) with a
  /// saved connection — see [_reachabilityCheckInterval]'s doc comment for
  /// why this is separate from [_refreshAllThumbnails]. Fire-and-forget,
  /// same reasoning as that method.
  void _checkAllReachability() {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        final connection = camera.connection;
        if (connection == null) continue;
        unawaited(
          pingCameraReachability(
            homesController: widget.homesController,
            cameraId: camera.id,
            connection: connection,
          ),
        );
      }
    }
  }

  void _onHomesChanged() {
    final labels = _tabLabelsFor(widget.homesController.value.selectedHome);
    if (_listEquals(_tabLabels, labels)) {
      setState(() {});
      return;
    }

    final previousIndex = _collectionTabController.index;
    final oldController = _collectionTabController;
    setState(() {
      _tabLabels = labels;
      _collectionTabController = TabController(
        length: labels.length,
        vsync: this,
        initialIndex: previousIndex < labels.length ? previousIndex : 0,
      );
    });
    // Dispose the old controller after the new one has taken over the tree.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => oldController.dispose(),
    );
  }

  List<String> _tabLabelsFor(Home home) {
    final roomNames = <String>{};
    var hasUnassigned = false;
    for (final camera in home.cameras) {
      if (camera.room == null) {
        hasUnassigned = true;
      } else {
        roomNames.add(camera.room!);
      }
    }
    final sortedRooms = roomNames.toList()..sort();
    return [
      _allTabLabel,
      _favouritesTabLabel,
      ...sortedRooms,
      if (hasUnassigned) _unassignedRoomLabel,
    ];
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _onUserScroll(UserScrollNotification notification) {
    switch (notification.direction) {
      case ScrollDirection.reverse:
        if (_isFabExpanded) setState(() => _isFabExpanded = false);
      case ScrollDirection.forward:
        if (!_isFabExpanded) setState(() => _isFabExpanded = true);
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  Future<void> _startAddCameraFlow() async {
    // Runs the real scan behind a popup that stays on the Dashboard route —
    // cancelable (Cancel button or back gesture/button), both confirming
    // first via "Do you want to stop scanning?" (see scanning_popup.dart).
    // Only navigates to the results screen once a real (non-cancelled) scan
    // has actually finished, passing its results along so that screen
    // doesn't re-run the same scan a second time.
    final result = await showDashboardScanningPopup(context);
    if (!mounted) return;
    if (result.addManually) {
      await showAddCameraManuallyDialog(
        context,
        homesController: widget.homesController,
      );
      return;
    }
    final cameras = result.cameras;
    if (cameras == null) return;
    context.push(
      '${DashboardScreen.routeName}/${ScannedDevicesScreen.routeName}',
      extra: cameras,
    );
  }

  void _toggleLayout() {
    setState(() {
      _layout = _layout == _CollectionLayout.grid
          ? _CollectionLayout.list
          : _CollectionLayout.grid;
    });
  }

  List<Camera> _camerasForTab(Home home, String label) {
    switch (label) {
      case _allTabLabel:
        // Pinned cameras float to the top; both groups keep home.cameras'
        // relative (drag-reorderable) order within themselves.
        final pinned = home.cameras.where((camera) => camera.isPinned);
        final unpinned = home.cameras.where((camera) => !camera.isPinned);
        return [...pinned, ...unpinned];
      case _favouritesTabLabel:
        return home.cameras.where((camera) => camera.isFavorite).toList();
      case _unassignedRoomLabel:
        return home.cameras.where((camera) => camera.room == null).toList();
      default:
        return home.cameras.where((camera) => camera.room == label).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.homesController.value;
    final selectedHome = state.selectedHome;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: PopupMenuButton<String>(
            key: const Key('DASH-001'),
            tooltip: 'Switch home',
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == _manageHomesMenuValue) {
                context.push(
                  '${DashboardScreen.routeName}/${ManageHomesScreen.routeName}',
                );
              } else {
                widget.homesController.selectHome(value);
              }
            },
            itemBuilder: (context) => [
              for (final home in state.homes)
                PopupMenuItem<String>(
                  key: Key('DASH-002-${home.id}'),
                  value: home.id,
                  child: Row(
                    children: [
                      if (home.id == selectedHome.id)
                        const Icon(Icons.check, size: 18),
                      if (home.id != selectedHome.id) const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(home.name),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                key: Key('DASH-003'),
                value: _manageHomesMenuValue,
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Manage homes'),
                  ],
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selectedHome.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          actions: [
            const _ForceTransportMenu(),
            if (_isReorderMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  key: const Key('DASH-018'),
                  onPressed: () => setState(() => _isReorderMode = false),
                  child: const Text('Done'),
                ),
              )
            else
              IconButton(
                key: const Key('DASH-019'),
                tooltip: 'Add camera',
                icon: const Icon(Icons.add_a_photo_outlined),
                onPressed: _startAddCameraFlow,
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    key: const Key('DASH-008'),
                    controller: _collectionTabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [for (final label in _tabLabels) Tab(text: label)],
                  ),
                ),
                IconButton(
                  key: const Key('DASH-004'),
                  tooltip: _layout == _CollectionLayout.grid
                      ? 'Switch to list view'
                      : 'Switch to grid view',
                  icon: Icon(
                    _layout == _CollectionLayout.grid
                        ? Icons.view_list_outlined
                        : Icons.grid_view_outlined,
                  ),
                  onPressed: _toggleLayout,
                ),
                IconButton(
                  key: const Key('DASH-022'),
                  tooltip: 'Multiview',
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  // rootNavigator: true — MultiviewScreen is a modal
                  // takeover (like CameraLiveScreen's fullscreen/AI Mode),
                  // not a nested go_router route, so it renders outside
                  // MainShell's bottom nav bar instead of underneath it.
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => MultiviewScreen(
                            home: selectedHome,
                            homesController: widget.homesController,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
        body: NotificationListener<UserScrollNotification>(
          onNotification: _onUserScroll,
          child: TabBarView(
            controller: _collectionTabController,
            children: [
              for (final label in _tabLabels)
                _CameraCollection(
                  key: Key('DASH-005-$label'),
                  home: selectedHome,
                  layout: _layout,
                  cameras: _camerasForTab(selectedHome, label),
                  isAllTab: label == _allTabLabel,
                  isReorderMode: _isReorderMode,
                  onEnterReorderMode: () =>
                      setState(() => _isReorderMode = true),
                  emptyMessage: label == _allTabLabel
                      ? 'No cameras in ${selectedHome.name} yet'
                      : 'No cameras in $label',
                  homesController: widget.homesController,
                  alertsController: widget.alertsController,
                ),
            ],
          ),
        ),
        floatingActionButton: GradientFab(
          key: const Key('DASH-020'),
          expanded: _isFabExpanded,
          onPressed: () => showCameraChatbot(
            context,
            homesController: widget.homesController,
            aiModelManager: widget.aiModelManager,
            chatController: widget.chatController,
          ),
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('Ask AI'),
        ),
      ),
    );
  }
}

class _CameraCollection extends StatelessWidget {
  const _CameraCollection({
    super.key,
    required this.home,
    required this.layout,
    required this.cameras,
    required this.isAllTab,
    required this.isReorderMode,
    required this.onEnterReorderMode,
    required this.emptyMessage,
    required this.homesController,
    required this.alertsController,
  });

  final Home home;
  final _CollectionLayout layout;
  final List<Camera> cameras;
  final bool isAllTab;

  /// While true, tiles hand whole-tile long-press-drag to
  /// [ReorderableListView]'s default behavior instead of opening the
  /// actions menu.
  final bool isReorderMode;
  final VoidCallback onEnterReorderMode;
  final String emptyMessage;
  final HomesController homesController;
  final AlertsController alertsController;

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final reordered = [...cameras];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final beforeId = newIndex + 1 < reordered.length
        ? reordered[newIndex + 1].id
        : null;
    homesController.reorderCamera(home.id, moved.id, beforeId);
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return Center(
        child: Text(
          key: const Key('DASH-007'),
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: alertsController,
      builder: (context, alerts, _) {
        if (layout == _CollectionLayout.list) {
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: isReorderMode,
            itemCount: cameras.length,
            onReorderItem: _onReorder,
            itemBuilder: (context, index) {
              final camera = cameras[index];
              return CameraListTile(
                key: Key('DASH-006-${camera.id}'),
                camera: camera,
                isReorderMode: isReorderMode,
                unreadAlertCount: alertsController.unreadCountForCamera(
                  camera.id,
                ),
                showPinToggle: isAllTab,
                onToggleFavorite: () =>
                    homesController.toggleFavorite(home.id, camera.id),
                onTogglePin: () =>
                    homesController.togglePin(home.id, camera.id),
                onDelete: () =>
                    homesController.deleteCamera(home.id, camera.id),
                onRearrange: onEnterReorderMode,
                onTap: () => context.push(
                  '${DashboardScreen.routeName}/${CameraLiveScreen.routeName}/${camera.id}',
                  extra: camera,
                ),
              );
            },
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          buildDefaultDragHandles: isReorderMode,
          itemCount: cameras.length,
          onReorderItem: _onReorder,
          itemBuilder: (context, index) {
            final camera = cameras[index];
            return CameraTile(
              key: Key('DASH-006-${camera.id}'),
              camera: camera,
              isReorderMode: isReorderMode,
              unreadAlertCount: alertsController.unreadCountForCamera(
                camera.id,
              ),
              showPinToggle: isAllTab,
              onToggleFavorite: () =>
                  homesController.toggleFavorite(home.id, camera.id),
              onTogglePin: () => homesController.togglePin(home.id, camera.id),
              onDelete: () => homesController.deleteCamera(home.id, camera.id),
              onRearrange: onEnterReorderMode,
              onTap: () => context.push(
                '${DashboardScreen.routeName}/${CameraLiveScreen.routeName}/${camera.id}',
                extra: camera,
              ),
            );
          },
        );
      },
    );
  }
}

/// Test-only — see [DebugTransportOverride]'s doc. Global (not per-camera)
/// LAN/WAN override, applied by every [LiveViewController] (camera live
/// view and Multiview tiles) for as long as this choice stays set. Remove
/// this widget once WAN testing no longer needs a manual override.
class _ForceTransportMenu extends StatelessWidget {
  const _ForceTransportMenu();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LiveViewTransport?>(
      valueListenable: DebugTransportOverride.instance,
      builder: (context, forced, _) {
        return PopupMenuButton<LiveViewTransport?>(
          key: const Key('DASH-023'),
          icon: Icon(
            Icons.bug_report_outlined,
            color: forced == null ? null : Colors.orangeAccent,
          ),
          tooltip: forced == null
              ? 'Test: force LAN/WAN for all cameras (currently Auto)'
              : 'Test: forcing ${forced == LiveViewTransport.lan ? 'LAN' : 'WAN'} for all cameras',
          onSelected: (transport) =>
              DebugTransportOverride.instance.value = transport,
          itemBuilder: (context) => const [
            PopupMenuItem(value: null, child: Text('Auto (normal behavior)')),
            PopupMenuItem(
              value: LiveViewTransport.lan,
              child: Text('Force LAN (all cameras)'),
            ),
            PopupMenuItem(
              value: LiveViewTransport.wan,
              child: Text('Force WAN (all cameras)'),
            ),
          ],
        );
      },
    );
  }
}
