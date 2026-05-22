import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ctg_app/core/extensions/datetime_extensions.dart';
import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/filter_chip_bar.dart';
import 'package:ctg_app/features/events/application/events_notifier.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';
import 'package:ctg_app/features/events/presentation/widgets/event_row.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(eventsFilterNotifierProvider);
    final eventsAsync = ref.watch(eventsProvider(filter: filter));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eventsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (events) => Text(
                        '${events.where((e) => !e.startsAt.isPast).length} PRÓXIMOS',
                        style: AppTextStyles.monoSm,
                      ),
                    ),
                    Text('Eventos', style: AppTextStyles.headingLg),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FilterChipBar<EventKind?>(
                selected: filter,
                onSelected: ref
                    .read(eventsFilterNotifierProvider.notifier)
                    .setFilter,
                items: const [
                  (value: null, label: 'Todos'),
                  (value: EventKind.tournament, label: 'Torneos'),
                  (value: EventKind.clinic, label: 'Clínics'),
                  (value: EventKind.groupSession, label: 'Grupos'),
                ],
              ),
            ),
          ),

          // Events list grouped by month
          eventsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            data: (events) {
              if (events.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay eventos próximos',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                );
              }

              // Group by month
              final grouped = <String, List<ClubEvent>>{};
              for (final e in events) {
                final key = e.startsAt.monthYearMono;
                grouped.putIfAbsent(key, () => []).add(e);
              }

              return SliverList.builder(
                itemCount: grouped.length,
                itemBuilder: (_, i) {
                  final month = grouped.keys.elementAt(i);
                  final monthEvents = grouped[month]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          month,
                          style: AppTextStyles.monoMd.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...monthEvents.map(
                        (event) => EventRow(
                          event: event,
                          onTap: () =>
                              context.push('/events/${event.id}'),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
