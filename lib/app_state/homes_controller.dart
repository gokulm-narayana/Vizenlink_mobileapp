import 'package:flutter/foundation.dart';

import '../models/camera.dart';
import '../models/home.dart';

const maxHomes = 10;
const maxRoomsPerHome = 10;

class HomesState {
  const HomesState({required this.homes, required this.selectedHomeId});

  final List<Home> homes;
  final String selectedHomeId;

  Home get selectedHome =>
      homes.firstWhere((home) => home.id == selectedHomeId);

  HomesState copyWith({List<Home>? homes, String? selectedHomeId}) {
    return HomesState(
      homes: homes ?? this.homes,
      selectedHomeId: selectedHomeId ?? this.selectedHomeId,
    );
  }
}

class HomesController extends ValueNotifier<HomesState> {
  HomesController() : super(_seedState());

  static String _thumbnailFor(String seed) =>
      'https://picsum.photos/seed/$seed/480/270';

  static HomesState _seedState() {
    final homes = [
      Home(
        id: 'home-1',
        name: 'Main House',
        rooms: const [
          'Living Room',
          'Backyard',
          'Garage',
          'Kitchen',
          'Bedroom',
        ],
        cameras: const [],
      ),
      Home(
        id: 'home-2',
        name: 'Office',
        rooms: const ['Living Room'],
        cameras: const [],
      ),
    ];
    return HomesState(homes: homes, selectedHomeId: 'home-1');
  }

  void selectHome(String homeId) {
    value = value.copyWith(selectedHomeId: homeId);
  }

  void renameCamera(String homeId, String cameraId, String newName) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(name: newName)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void updateCameraWifi(String homeId, String cameraId, String wifiNetwork) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(wifiNetwork: wifiNetwork)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void updateCameraTimezone(String homeId, String cameraId, String timezone) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(timezone: timezone)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  /// Generic camera-settings persistence: finds [cameraId] across all homes
  /// (no need for the caller to know which home it belongs to) and replaces
  /// it with `transform(current)`. Used by the settings screens whose saved
  /// values don't yet drive anything visible (no real CCTV stream — see
  /// CLAUDE.md) but should still be durable, so a future real stream only
  /// needs to read these `Camera` fields, not add new plumbing.
  void updateCamera(
    String cameraId,
    Camera Function(Camera current) transform,
  ) {
    final updated = [
      for (final home in value.homes)
        home.copyWith(
          cameras: [
            for (final camera in home.cameras)
              if (camera.id == cameraId) transform(camera) else camera,
          ],
        ),
    ];
    value = value.copyWith(homes: updated);
  }

  void updateCameraOsdSettings(
    String homeId,
    String cameraId, {
    required bool bitrateOsdEnabled,
    required OsdCorner bitrateOsdPosition,
    required bool signalStrengthOsdEnabled,
    required OsdCorner signalStrengthOsdPosition,
    required bool liveTagOsdEnabled,
  }) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(
                    bitrateOsdEnabled: bitrateOsdEnabled,
                    bitrateOsdPosition: bitrateOsdPosition,
                    signalStrengthOsdEnabled: signalStrengthOsdEnabled,
                    signalStrengthOsdPosition: signalStrengthOsdPosition,
                    liveTagOsdEnabled: liveTagOsdEnabled,
                  )
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  /// Moves a camera from [fromHomeId] to [toHomeId], optionally assigning it
  /// to [room] in the destination home. If [toHomeId] equals [fromHomeId]
  /// this just reassigns the room within the same home.
  void moveCameraToHome({
    required String fromHomeId,
    required String toHomeId,
    required String cameraId,
    String? room,
  }) {
    if (fromHomeId == toHomeId) {
      final updated = [
        for (final home in value.homes)
          if (home.id == fromHomeId)
            home.copyWith(
              cameras: [
                for (final camera in home.cameras)
                  if (camera.id == cameraId)
                    camera.copyWith(room: room, setRoom: true)
                  else
                    camera,
              ],
            )
          else
            home,
      ];
      value = value.copyWith(homes: updated);
      return;
    }

    final sourceHome = value.homes.firstWhere((home) => home.id == fromHomeId);
    final camera = sourceHome.cameras.firstWhere((c) => c.id == cameraId);
    final movedCamera = camera.copyWith(room: room, setRoom: true);

    final updated = [
      for (final home in value.homes)
        if (home.id == fromHomeId)
          home.copyWith(
            cameras: home.cameras.where((c) => c.id != cameraId).toList(),
          )
        else if (home.id == toHomeId)
          home.copyWith(cameras: [...home.cameras, movedCamera])
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void toggleFavorite(String homeId, String cameraId) {
    final updatedHomes = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(isFavorite: !camera.isFavorite)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updatedHomes);
  }

  void togglePin(String homeId, String cameraId) {
    final updatedHomes = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: [
              for (final camera in home.cameras)
                if (camera.id == cameraId)
                  camera.copyWith(isPinned: !camera.isPinned)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updatedHomes);
  }

  /// Moves the camera with [cameraId] to sit immediately before
  /// [beforeCameraId] (or to the end of the list if null) within [homeId]'s
  /// camera order. Used to persist drag-to-reorder from the Dashboard.
  void reorderCamera(String homeId, String cameraId, String? beforeCameraId) {
    final updatedHomes = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: _reordered(home.cameras, cameraId, beforeCameraId),
          )
        else
          home,
    ];
    value = value.copyWith(homes: updatedHomes);
  }

  static List<Camera> _reordered(
    List<Camera> cameras,
    String cameraId,
    String? beforeCameraId,
  ) {
    final moved = cameras.firstWhere((camera) => camera.id == cameraId);
    final remaining = cameras.where((camera) => camera.id != cameraId).toList();
    final insertIndex = beforeCameraId == null
        ? remaining.length
        : remaining.indexWhere((camera) => camera.id == beforeCameraId);
    remaining.insert(insertIndex == -1 ? remaining.length : insertIndex, moved);
    return remaining;
  }

  bool get canAddHome => value.homes.length < maxHomes;

  void addHome(String name) {
    if (!canAddHome) return;
    final newHome = Home(
      id: 'home-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
    );
    value = value.copyWith(homes: [...value.homes, newHome]);
  }

  void renameHome(String homeId, String newName) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId) home.copyWith(name: newName) else home,
    ];
    value = value.copyWith(homes: updated);
  }

  void deleteHome(String homeId) {
    if (value.homes.length <= 1) return;
    final remaining = value.homes.where((home) => home.id != homeId).toList();
    final selectedHomeId = value.selectedHomeId == homeId
        ? remaining.first.id
        : value.selectedHomeId;
    value = HomesState(homes: remaining, selectedHomeId: selectedHomeId);
  }

  bool canAddRoom(String homeId) {
    final home = value.homes.firstWhere((home) => home.id == homeId);
    return home.rooms.length < maxRoomsPerHome;
  }

  void addCamera(
    String homeId, {
    required String name,
    String? room,
    required bool isOnline,
    String? host,
    String? username,
    String? password,
  }) {
    final cameraId = 'cam-${DateTime.now().microsecondsSinceEpoch}';
    final newCamera = Camera(
      id: cameraId,
      name: name,
      isOnline: isOnline,
      room: room,
      thumbnailUrl: _thumbnailFor(cameraId),
      host: host,
      username: username,
      password: password,
      ipAddress: host ?? '—',
    );
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(cameras: [...home.cameras, newCamera])
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void addRoom(String homeId, String roomName) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId &&
            home.rooms.length < maxRoomsPerHome &&
            !home.rooms.contains(roomName))
          home.copyWith(rooms: [...home.rooms, roomName])
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void renameRoom(String homeId, String oldName, String newName) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            rooms: [
              for (final room in home.rooms) room == oldName ? newName : room,
            ],
            cameras: [
              for (final camera in home.cameras)
                if (camera.room == oldName)
                  camera.copyWith(room: newName, setRoom: true)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void deleteCamera(String homeId, String cameraId) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            cameras: home.cameras
                .where((camera) => camera.id != cameraId)
                .toList(),
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }

  void deleteRoom(String homeId, String roomName) {
    final updated = [
      for (final home in value.homes)
        if (home.id == homeId)
          home.copyWith(
            rooms: home.rooms.where((room) => room != roomName).toList(),
            cameras: [
              for (final camera in home.cameras)
                if (camera.room == roomName)
                  camera.copyWith(setRoom: true)
                else
                  camera,
            ],
          )
        else
          home,
    ];
    value = value.copyWith(homes: updated);
  }
}
