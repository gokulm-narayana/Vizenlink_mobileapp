import 'package:flutter/material.dart';

/// App-wide `RouteObserver`, registered on the `GoRouter` in `main.dart` —
/// lets any screen mix in `RouteAware` to find out when it's been covered
/// by a route pushed on top of it (`didPushNext`) or uncovered again
/// (`didPopNext`), as opposed to actually disposed. `CameraLiveScreen` uses
/// this to pause its live WebRTC/WAN session while a settings sub-screen is
/// pushed on top of it — without this, `context.push` leaves the Live
/// screen (and its stream) mounted and running underneath, just not
/// visible, which the app was still doing before this was added (a real
/// complaint: the stream/audio kept running while browsing Camera
/// Settings).
final routeObserver = RouteObserver<PageRoute<void>>();
