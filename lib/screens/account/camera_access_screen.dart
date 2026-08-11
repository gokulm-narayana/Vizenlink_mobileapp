import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera_access_scope.dart';
import '../../models/home.dart';
import '../../widgets/camera_access_checklist.dart';
import '../../widgets/gradient_background.dart';

/// Arguments passed via `extra` when pushing [CameraAccessScreen].
class CameraAccessScreenArgs {
  const CameraAccessScreenArgs({
    required this.memberName,
    required this.initialScope,
  });

  final String memberName;
  final CameraAccessScope initialScope;
}

/// Lets an Owner pick which cameras a Family Viewer / Temporary Guest member
/// can access, reached from the "Camera access" row on [UsersInvitesScreen]'s
/// member list — editing an already-added member, as opposed to the inline
/// camera-access section on [InviteUserScreen]/[CreateUserScreen] (part of
/// filling out that form, not a separate destination). Pushed with a
/// [CameraAccessScreenArgs] via `extra` and pops with the edited
/// [CameraAccessScope], or null if the user backs out without saving. No
/// sharing/permissions backend is wired up yet (see CLAUDE.md) — the
/// returned scope is only held in the caller's local widget state.
class CameraAccessScreen extends StatefulWidget {
  const CameraAccessScreen({
    super.key,
    required this.homesController,
    required this.args,
  });

  static const routeName = 'camera-access';

  final HomesController homesController;
  final CameraAccessScreenArgs args;

  @override
  State<CameraAccessScreen> createState() => _CameraAccessScreenState();
}

class _CameraAccessScreenState extends State<CameraAccessScreen> {
  late bool _allCameras = widget.args.initialScope.allCameras;
  late final Set<String> _selectedCameraIds = {
    ...widget.args.initialScope.cameraIds,
  };

  void _toggleHome(Home home, bool select) {
    setState(() {
      for (final camera in home.cameras) {
        if (select) {
          _selectedCameraIds.add(camera.id);
        } else {
          _selectedCameraIds.remove(camera.id);
        }
      }
    });
  }

  void _toggleCamera(String cameraId, bool select) {
    setState(() {
      if (select) {
        _selectedCameraIds.add(cameraId);
      } else {
        _selectedCameraIds.remove(cameraId);
      }
    });
  }

  void _save() {
    Navigator.of(context).pop(
      CameraAccessScope(
        allCameras: _allCameras,
        cameraIds: _allCameras ? const {} : _selectedCameraIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('CAMACC-001'),
          title: const Text('Camera Access'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'for ${widget.args.memberName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('CAMACC-002'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: CameraAccessChecklist(
              homesController: widget.homesController,
              allCameras: _allCameras,
              selectedCameraIds: _selectedCameraIds,
              onAllCamerasChanged: (value) =>
                  setState(() => _allCameras = value),
              onToggleHome: _toggleHome,
              onToggleCamera: _toggleCamera,
              allCamerasSwitchId: 'CAMACC-003',
              homeSectionId: 'CAMACC-004',
              homeCheckboxId: 'CAMACC-005',
              cameraRowId: 'CAMACC-006',
              emptyStateId: 'CAMACC-007',
            ),
          ),
        ),
      ),
    );
  }
}
