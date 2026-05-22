import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/features/admin/application/admin_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final roleState = ref.watch(setUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar usuarios'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, i) =>
              _UserTile(user: users[i], roleState: roleState),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.roleState});

  final AppUser user;
  final AsyncValue<void> roleState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AppAvatar(
        name: user.displayName,
        photoUrl: user.photoUrl,
        size: 44,
      ),
      title: Text(user.displayName, style: AppTextStyles.labelMd),
      subtitle: Text(user.email ?? '—', style: AppTextStyles.caption),
      trailing: DropdownButton<UserRole>(
        value: user.role,
        underline: const SizedBox.shrink(),
        style: AppTextStyles.labelSm.copyWith(color: AppColors.purple),
        items: const [
          DropdownMenuItem(value: UserRole.socio, child: Text('Socio')),
          DropdownMenuItem(
              value: UserRole.entrenador, child: Text('Entrenador')),
          DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
        ],
        onChanged: roleState.isLoading
            ? null
            : (newRole) {
                if (newRole == null || newRole == user.role) return;
                ref
                    .read(setUserRoleProvider.notifier)
                    .setRole(user.id, newRole);
              },
      ),
    );
  }
}
