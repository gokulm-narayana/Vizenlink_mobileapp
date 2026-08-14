import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobilecctvapp/app_state/ai_model_manager.dart';
import 'package:mobilecctvapp/app_state/alerts_controller.dart';
import 'package:mobilecctvapp/app_state/events_controller.dart';
import 'package:mobilecctvapp/app_state/homes_controller.dart';
import 'package:mobilecctvapp/main.dart';
import 'package:mobilecctvapp/models/camera.dart';
import 'package:mobilecctvapp/models/scanned_camera.dart';
import 'package:mobilecctvapp/screens/dashboard/dashboard_screen.dart';
import 'package:mobilecctvapp/screens/homes/manage_homes_screen.dart';
import 'package:mobilecctvapp/screens/scan/scanned_devices_screen.dart';
import 'package:mobilecctvapp/screens/scan/scanning_popup.dart';

/// Seeds `homesController`'s "Main House" (`home-1`) with three demo
/// cameras matching what the Dashboard tests below assert on. Replaces the
/// hardcoded seed-data cameras `HomesController._seedState()` used to ship
/// with — removed once real camera scanning replaced fake demo data, which
/// left these tests with no cameras to find. Returns the added cameras in
/// (front door, living room, bedroom) order — real ids are timestamp-based
/// (`HomesController.addCamera`), not the old hardcoded `cam-1`/etc., so
/// callers needing a specific camera's key must use the returned `Camera`,
/// not a literal id string.
List<Camera> _seedDemoCameras(HomesController homesController) {
  final frontDoor = homesController.addCamera(
    'home-1',
    name: 'Front Door Cam',
    room: 'Living Room',
    isOnline: true,
  );
  homesController.toggleFavorite('home-1', frontDoor.id);
  final livingRoom = homesController.addCamera(
    'home-1',
    name: 'Living Room Cam',
    room: 'Living Room',
    isOnline: true,
  );
  // Also favourited, so it's still expected in the Favourites tab after the
  // Favourites test un-favourites Front Door Cam.
  homesController.toggleFavorite('home-1', livingRoom.id);
  final bedroom = homesController.addCamera(
    'home-1',
    name: 'Bedroom Cam',
    room: 'Bedroom',
    isOnline: true,
  );
  return [frontDoor, livingRoom, bedroom];
}

/// Fixed (non-randomised) stand-in for a real `scanForCameras()` LAN
/// discovery pass — one "Configured" and one "Unconfigured" result, which
/// is everything `ScannedDevicesScreen`'s own tests below tap through.
/// Passed as `ScannedDevicesScreen.scan` so those tests don't depend on
/// real network hardware (unavailable in a sandboxed test environment —
/// see `scan_cameras_screen.md`'s Notes) or a flaky retry-until-found loop.
Future<List<ScannedCamera>> _fakeScanResults() async => const [
  ScannedCamera(
    id: '192.168.1.50',
    name: 'Camera at 192.168.1.50',
    ipAddress: '192.168.1.50',
    isConfigured: true,
  ),
  ScannedCamera(
    id: '192.168.1.51',
    name: 'VZL-CAM',
    ipAddress: '192.168.1.51',
    isConfigured: false,
  ),
];

/// A `MockClient` standing in for the real camera during the setup form's
/// "Connect" credential verification (`OnvifDeviceClient.
/// getDeviceInformation`/`getSerialNumber`/`getNetworkInterfaceInfo`/
/// `getDeviceIdentity`) — passed as `ScannedDevicesScreen.httpClient`.
/// Response shapes match `packages/camera_api/test/onvif_device_client_test
/// .dart`'s own fixtures for the same calls. Only `GetDeviceInformation`'s
/// response actually matters for these tests (it's what gates whether
/// "Connect" succeeds) — the other three are best-effort enrichment calls
/// that don't block adding the camera even if left generic/empty.
http.Client _mockOnvifDeviceHttpClient() => MockClient((request) async {
  const envelopeOpen =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body>';
  const envelopeClose = '</s:Body></s:Envelope>';

  if (request.body.contains('GetDeviceInformation')) {
    return http.Response(
      '$envelopeOpen'
      '<tds:GetDeviceInformationResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl">'
      '<tds:Manufacturer>VizenLink</tds:Manufacturer>'
      '<tds:Model>VZL-CAM</tds:Model>'
      '<tds:FirmwareVersion>1.0.0</tds:FirmwareVersion>'
      '<tds:SerialNumber>VZL-CAM-000001</tds:SerialNumber>'
      '<tds:HardwareId>HW-VZL-DEV-A</tds:HardwareId>'
      '</tds:GetDeviceInformationResponse>'
      '$envelopeClose',
      200,
    );
  }
  if (request.body.contains('GetNetworkInterfaces')) {
    return http.Response(
      '$envelopeOpen'
      '<tds:GetNetworkInterfacesResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl">'
      '<tds:Name>eth</tds:Name>'
      '<tds:HwAddress>00:11:22:33:44:55</tds:HwAddress>'
      '<tds:Address>192.168.1.50</tds:Address>'
      '</tds:GetNetworkInterfacesResponse>'
      '$envelopeClose',
      200,
    );
  }
  if (request.body.contains('GetScopes')) {
    return http.Response(
      '$envelopeOpen'
      '<tds:GetScopesResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>'
      '$envelopeClose',
      200,
    );
  }
  return http.Response('$envelopeOpen$envelopeClose', 200);
});

/// `CameraCredentialsStore` (backing `HomesController`'s camera passwords)
/// talks to `flutter_secure_storage`'s platform channel, which has no
/// implementation registered in the test environment — without a mock
/// handler, every call hangs instead of throwing, which stalls
/// `pumpAndSettle`. Mirrors `SharedPreferences.setMockInitialValues` below
/// for the same reason.
void _mockSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>();
        switch (call.method) {
          case 'write':
            store[args!['key'] as String] = args['value'] as String;
            return null;
          case 'read':
            return store[args!['key'] as String];
          case 'readAll':
            return store;
          case 'delete':
            store.remove(args!['key'] as String);
            return null;
          case 'deleteAll':
            store.clear();
            return null;
          case 'containsKey':
            return store.containsKey(args!['key'] as String);
          default:
            return null;
        }
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AiModelManager/ThemeController.load() both call
  // SharedPreferences.getInstance(), which never resolves in a test
  // environment without a mock store — SplashScreen (the app's initial
  // route) waits on both before navigating to the dashboard, so every test
  // that pumps the full app needs this.
  SharedPreferences.setMockInitialValues({});
  _mockSecureStorageChannel();

  testWidgets('Splash routes to login when no session is restored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MobileCctvApp());
    // The splash screen waits on app startup (theme/AI-consent/homes
    // loading, plus AuthController.restore()) before routing — no more
    // fixed minimum delay to pump through, just real (mocked)
    // SharedPreferences/secure-storage reads. With no persisted session
    // (mocked secure storage starts empty), it lands on Login, not
    // Dashboard — the app is now gated on a real auth_api session.
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('LOGIN-001')), findsOneWidget);
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
    final cameras = _seedDemoCameras(homesController);
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
    expect(find.byKey(Key('DASH-006-${cameras[0].id}')), findsOneWidget);
  });

  testWidgets('Dashboard Favourites tab reflects favourite toggles', (
    WidgetTester tester,
  ) async {
    final homesController = HomesController();
    addTearDown(homesController.dispose);
    final cameras = _seedDemoCameras(homesController);
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

    // Front Door Cam starts favourited (see _seedDemoCameras); un-favourite
    // it from the All tab via the long-press actions menu.
    await tester.longPress(find.byKey(Key('DASH-006-${cameras[0].id}')));
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
    _seedDemoCameras(homesController);
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
      MaterialApp(
        home: ScannedDevicesScreen(
          homesController: homesController,
          scan: _fakeScanResults,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('SCAN-004')), findsOneWidget);
  });

  testWidgets(
    'Scanned devices screen can add a configured camera with a room',
    (WidgetTester tester) async {
      final homesController = HomesController();
      addTearDown(homesController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ScannedDevicesScreen(
            homesController: homesController,
            scan: _fakeScanResults,
            httpClient: _mockOnvifDeviceHttpClient(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final camerasBefore = homesController.value.selectedHome.cameras.length;

      // Configured cameras skip straight to the setup form.
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
          home: ScannedDevicesScreen(
            homesController: homesController,
            scan: _fakeScanResults,
            httpClient: _mockOnvifDeviceHttpClient(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final camerasBefore = homesController.value.selectedHome.cameras.length;

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
          home: ScannedDevicesScreen(
            homesController: homesController,
            scan: _fakeScanResults,
            httpClient: _mockOnvifDeviceHttpClient(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final camerasBefore = homesController.value.selectedHome.cameras.length;

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
