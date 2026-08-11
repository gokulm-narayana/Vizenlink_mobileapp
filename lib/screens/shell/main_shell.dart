import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/alerts_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/navigation_leave_guard.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.alertsController,
    required this.navigationGuard,
  });

  final StatefulNavigationShell navigationShell;
  final AlertsController alertsController;
  final NavigationGuardController navigationGuard;

  static const _destinations = [
    _ShellDestination(
      key: 'SHELL-002',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _ShellDestination(
      key: 'SHELL-003',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
      showsUnreadBadge: true,
    ),
    _ShellDestination(
      key: 'SHELL-004',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      label: 'Events',
    ),
    _ShellDestination(
      key: 'SHELL-005',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationGuardScope(
      controller: navigationGuard,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: navigationShell,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GlassCard(
                key: const Key('SHELL-001'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < _destinations.length; i++)
                      _ShellNavItem(
                        destination: _destinations[i],
                        selected: navigationShell.currentIndex == i,
                        alertsController: alertsController,
                        onTap: () => navigationGuard.confirmLeave().then((ok) {
                          if (ok) {
                            navigationShell.goBranch(
                              i,
                              initialLocation:
                                  navigationShell.currentIndex == i,
                            );
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showsUnreadBadge = false,
  });

  final String key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool showsUnreadBadge;
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.destination,
    required this.selected,
    required this.alertsController,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final AlertsController alertsController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        key: Key(destination.key),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    if (destination.showsUnreadBadge)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: ValueListenableBuilder(
                          valueListenable: alertsController,
                          builder: (context, alerts, _) {
                            final hasUnread = alertsController.unreadCount > 0;
                            if (!hasUnread) return const SizedBox.shrink();
                            return Container(
                              key: const Key('SHELL-006'),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkMid
                                      : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
