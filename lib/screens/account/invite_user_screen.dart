import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera_access_scope.dart';
import '../../models/home.dart';
import '../../models/member_role.dart';
import '../../widgets/camera_access_checklist.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/member_access_fields.dart';

/// Result popped by [InviteUserScreen] when "Send invite" is tapped.
class InviteUserResult {
  const InviteUserResult({
    required this.contact,
    required this.role,
    this.expiresAt,
    required this.cameraAccess,
  });

  final String contact;
  final MemberRole role;
  final DateTime? expiresAt;
  final CameraAccessScope cameraAccess;
}

/// Full-screen "Invite" flow, reached from the "Send invite" option on
/// [UsersInvitesScreen]'s add-user choice dialog (replaces the previous
/// popup dialog so there's room for the camera-access checklist). Camera
/// access is edited inline (via [CameraAccessChecklist]) rather than as a
/// separate screen, since it's one field of this form, not its own
/// destination. Pops with an [InviteUserResult], or null if the user backs
/// out. No sharing/permissions backend is wired up yet (see CLAUDE.md) — the
/// caller only adds the result to its local pending-invites list.
class InviteUserScreen extends StatefulWidget {
  const InviteUserScreen({super.key, required this.homesController});

  static const routeName = 'invite';

  final HomesController homesController;

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _role = MemberRole.familyViewer;
  DateTime? _expiresAt;
  var _allCameras = true;
  final _selectedCameraIds = <String>{};

  Future<DateTime?> _pickExpiryDate() {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
  }

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

  void _submit() {
    if (_role == MemberRole.temporaryGuest && _expiresAt == null) return;
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      InviteUserResult(
        contact: _contactController.text.trim(),
        role: _role,
        expiresAt: _expiresAt,
        cameraAccess: CameraAccessScope(
          allCameras: _allCameras,
          cameraIds: _allCameras ? const {} : _selectedCameraIds,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('INVUSR-001'),
          title: const Text('Invite'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('INVUSR-002'),
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Email or phone number',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              RoleSelectorField(
                key: const Key('INVUSR-003'),
                role: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              if (_role == MemberRole.temporaryGuest) ...[
                const SizedBox(height: 4),
                ExpiryDateRow(
                  key: const Key('INVUSR-004'),
                  expiresAt: _expiresAt,
                  onPick: () async {
                    final picked = await _pickExpiryDate();
                    if (picked != null) setState(() => _expiresAt = picked);
                  },
                ),
              ],
              if (_role != MemberRole.owner) ...[
                const SizedBox(height: 16),
                Text(
                  'Camera access',
                  key: const Key('INVUSR-007'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CameraAccessChecklist(
                  homesController: widget.homesController,
                  allCameras: _allCameras,
                  selectedCameraIds: _selectedCameraIds,
                  onAllCamerasChanged: (value) =>
                      setState(() => _allCameras = value),
                  onToggleHome: _toggleHome,
                  onToggleCamera: _toggleCamera,
                  allCamerasSwitchId: 'INVUSR-008',
                  homeSectionId: 'INVUSR-009',
                  homeCheckboxId: 'INVUSR-010',
                  cameraRowId: 'INVUSR-011',
                  emptyStateId: 'INVUSR-012',
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('INVUSR-006'),
                onPressed: _submit,
                child: const Text('Send invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
