import 'package:auth_api/auth_api.dart';
import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_state/ai_model_manager.dart';
import 'app_state/alerts_controller.dart';
import 'app_state/events_controller.dart';
import 'app_state/homes_controller.dart';
import 'app_state/preview_key_store.dart';
import 'app_state/profile_controller.dart';
import 'app_state/route_observer.dart';
import 'app_state/theme_controller.dart';
import 'models/camera.dart';
import 'models/alert.dart';
import 'models/event.dart';
import 'models/scanned_camera.dart';
import 'screens/account/account_screen.dart';
import 'screens/account/account_settings_screen.dart';
import 'screens/account/active_sessions_screen.dart';
import 'screens/account/camera_access_screen.dart';
import 'screens/account/change_password_screen.dart';
import 'screens/account/create_user_screen.dart';
import 'screens/account/invite_user_screen.dart';
import 'screens/account/notification_preferences_screen.dart';
import 'screens/account/help_support_screen.dart';
import 'screens/account/users_invites_screen.dart';
import 'screens/alerts/alert_detail_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/camera_live/camera_live_screen.dart';
import 'screens/camera_settings/audio_screen.dart';
import 'screens/camera_settings/recording_screen.dart';
import 'screens/camera_settings/storage_screen.dart';
import 'screens/camera_settings/camera_info_screen.dart';
import 'screens/camera_settings/camera_settings_screen.dart';
import 'screens/camera_settings/danger_zone_screen.dart';
import 'screens/camera_settings/detections_screen.dart';
import 'screens/camera_settings/imaging_screen.dart';
import 'screens/camera_settings/intrusion_detection_screen.dart';
import 'screens/camera_settings/line_crossing_screen.dart';
import 'screens/camera_settings/motion_detection_screen.dart';
import 'screens/camera_settings/night_mode_screen.dart';
import 'screens/camera_settings/on_screen_display_screen.dart';
import 'screens/camera_settings/person_detection_screen.dart';
import 'screens/camera_settings/privacy_mode_screen.dart';
import 'screens/camera_settings/tags_screen.dart';
import 'screens/camera_settings/vehicle_detection_screen.dart';
import 'screens/camera_settings/video_display_screen.dart';
import 'screens/camera_settings/video_encoder_screen.dart';
import 'screens/camera_settings/video_mode_screen.dart';
import 'screens/camera_settings/wifi_config_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/events/events_summary_screen.dart';
import 'screens/homes/manage_homes_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/scan/scanned_devices_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/signup/confirm_signup_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/branding.dart';
import 'widgets/navigation_leave_guard.dart';

void main() {
  // Live `vizenlink-mobile` Cognito pool — see packages/auth_api/API_REFERENCE.md
  // § Configuration. Can be overridden at build time via
  // --dart-define=COGNITO_USER_POOL_ID=.../COGNITO_APP_CLIENT_ID=.../COGNITO_IDENTITY_POOL_ID=...
  AuthController.configure(
    const AuthApiConfig(
      region: 'ap-south-1',
      userPoolId: String.fromEnvironment(
        'COGNITO_USER_POOL_ID',
        defaultValue: 'ap-south-1_RKoTtmxCi',
      ),
      appClientId: String.fromEnvironment(
        'COGNITO_APP_CLIENT_ID',
        defaultValue: '28b1gba2nk2oe0v70obu439bu9',
      ),
      identityPoolId: String.fromEnvironment(
        'COGNITO_IDENTITY_POOL_ID',
        defaultValue: 'ap-south-1:5afc6818-10ed-498f-9106-fb190aa44976',
      ),
    ),
  );
  // camera_api's WAN clients (packages/camera_api/lib/src/wan/wan_auth.dart)
  // fall back to these app-wide hooks instead of importing anything
  // app-specific — set once, before the first WAN call.
  WanAuth.idTokenProvider = () => AuthController.instance.session?.idToken;
  // This project's real, live deployed relay (VizenLinkKvsPlaybackProxy,
  // confirmed live 2026-08-12 per packages/camera_api/API_REFERENCE.md
  // "Getting started") — not a placeholder. Overridable via
  // --dart-define=KVS_PLAYBACK_LAMBDA_URL=... if it's ever redeployed at a
  // new Function URL.
  WanAuth.kvsPlaybackLambdaUrl = const String.fromEnvironment(
    'KVS_PLAYBACK_LAMBDA_URL',
    defaultValue:
        'https://jxce73jfkwoouhcmxvhsoysxxq0gavso.lambda-url.ap-south-1.on.aws/',
  );
  // Backs WanPreviewSnapshotClient's decrypt step — see PreviewKeyStore's
  // own doc comment for the full registration/re-registration picture.
  WanAuth.previewPrivateKeyProvider =
      PreviewKeyStore.instance.getExistingPrivateKey;
  WanAuth.onPreviewKeyNeedsRegistration =
      PreviewKeyStore.instance.flagNeedsReregistration;
  runApp(const MobileCctvApp());
}

class MobileCctvApp extends StatefulWidget {
  const MobileCctvApp({super.key});

  @override
  State<MobileCctvApp> createState() => _MobileCctvAppState();
}

class _MobileCctvAppState extends State<MobileCctvApp> {
  final _themeController = ThemeController();
  final _homesController = HomesController();
  final _alertsController = AlertsController();
  final _eventsController = EventsController();
  final _profileController = ProfileController();
  final _navigationGuard = NavigationGuardController();
  final _aiModelManager = AiModelManager();
  late final GoRouter _router;
  late final Future<void> _appReady;

  @override
  void initState() {
    super.initState();
    // The splash stays up for exactly as long as this real background
    // loading takes — no artificial padding. It used to force a fixed
    // 15-second minimum regardless of how fast loading actually finished,
    // making every app launch wait 15s even though this work normally
    // completes in milliseconds.
    _appReady = Future.wait([
      _themeController.load(),
      _aiModelManager.load(),
      _homesController.load(),
      AuthController.instance.restore(),
    ]);
    _router = _buildRouter();
  }

  @override
  void dispose() {
    _themeController.dispose();
    _homesController.dispose();
    _alertsController.dispose();
    _eventsController.dispose();
    _navigationGuard.dispose();
    _aiModelManager.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: SplashScreen.routeName,
      observers: [routeObserver],
      routes: [
        GoRoute(
          path: SplashScreen.routeName,
          builder: (context, state) => SplashScreen(
            appReady: _appReady,
            authController: AuthController.instance,
          ),
        ),
        GoRoute(
          path: LoginScreen.routeName,
          builder: (context, state) =>
              LoginScreen(themeController: _themeController),
        ),
        GoRoute(
          path: SignupScreen.routeName,
          builder: (context, state) =>
              SignupScreen(themeController: _themeController),
        ),
        GoRoute(
          path: ConfirmSignupScreen.routeName,
          builder: (context, state) =>
              ConfirmSignupScreen(args: state.extra as ConfirmSignupArgs),
        ),
        GoRoute(
          path: ForgotPasswordScreen.routeName,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(
            navigationShell: navigationShell,
            alertsController: _alertsController,
            navigationGuard: _navigationGuard,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DashboardScreen.routeName,
                  builder: (context, state) => DashboardScreen(
                    homesController: _homesController,
                    alertsController: _alertsController,
                    eventsController: _eventsController,
                    aiModelManager: _aiModelManager,
                  ),
                  routes: [
                    GoRoute(
                      path: 'homes/manage',
                      builder: (context, state) =>
                          ManageHomesScreen(homesController: _homesController),
                    ),
                    GoRoute(
                      path: ScannedDevicesScreen.routeName,
                      builder: (context, state) => ScannedDevicesScreen(
                        homesController: _homesController,
                        initialResults: state.extra as List<ScannedCamera>?,
                      ),
                    ),
                    GoRoute(
                      path: '${CameraLiveScreen.routeName}/:cameraId',
                      builder: (context, state) => CameraLiveScreen(
                        camera: state.extra as Camera,
                        homesController: _homesController,
                      ),
                      routes: [
                        GoRoute(
                          path: CameraSettingsScreen.routeName,
                          builder: (context, state) => CameraSettingsScreen(
                            camera: state.extra as Camera,
                            homesController: _homesController,
                          ),
                          routes: [
                            GoRoute(
                              path: CameraInfoScreen.routeName,
                              builder: (context, state) => CameraInfoScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                              routes: [
                                GoRoute(
                                  path: WifiConfigScreen.routeName,
                                  builder: (context, state) => WifiConfigScreen(
                                    camera: state.extra as Camera,
                                    homesController: _homesController,
                                  ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: VideoDisplayScreen.routeName,
                              builder: (context, state) => VideoDisplayScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                              routes: [
                                GoRoute(
                                  path: VideoModeScreen.routeName,
                                  builder: (context, state) => VideoModeScreen(
                                    camera: state.extra as Camera,
                                    homesController: _homesController,
                                  ),
                                ),
                                GoRoute(
                                  path: NightModeScreen.routeName,
                                  builder: (context, state) => NightModeScreen(
                                    camera: state.extra as Camera,
                                    homesController: _homesController,
                                  ),
                                ),
                                GoRoute(
                                  path: PrivacyModeScreen.routeName,
                                  builder: (context, state) =>
                                      PrivacyModeScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: OnScreenDisplayScreen.routeName,
                                  builder: (context, state) =>
                                      OnScreenDisplayScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: ImagingScreen.routeName,
                                  builder: (context, state) => ImagingScreen(
                                    camera: state.extra as Camera,
                                    homesController: _homesController,
                                  ),
                                ),
                                GoRoute(
                                  path: VideoEncoderScreen.routeName,
                                  builder: (context, state) =>
                                      VideoEncoderScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: TagsScreen.routeName,
                                  builder: (context, state) => TagsScreen(
                                    camera: state.extra as Camera,
                                    homesController: _homesController,
                                  ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: DetectionsScreen.routeName,
                              builder: (context, state) => DetectionsScreen(
                                camera: state.extra as Camera,
                              ),
                              routes: [
                                GoRoute(
                                  path: MotionDetectionScreen.routeName,
                                  builder: (context, state) =>
                                      MotionDetectionScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: IntrusionDetectionScreen.routeName,
                                  builder: (context, state) =>
                                      IntrusionDetectionScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: LineCrossingScreen.routeName,
                                  builder: (context, state) =>
                                      LineCrossingScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: PersonDetectionScreen.routeName,
                                  builder: (context, state) =>
                                      PersonDetectionScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                                GoRoute(
                                  path: VehicleDetectionScreen.routeName,
                                  builder: (context, state) =>
                                      VehicleDetectionScreen(
                                        camera: state.extra as Camera,
                                        homesController: _homesController,
                                      ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: AudioScreen.routeName,
                              builder: (context, state) => AudioScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                            ),
                            GoRoute(
                              path: RecordingScreen.routeName,
                              builder: (context, state) => RecordingScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                            ),
                            GoRoute(
                              path: StorageScreen.routeName,
                              builder: (context, state) => StorageScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                            ),
                            GoRoute(
                              path: DangerZoneScreen.routeName,
                              builder: (context, state) => DangerZoneScreen(
                                camera: state.extra as Camera,
                                homesController: _homesController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AlertsScreen.routeName,
                  builder: (context, state) {
                    final extra = state.extra;
                    final filter = extra is (String, AlertType, bool)
                        ? extra
                        : null;
                    return AlertsScreen(
                      alertsController: _alertsController,
                      homesController: _homesController,
                      initialCameraFilter: filter?.$1,
                      initialTypeFilter: filter?.$2,
                      initialUnreadOnly: filter?.$3 ?? false,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: AlertDetailScreen.routeName,
                      builder: (context, state) => AlertDetailScreen(
                        alert: state.extra as Alert,
                        alertsController: _alertsController,
                        homesController: _homesController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: EventsScreen.routeName,
                  builder: (context, state) =>
                      EventsScreen(eventsController: _eventsController),
                  routes: [
                    GoRoute(
                      path: EventsSummaryScreen.routeName,
                      builder: (context, state) => EventsSummaryScreen(
                        args: state.extra as EventsSummaryArgs,
                      ),
                    ),
                    GoRoute(
                      path: EventDetailScreen.routeName,
                      builder: (context, state) => EventDetailScreen(
                        event: state.extra as RecordedEvent,
                        eventsController: _eventsController,
                        homesController: _homesController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AccountScreen.routeName,
                  builder: (context, state) => AccountScreen(
                    themeController: _themeController,
                    profileController: _profileController,
                  ),
                  routes: [
                    GoRoute(
                      path: AccountSettingsScreen.routeName,
                      builder: (context, state) => AccountSettingsScreen(
                        profileController: _profileController,
                      ),
                      routes: [
                        GoRoute(
                          path: ActiveSessionsScreen.routeName,
                          builder: (context, state) =>
                              const ActiveSessionsScreen(),
                        ),
                        GoRoute(
                          path: ChangePasswordScreen.routeName,
                          builder: (context, state) =>
                              const ChangePasswordScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: NotificationPreferencesScreen.routeName,
                      builder: (context, state) =>
                          const NotificationPreferencesScreen(),
                    ),
                    GoRoute(
                      path: UsersInvitesScreen.routeName,
                      builder: (context, state) =>
                          UsersInvitesScreen(homesController: _homesController),
                      routes: [
                        GoRoute(
                          path: CameraAccessScreen.routeName,
                          builder: (context, state) => CameraAccessScreen(
                            homesController: _homesController,
                            args: state.extra as CameraAccessScreenArgs,
                          ),
                        ),
                        GoRoute(
                          path: InviteUserScreen.routeName,
                          builder: (context, state) => InviteUserScreen(
                            homesController: _homesController,
                          ),
                        ),
                        GoRoute(
                          path: CreateUserScreen.routeName,
                          builder: (context, state) => CreateUserScreen(
                            homesController: _homesController,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: HelpSupportScreen.routeName,
                      builder: (context, state) => const HelpSupportScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeController,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: kAppBrandName,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: _router,
        );
      },
    );
  }
}
