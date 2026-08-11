import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera_access_scope.dart';
import '../../models/home.dart';
import '../../models/member_role.dart';
import '../../widgets/camera_access_checklist.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/member_access_fields.dart';

/// Result popped by [CreateUserScreen] when "Create" is tapped. Email and
/// password are validated on this screen but not carried in the result —
/// same as the dialog it replaces, there's no auth backend to store them
/// against yet (see CLAUDE.md), so only the fields the Members list actually
/// displays are returned.
class CreateUserResult {
  const CreateUserResult({
    required this.name,
    required this.role,
    this.expiresAt,
    required this.cameraAccess,
  });

  final String name;
  final MemberRole role;
  final DateTime? expiresAt;
  final CameraAccessScope cameraAccess;
}

/// Full-screen "Create user" flow, reached from the "Create user" option on
/// [UsersInvitesScreen]'s add-user choice dialog (replaces the previous
/// popup dialog so there's room for the camera-access checklist). Camera
/// access is edited inline (via [CameraAccessChecklist]) rather than as a
/// separate screen, since it's one field of this form, not its own
/// destination. Pops with a [CreateUserResult], or null if the user backs
/// out. No auth backend is wired up yet (see CLAUDE.md) — the caller adds
/// the result directly to its local Members list (no Pending step, unlike
/// Invite).
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key, required this.homesController});

  static const routeName = 'create-user';

  final HomesController homesController;

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
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
      CreateUserResult(
        name: _nameController.text.trim(),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('CRUSR-001'),
          title: const Text('Create user'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('CRUSR-002'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('CRUSR-003'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('CRUSR-004'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => (value == null || value.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('CRUSR-005'),
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 16),
              RoleSelectorField(
                key: const Key('CRUSR-006'),
                role: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              if (_role == MemberRole.temporaryGuest) ...[
                const SizedBox(height: 4),
                ExpiryDateRow(
                  key: const Key('CRUSR-007'),
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
                  key: const Key('CRUSR-010'),
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
                  allCamerasSwitchId: 'CRUSR-011',
                  homeSectionId: 'CRUSR-012',
                  homeCheckboxId: 'CRUSR-013',
                  cameraRowId: 'CRUSR-014',
                  emptyStateId: 'CRUSR-015',
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('CRUSR-009'),
                onPressed: _submit,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
