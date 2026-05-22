import 'package:ctg_app/core/shell/main_shell.dart';
import 'package:ctg_app/features/admin/presentation/users_page.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/features/auth/presentation/login_page.dart';
import 'package:ctg_app/features/auth/presentation/profile_page.dart';
import 'package:ctg_app/features/auth/presentation/register_page.dart';
import 'package:ctg_app/features/events/presentation/event_detail_page.dart';
import 'package:ctg_app/features/events/presentation/events_page.dart';
import 'package:ctg_app/features/feed/presentation/feed_page.dart';
import 'package:ctg_app/features/feed/presentation/post_detail_page.dart';
import 'package:ctg_app/features/rankings/presentation/ranking_page.dart';
import 'package:ctg_app/features/trainings/presentation/training_page.dart';
import 'package:ctg_app/features/trainings/presentation/trainings_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) {
        return user.role == UserRole.entrenador ? '/trainings' : '/feed';
      }
      if (!isLoggedIn) return null;

      final role = user.role;

      if (role == UserRole.entrenador) {
        final allowed = loc.startsWith('/trainings') ||
            loc.startsWith('/profile');
        if (!allowed) return '/trainings';
      }

      if (role == UserRole.socio) {
        if (loc.startsWith('/trainings') || loc.startsWith('/admin')) {
          return '/feed';
        }
      }

      if (role != UserRole.admin && loc.startsWith('/admin')) {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            name: 'feed',
            builder: (_, __) => const FeedPage(),
            routes: [
              GoRoute(
                path: 'post/:id',
                name: 'post-detail',
                builder: (_, state) =>
                    PostDetailPage(postId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (_, __) => const EventsPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'event-detail',
                builder: (_, state) =>
                    EventDetailPage(eventId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/ranking',
            name: 'ranking',
            builder: (_, __) => const RankingPage(),
          ),
          GoRoute(
            path: '/trainings',
            name: 'trainings',
            builder: (_, __) => const TrainingsListPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'training',
                builder: (_, state) =>
                    TrainingPage(sessionId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (_, __) => const UsersPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.error}'),
      ),
    ),
  );
}
