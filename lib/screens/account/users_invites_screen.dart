import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera_access_scope.dart';
import '../../models/member_role.dart';
import '../../utils/date_format.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'camera_access_screen.dart';
import 'create_user_screen.dart';
import 'invite_user_screen.dart';

enum _AddUserChoice { invite, create }

class _Member {
  _Member({required this.name, required this.role, this.isCurrentUser = false});

  final String name;
  MemberRole role;
  final bool isCurrentUser;
  DateTime? expiresAt;
  CameraAccessScope cameraAccess = const CameraAccessScope();
}

class _Invite {
  _Invite({
    required this.contact,
    required this.role,
    this.expiresAt,
    this.cameraAccess = const CameraAccessScope(),
  });

  final String contact;
  final MemberRole role;
  final DateTime? expiresAt;
  final CameraAccessScope cameraAccess;
}

/// Users & Invites: account-wide member list (not scoped per-home). No
/// sharing/permissions backend is wired up yet (see CLAUDE.md), so members
/// and invites are static mock data held in local widget state. Roles are
/// informational (Owner / Family Viewer / Temporary Guest) — there's no
/// backend to actually enforce them. Non-Owner members/invites additionally
/// carry a [CameraAccessScope] (all cameras, or an explicit subset), edited
/// via [CameraAccessScreen], plus an expiry date for Temporary Guest.
class UsersInvitesScreen extends StatefulWidget {
  const UsersInvitesScreen({super.key, required this.homesController});

  static const routeName = 'users-invites';

  final HomesController homesController;

  @override
  State<UsersInvitesScreen> createState() => _UsersInvitesScreenState();
}

class _UsersInvitesScreenState extends State<UsersInvitesScreen> {
  final _members = <_Member>[
    _Member(name: 'Alex Morgan', role: MemberRole.owner, isCurrentUser: true),
    _Member(name: 'Jamie Lee', role: MemberRole.familyViewer),
  ];
  final _invites = <_Invite>[
    _Invite(contact: 'sam.rivera@example.com', role: MemberRole.familyViewer),
  ];

  String _initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();

  String _memberSubtitle(_Member member) {
    final role = memberRoleLabels[member.role]!;
    if (member.role == MemberRole.temporaryGuest && member.expiresAt != null) {
      return '$role · Expires ${formatDate(member.expiresAt!)}';
    }
    return role;
  }

  bool get _hasSingleOwner =>
      _members.where((m) => m.role == MemberRole.owner).length <= 1;

  int get _totalCameraCount =>
      widget.homesController.value.homes.expand((home) => home.cameras).length;

  Future<CameraAccessScope?> _editCameraAccess({
    required String memberName,
    required CameraAccessScope currentScope,
  }) {
    return context.push<CameraAccessScope>(
      '${GoRouterState.of(context).matchedLocation}/${CameraAccessScreen.routeName}',
      extra: CameraAccessScreenArgs(
        memberName: memberName,
        initialScope: currentScope,
      ),
    );
  }

  Future<void> _editMemberCameraAccess(_Member member) async {
    final scope = await _editCameraAccess(
      memberName: member.name,
      currentScope: member.cameraAccess,
    );
    if (scope != null) {
      setState(() => member.cameraAccess = scope);
    }
  }

  Future<DateTime?> _pickExpiryDate() {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
  }

  Future<void> _changeMemberRole(_Member member, MemberRole newRole) async {
    if (newRole == MemberRole.temporaryGuest) {
      final expiry = await _pickExpiryDate();
      if (expiry == null) return;
      setState(() {
        member.role = newRole;
        member.expiresAt = expiry;
      });
    } else {
      setState(() {
        member.role = newRole;
        member.expiresAt = null;
      });
    }
  }

  Future<void> _removeMember(_Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member.name} will lose access to all homes and cameras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _members.remove(member));
    }
  }

  void _cancelInvite(_Invite invite) {
    setState(() => _invites.remove(invite));
  }

  Future<void> _showAddUserChoiceDialog() async {
    final choice = await showDialog<_AddUserChoice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Add a user'),
        children: [
          SimpleDialogOption(
            key: const Key('USRINV-014'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_AddUserChoice.invite),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.mail_outline),
              title: Text('Send invite'),
              subtitle: Text(
                'They accept by email/phone; stays Pending until then',
              ),
            ),
          ),
          SimpleDialogOption(
            key: const Key('USRINV-015'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_AddUserChoice.create),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_add_outlined),
              title: Text('Create user'),
              subtitle: Text('Set a name, email, and password directly'),
            ),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case _AddUserChoice.invite:
        _openInviteScreen();
      case _AddUserChoice.create:
        _openCreateUserScreen();
    }
  }

  Future<void> _openInviteScreen() async {
    final result = await context.push<InviteUserResult>(
      '${GoRouterState.of(context).matchedLocation}/${InviteUserScreen.routeName}',
    );
    if (result == null) return;
    setState(() {
      _invites.add(
        _Invite(
          contact: result.contact,
          role: result.role,
          expiresAt: result.expiresAt,
          cameraAccess: result.cameraAccess,
        ),
      );
    });
  }

  Future<void> _openCreateUserScreen() async {
    final result = await context.push<CreateUserResult>(
      '${GoRouterState.of(context).matchedLocation}/${CreateUserScreen.routeName}',
    );
    if (result == null) return;
    setState(() {
      _members.add(
        _Member(name: result.name, role: result.role)
          ..expiresAt = result.expiresAt
          ..cameraAccess = result.cameraAccess,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('USRINV-001'),
          title: const Text('Users & Invites'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('USRINV-009'),
          onPressed: _showAddUserChoiceDialog,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Invite'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Members',
              key: const Key('USRINV-002'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final member in _members) ...[
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('USRINV-003'),
                      leading: CircleAvatar(
                        child: Text(_initialsOf(member.name)),
                      ),
                      title: Text(member.name),
                      subtitle: Text(_memberSubtitle(member)),
                      trailing: member.isCurrentUser
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<MemberRole>(
                                  key: const Key('USRINV-004'),
                                  initialValue: member.role,
                                  onSelected: (role) =>
                                      _changeMemberRole(member, role),
                                  itemBuilder: (context) => [
                                    for (final r in MemberRole.values)
                                      PopupMenuItem(
                                        value: r,
                                        child: Text(
                                          'Make ${memberRoleLabels[r]}',
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  key: const Key('USRINV-005'),
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                  ),
                                  onPressed:
                                      member.role == MemberRole.owner &&
                                          _hasSingleOwner
                                      ? null
                                      : () => _removeMember(member),
                                ),
                              ],
                            ),
                    ),
                    if (member.role != MemberRole.owner)
                      ListTile(
                        key: const Key('USRINV-023'),
                        dense: true,
                        leading: const Icon(Icons.videocam_outlined),
                        title: const Text('Camera access'),
                        subtitle: Text(
                          member.cameraAccess.summary(_totalCameraCount),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _editMemberCameraAccess(member),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_invites.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pending invites',
                key: const Key('USRINV-006'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final invite in _invites) ...[
                GlassCard(
                  child: ListTile(
                    key: const Key('USRINV-007'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(invite.contact),
                    subtitle: Text(
                      invite.role == MemberRole.temporaryGuest &&
                              invite.expiresAt != null
                          ? 'Pending · ${memberRoleLabels[invite.role]} · '
                                'Expires ${formatDate(invite.expiresAt!)}'
                          : 'Pending · ${memberRoleLabels[invite.role]}',
                    ),
                    trailing: IconButton(
                      key: const Key('USRINV-008'),
                      icon: const Icon(Icons.close),
                      onPressed: () => _cancelInvite(invite),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
