import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final role =
        ref.watch(authNotifierProvider).valueOrNull?.role ?? UserRole.socio;

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentLocation: location, role: role),
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

List<_TabConfig> _tabsForRole(UserRole role) => switch (role) {
      UserRole.admin => const [
          _TabConfig(
            path: '/feed',
            icon: Icons.dynamic_feed_outlined,
            activeIcon: Icons.dynamic_feed,
            label: 'Feed',
          ),
          _TabConfig(
            path: '/events',
            icon: Icons.event_outlined,
            activeIcon: Icons.event,
            label: 'Eventos',
          ),
          _TabConfig(
            path: '/ranking',
            icon: Icons.leaderboard_outlined,
            activeIcon: Icons.leaderboard,
            label: 'Ranking',
          ),
          _TabConfig(
            path: '/trainings',
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Entrenos',
          ),
          _TabConfig(
            path: '/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
          ),
        ],
      UserRole.entrenador => const [
          _TabConfig(
            path: '/trainings',
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Entrenos',
          ),
          _TabConfig(
            path: '/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
          ),
        ],
      UserRole.socio => const [
          _TabConfig(
            path: '/feed',
            icon: Icons.dynamic_feed_outlined,
            activeIcon: Icons.dynamic_feed,
            label: 'Feed',
          ),
          _TabConfig(
            path: '/events',
            icon: Icons.event_outlined,
            activeIcon: Icons.event,
            label: 'Eventos',
          ),
          _TabConfig(
            path: '/ranking',
            icon: Icons.leaderboard_outlined,
            activeIcon: Icons.leaderboard,
            label: 'Ranking',
          ),
          _TabConfig(
            path: '/profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
          ),
        ],
    };

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentLocation, required this.role});

  final String currentLocation;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsForRole(role);

    var selectedIndex = 0;
    for (var i = 0; i < tabs.length; i++) {
      if (currentLocation.startsWith(tabs[i].path)) {
        selectedIndex = i;
        break;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: AppColors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(tabs[index].path),
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
