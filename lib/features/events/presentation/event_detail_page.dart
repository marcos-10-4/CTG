import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ctg_app/core/extensions/datetime_extensions.dart';
import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/shared/widgets/capacity_bar.dart';
import 'package:ctg_app/shared/widgets/kind_chip.dart';
import 'package:ctg_app/features/events/application/events_notifier.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});
  final String eventId;

  String _kindLabel(EventKind k) => switch (k) {
        EventKind.tournament => 'Torneo',
        EventKind.clinic => 'Clínic',
        EventKind.groupSession => 'Grupal',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider());
    final regState = ref.watch(eventRegistrationNotifierProvider);

    final event = eventsAsync.valueOrNull
        ?.firstWhere((e) => e.id == eventId, orElse: () => _loading);

    if (event == null || event.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isRegistered = event.myStatus == RegistrationStatus.registered;
    final isFull = event.registeredCount >= event.capacity;

    ref.listen(eventRegistrationNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header — green accent
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.green,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _GlassButton(
                onTap: () => context.pop(),
                icon: Icons.arrow_back,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _GlassButton(onTap: () {}, icon: Icons.share_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: event.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.coverUrl!,
                      fit: BoxFit.cover,
                      color: AppColors.greenDeep.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Container(
                      color: AppColors.green,
                      child: const Icon(
                        Icons.sports_tennis,
                        color: Colors.white24,
                        size: 80,
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kind + level chips
                  Row(
                    children: [
                      KindChip(
                        label: _kindLabel(event.kind),
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      KindChip(
                        label: 'NIVEL ${event.level}',
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(event.title, style: AppTextStyles.displayMd),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.ink2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Date/time/place block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: event.startsAt.dayMonthYear,
                          value: '${event.startsAt.hourMinute} – ${event.endsAt.hourMinute}',
                        ),
                        const Divider(height: 16),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lugar',
                          value: event.place,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Coach card
                  if (event.coachName != null) ...[
                    Text('Entrenador', style: AppTextStyles.headingSm),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            name: event.coachName!,
                            photoUrl: event.coachPhotoUrl,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.coachName!,
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Ver perfil'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Registered users
                  Text(
                    'Inscritos · ${event.registeredCount} de ${event.capacity}',
                    style: AppTextStyles.headingSm,
                  ),
                  const SizedBox(height: 10),
                  CapacityBar(
                    registered: event.registeredCount,
                    capacity: event.capacity,
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inscripción', style: AppTextStyles.caption),
                Text(
                  isFull ? 'Completo' : 'Gratuito',
                  style: AppTextStyles.headingMd.copyWith(
                    color: isFull ? AppColors.error : AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (isFull && !isRegistered) || regState.isLoading
                    ? null
                    : () {
                        if (isRegistered) {
                          ref
                              .read(eventRegistrationNotifierProvider.notifier)
                              .unregister(eventId);
                        } else {
                          ref
                              .read(eventRegistrationNotifierProvider.notifier)
                              .register(eventId);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRegistered ? AppColors.ink2 : AppColors.purple,
                ),
                child: regState.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(isRegistered ? 'Cancelar inscripción' : 'Inscribirme'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _loading = ClubEvent(
    id: '',
    title: 'Cargando...',
    description: '',
    place: '',
    kind: EventKind.tournament,
    startsAt: DateTime.now(),
    endsAt: DateTime.now(),
    capacity: 0,
    registeredCount: 0,
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.purple),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.labelMd),
          ],
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }
}
