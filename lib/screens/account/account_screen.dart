import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_state/profile_controller.dart';
import '../../app_state/theme_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_button.dart';
import 'account_settings_screen.dart';
import 'help_support_screen.dart';
import 'notification_preferences_screen.dart';
import 'users_invites_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../homes/manage_homes_screen.dart';
import '../login/login_screen.dart';

const _mockAppVersion = 'v1.0.0';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.themeController,
    required this.profileController,
  });

  static const routeName = '/account';

  final ThemeController themeController;
  final ProfileController profileController;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  String _initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();

  Future<void> _showProfileDialog(ProfileData profile) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: profile.avatarImage != null
                    ? Image.file(
                        profile.avatarImage!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      )
                    : CircleAvatar(
                        radius: 110,
                        child: Text(
                          _initialsOf(profile.displayName),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.role,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    widget.profileController.updateAvatarImage(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ACCT-001'),
          title: const Text('Profile'),
          actions: [
            ThemeToggleButton(
              controller: widget.themeController,
              designId: 'ACCT-002',
            ),
          ],
        ),
        body: ValueListenableBuilder<ProfileData>(
          valueListenable: widget.profileController,
          builder: (context, profile, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            key: const Key('ACCT-004'),
                            onTap: () => _showProfileDialog(profile),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundImage: profile.avatarImage != null
                                  ? FileImage(profile.avatarImage!)
                                  : null,
                              child: profile.avatarImage == null
                                  ? Text(_initialsOf(profile.displayName))
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                key: const Key('ACCT-007'),
                                customBorder: const CircleBorder(),
                                onTap: _pickAvatarImage,
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName,
                        key: const Key('ACCT-005'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.role,
                        key: const Key('ACCT-016'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _AccountMenuTile(
                tileKey: const Key('ACCT-008'),
                icon: Icons.lock_outline,
                label: 'Account settings',
                onTap: () => context.push(
                  '${AccountScreen.routeName}/${AccountSettingsScreen.routeName}',
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-009'),
                icon: Icons.home_outlined,
                label: 'Manage Homes',
                onTap: () => context.push(
                  '${DashboardScreen.routeName}/${ManageHomesScreen.routeName}',
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-010'),
                icon: Icons.notifications_outlined,
                label: 'Notification preferences',
                onTap: () => context.push(
                  '${AccountScreen.routeName}/${NotificationPreferencesScreen.routeName}',
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-014'),
                icon: Icons.workspace_premium_outlined,
                label: 'Subscription / Plan',
                onTap: () => _showComingSoon('Subscription / Plan'),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-015'),
                icon: Icons.group_outlined,
                label: 'Users & Invites',
                onTap: () => context.push(
                  '${AccountScreen.routeName}/${UsersInvitesScreen.routeName}',
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-012'),
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () => context.push(
                  '${AccountScreen.routeName}/${HelpSupportScreen.routeName}',
                ),
              ),
              const SizedBox(height: 12),
              _AccountMenuTile(
                tileKey: const Key('ACCT-011'),
                icon: Icons.info_outline,
                label: 'About',
                trailing: Text(
                  _mockAppVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('ACCT-013'),
                onPressed: () => context.go(LoginScreen.routeName),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tileKey,
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon, color: colorScheme.primary),
            title: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing:
                trailing ??
                (onTap != null ? const Icon(Icons.chevron_right) : null),
          ),
        ),
      ),
    );
  }
}
