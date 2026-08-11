import 'package:flutter/material.dart';

import '../app_state/homes_controller.dart';
import '../models/home.dart';
import 'glass_card.dart';

/// "All cameras" switch + per-home/per-camera checklist, shared by
/// [CameraAccessScreen] (its own screen, editing an existing member) and the
/// inline "Camera access" section on [InviteUserScreen]/[CreateUserScreen]
/// (part of the same form, no extra navigation). Purely presentational —
/// [allCameras]/[selectedCameraIds] are owned by the caller, which re-renders
/// this widget after applying a callback.
///
/// Design IDs are supplied by the caller (each embedding screen assigns its
/// own `SCREEN-PREFIX-NNN` ids), since the same widget backs different
/// screens' element inventories.
class CameraAccessChecklist extends StatelessWidget {
  const CameraAccessChecklist({
    super.key,
    required this.homesController,
    required this.allCameras,
    required this.selectedCameraIds,
    required this.onAllCamerasChanged,
    required this.onToggleHome,
    required this.onToggleCamera,
    required this.allCamerasSwitchId,
    required this.homeSectionId,
    required this.homeCheckboxId,
    required this.cameraRowId,
    required this.emptyStateId,
  });

  final HomesController homesController;
  final bool allCameras;
  final Set<String> selectedCameraIds;
  final ValueChanged<bool> onAllCamerasChanged;
  final void Function(Home home, bool select) onToggleHome;
  final void Function(String cameraId, bool select) onToggleCamera;
  final String allCamerasSwitchId;
  final String homeSectionId;
  final String homeCheckboxId;
  final String cameraRowId;
  final String emptyStateId;

  bool? _homeTristate(Home home) {
    if (home.cameras.isEmpty) return false;
    final selectedCount = home.cameras
        .where((camera) => selectedCameraIds.contains(camera.id))
        .length;
    if (selectedCount == 0) return false;
    if (selectedCount == home.cameras.length) return true;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomesState>(
      valueListenable: homesController,
      builder: (context, state, _) {
        if (state.homes.isEmpty) {
          return Center(
            key: Key(emptyStateId),
            child: Text(
              'No homes or cameras yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            GlassCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                key: Key(allCamerasSwitchId),
                title: const Text('All cameras'),
                subtitle: const Text(
                  'Includes cameras added to any home later',
                ),
                value: allCameras,
                onChanged: onAllCamerasChanged,
              ),
            ),
            const SizedBox(height: 12),
            for (final home in state.homes) ...[
              GlassCard(
                padding: EdgeInsets.zero,
                child: Material(
                  type: MaterialType.transparency,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key('$homeSectionId-${home.id}'),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(home.name),
                      subtitle: Text('${home.cameras.length} camera(s)'),
                      leading: Checkbox(
                        key: Key('$homeCheckboxId-${home.id}'),
                        tristate: true,
                        value: allCameras ? true : _homeTristate(home),
                        onChanged: allCameras
                            ? null
                            : (value) => onToggleHome(home, value ?? true),
                      ),
                      children: [
                        for (final camera in home.cameras)
                          CheckboxListTile(
                            key: Key('$cameraRowId-${camera.id}'),
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 24,
                              right: 16,
                            ),
                            title: Text(camera.name),
                            value: allCameras
                                ? true
                                : selectedCameraIds.contains(camera.id),
                            onChanged: allCameras
                                ? null
                                : (value) =>
                                      onToggleCamera(camera.id, value ?? false),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
