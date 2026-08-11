import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobilecctvapp/app_state/ai_model_manager.dart';
import 'package:mobilecctvapp/app_state/alerts_controller.dart';
import 'package:mobilecctvapp/app_state/events_controller.dart';
import 'package:mobilecctvapp/app_state/homes_controller.dart';
import 'package:mobilecctvapp/main.dart';
import 'package:mobilecctvapp/screens/dashboard/dashboard_screen.dart';
import 'package:mobilecctvapp/screens/homes/manage_homes_screen.dart';
import 'package:mobilecctvapp/screens/scan/scanned_devices_screen.dart';
import 'package:mobilecctvapp/screens/scan/scanning_popup.dart';

void main() {
  // AiModelManager/ThemeController.load() both call
  // SharedPreferences.getInstance(), which never resolves in a test
  // environment without a mock store — SplashScreen (the app's initial
  // route) waits on both before navigating to the dashboard, so every test
  // that pumps the full app needs this.
  SharedPreferences.setMockInitialValues({});

  testWidgets('Dashboard is the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileCctvApp());
    // The splash screen hands off to the dashboard once app startup
    // (theme/AI-consent loading, plus a minimum visible duration) resolves.
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    expect(find.text('Main House'), findsOneWidget);
    expect(find.byKey(const Key('SHELL-001')), findsOneWidget);
  });

  testWidgets('Switching homes via the dropdown does not crash', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);
    final alertsController = AlertsController();
    addTearDown(alertsController.dispose);
    final eventsController = EventsController();
    addTearDown(eventsController.dispose);
    final aiModelManager = AiModelManager();
    addTearDown(aiModelManager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          homesController: homesController,
          alertsController: alertsController,
          eventsController: eventsController,
          aiModelManager: aiModelManager,
        ),
      ),
    );

    // Open the home switcher dropdown and switch to Office (fewer rooms
    // than Main House, so the tab count/controller changes).
    await tester.tap(find.byKey(const Key('DASH-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('DASH-002-home-2')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Office'), findsWidgets);

    // Switch back to Main House.
    await tester.tap(find.byKey(const Key('DASH-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('DASH-002-home-1')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Main House'), findsWidgets);
  });

  testWidgets('Dashboard shows the selected home and its cameras', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);
    final alertsController = AlertsController();
    addTearDown(alertsController.dispose);
    final eventsController = EventsController();
    addTearDown(eventsController.dispose);
    final aiModelManager = AiModelManager();
    addTearDown(aiModelManager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          homesController: homesController,
          alertsController: alertsController,
          eventsController: eventsController,
          aiModelManager: aiModelManager,
        ),
      ),
    );

    expect(find.text('Main House'), findsOneWidget);
    expect(find.text('Front Door Cam'), findsOneWidget);
    expect(find.byKey(const Key('DASH-005-All')), findsOneWidget);

    await tester.tap(find.byKey(const Key('DASH-004')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('DASH-006-cam-1')), findsOneWidget);
  });

  testWidgets('Dashboard Favourites tab reflects favourite toggles', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);
    final alertsController = AlertsController();
    addTearDown(alertsController.dispose);
    final eventsController = EventsController();
    addTearDown(eventsController.dispose);
    final aiModelManager = AiModelManager();
    addTearDown(aiModelManager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          homesController: homesController,
          alertsController: alertsController,
          eventsController: eventsController,
          aiModelManager: aiModelManager,
        ),
      ),
    );

    // cam-1 (Front Door Cam) starts favourited; un-favourite it from the All
    // tab via the long-press actions menu.
    await tester.longPress(find.byKey(const Key('DASH-006-cam-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('DASH-016-favorite')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(find.text('Front Door Cam'), findsNothing);
    expect(find.text('Living Room Cam'), findsOneWidget);
  });

  testWidgets('Dashboard has one tab per room and filters cameras by it', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);
    final alertsController = AlertsController();
    addTearDown(alertsController.dispose);
    final eventsController = EventsController();
    addTearDown(eventsController.dispose);
    final aiModelManager = AiModelManager();
    addTearDown(aiModelManager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          homesController: homesController,
          alertsController: alertsController,
          eventsController: eventsController,
          aiModelManager: aiModelManager,
        ),
      ),
    );

    // Room tabs are dynamic, sorted alphabetically after All/Favourites.
    expect(find.text('Bedroom'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Living Room'),
      find.byKey(const Key('DASH-008')),
      const Offset(-200, 0),
    );
    await tester.tap(find.text('Living Room'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('DASH-005-Living Room')), findsOneWidget);
    expect(find.text('Front Door Cam'), findsOneWidget);
    expect(find.text('Living Room Cam'), findsOneWidget);
    expect(find.text('Bedroom Cam'), findsNothing);
  });

  testWidgets('Manage homes screen can add a home', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ManageHomesScreen(homesController: homesController)),
    );

    expect(find.text('Main House'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);

    await tester.tap(find.byKey(const Key('HOMES-005')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cabin');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Cabin'), findsOneWidget);
    expect(homesController.value.homes, hasLength(3));
  });

  testWidgets('Manage homes screen expands a home to add and rename a room', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ManageHomesScreen(homesController: homesController)),
    );

    // Office starts with a single "Living Room" room.
    await tester.tap(find.byKey(const Key('HOMES-006-home-2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('HOMES-007-home-2-Living Room')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('HOMES-010-home-2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Storage');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('HOMES-007-home-2-Storage')), findsOneWidget);

    await tester.tap(find.byKey(const Key('HOMES-008-home-2-Storage')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Store Room');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('HOMES-007-home-2-Store Room')),
      findsOneWidget,
    );
    expect(
      homesController.value.homes
          .firstWhere((home) => home.id == 'home-2')
          .rooms,
      containsAll(['Living Room', 'Store Room']),
    );
  });

  test(
    'HomesController enforces the max homes and max rooms per home limits',
    () {
      final homesController = HomesController();
      addTearDown(homesController.dispose);

      for (var i = 0; i < maxHomes + 5; i++) {
        homesController.addHome('Home $i');
      }
      expect(homesController.value.homes, hasLength(maxHomes));
      expect(homesController.canAddHome, isFalse);

      final homeId = homesController.value.homes.first.id;
      for (var i = 0; i < maxRoomsPerHome + 5; i++) {
        homesController.addRoom(homeId, 'Room $i');
      }
      final home = homesController.value.homes.firstWhere(
        (home) => home.id == homeId,
      );
      expect(home.rooms, hasLength(maxRoomsPerHome));
      expect(homesController.canAddRoom(homeId), isFalse);
    },
  );

  testWidgets('Scanning popup shows a spinner then dismisses itself', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scanningPopupOpenerApp());
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.byKey(const Key('SCAN-001')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('SCAN-001')), findsNothing);
  });

  testWidgets('Scanned devices screen shows a results list', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ScannedDevicesScreen(homesController: homesController)),
    );

    expect(find.byKey(const Key('SCAN-004')), findsOneWidget);
  });

  testWidgets(
    'Scanned devices screen can add a configured camera with a room',
    (WidgetTester tester) async {
      final homesController = HomesController();
      addTearDown(homesController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ScannedDevicesScreen(homesController: homesController),
        ),
      );

      final camerasBefore = homesController.value.selectedHome.cameras.length;

      // Keep retrying a scan until a configured camera shows up (results are
      // randomised), then tap it — configured cameras skip straight to the
      // setup form.
      while (!find.text('Configured').evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('SCAN-006')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await tester.tap(find.text('Configured').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('SCAN-010')), findsOneWidget);

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(
        homesController.value.selectedHome.cameras.length,
        camerasBefore + 1,
      );
    },
  );

  testWidgets(
    'Scanned devices screen walks an unconfigured camera through default credentials',
    (WidgetTester tester) async {
      final homesController = HomesController();
      addTearDown(homesController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ScannedDevicesScreen(homesController: homesController),
        ),
      );

      final camerasBefore = homesController.value.selectedHome.cameras.length;

      while (!find.text('Unconfigured').evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('SCAN-006')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await tester.tap(find.text('Unconfigured').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('SCAN-007')), findsOneWidget);
      await tester.tap(find.text('Connect with default credentials'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('SCAN-010')), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(
        homesController.value.selectedHome.cameras.length,
        camerasBefore + 1,
      );
    },
  );

  testWidgets(
    'Scanned devices screen requires matching passwords for change-credentials path',
    (WidgetTester tester) async {
      final homesController = HomesController();
      addTearDown(homesController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ScannedDevicesScreen(homesController: homesController),
        ),
      );

      final camerasBefore = homesController.value.selectedHome.cameras.length;

      while (!find.text('Unconfigured').evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('SCAN-006')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await tester.tap(find.text('Unconfigured').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change credentials'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('SCAN-010')), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(1), 'newpass1');
      await tester.enterText(passwordFields.at(2), 'newpass2');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(homesController.value.selectedHome.cameras.length, camerasBefore);
    },
  );
}

Widget _scanningPopupOpenerApp() {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showScanningPopup(context),
              child: const Text('Open'),
            ),
          ),
        );
      },
    ),
  );
}
