import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/core/extensions/datetime_extensions.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/features/payments/application/payments_notifier.dart';
import 'package:ctg_app/features/payments/domain/entities/payment_record.dart';
import 'package:ctg_app/features/rankings/application/rankings_notifier.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(userRankingProvider(user.id));
    final paymentAsync = ref.watch(userPaymentProvider(user.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ProfileHeader(user: user),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats card overlapping header
                _StatsCard(user: user, rankAsync: rankAsync),
                const SizedBox(height: 16),

                // Payment banner
                paymentAsync.whenData(
                  (payment) => payment != null
                      ? _PaymentBanner(payment: payment)
                      : const SizedBox.shrink(),
                ).value ?? const SizedBox.shrink(),

                const SizedBox(height: 8),

                // Menu items
                _MenuItem(
                  icon: Icons.history,
                  title: 'Historial de partidos',
                  subtitle: 'Resultados y puntuación ELO',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.fitness_center,
                  title: 'Entrenamientos',
                  subtitle: 'Sesiones y asistencia',
                  onTap: () => context.go('/trainings'),
                ),
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Pagos',
                  subtitle: 'Historial de cuotas',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Preferencias de avisos',
                  onTap: () {},
                ),
                if (user.role == UserRole.admin) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'ADMINISTRACIÓN',
                      style: AppTextStyles.monoSm,
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Gestionar usuarios',
                    subtitle: 'Roles y permisos',
                    onTap: () => context.push('/admin/users'),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(signInNotifierProvider.notifier)
                        .signOut(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: AppColors.purple,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.purple,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AppAvatar(
                      name: user.displayName,
                      photoUrl: user.photoUrl,
                      size: 80,
                      borderColor: AppColors.white,
                      borderWidth: 3,
                    ),
                    // Online indicator
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  user.displayName,
                  style: AppTextStyles.headingMd.copyWith(
                    color: AppColors.white,
                  ),
                ),
                if (user.memberSince != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Socio desde ${user.memberSince!.dayMonthYear}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  const _StatsCard({required this.user, required this.rankAsync});
  final AppUser user;
  final AsyncValue<RankingEntry?> rankAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: rankAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const _StatsRow(elo: '—', pos: '—', record: '—'),
          data: (ranking) {
            if (ranking == null) {
              return const _StatsRow(elo: '1200', pos: '—', record: '0-0');
            }
            return _StatsRow(
              elo: ranking.points.toString(),
              pos: '#${ranking.position}',
              record: '${ranking.wins}-${ranking.losses}',
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.elo,
    required this.pos,
    required this.record,
  });
  final String elo;
  final String pos;
  final String record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(label: 'Puntos ELO', value: elo),
        const _Divider(),
        _StatCell(label: 'Posición', value: pos),
        const _Divider(),
        _StatCell(label: 'V-D 2026', value: record),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.displayMd.copyWith(
              color: AppColors.purple,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.line,
    );
  }
}

class _PaymentBanner extends StatelessWidget {
  const _PaymentBanner({required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == PaymentStatus.pagado;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.greenSoft : AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? AppColors.green : AppColors.purple,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: isPaid ? AppColors.greenDeep : AppColors.purple,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Cuota al día' : 'Cuota pendiente',
                  style: AppTextStyles.labelMd.copyWith(
                    color: isPaid ? AppColors.greenDeep : AppColors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Renovación: ${payment.periodEnd.dayMonthYear}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.purpleSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.purple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMd),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
