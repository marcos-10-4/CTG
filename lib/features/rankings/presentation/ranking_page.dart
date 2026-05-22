import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/filter_chip_bar.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/rankings/application/rankings_notifier.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/rankings/presentation/widgets/podium_step.dart';
import 'package:ctg_app/features/rankings/presentation/widgets/rank_row.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final category = ref.watch(rankingCategoryNotifierProvider);
    final userAsync = ref.watch(authNotifierProvider);
    final currentUserId = userAsync.valueOrNull?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TEMPORADA 2026 · ELO', style: AppTextStyles.monoSm),
                Text('Ranking', style: AppTextStyles.headingLg),
              ],
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FilterChipBar<RankingCategory>(
                selected: category,
                onSelected: ref
                    .read(rankingCategoryNotifierProvider.notifier)
                    .set,
                items: const [
                  (value: RankingCategory.individual, label: 'Individual'),
                  (value: RankingCategory.doubles, label: 'Dobles'),
                  (value: RankingCategory.veterans, label: 'Veteranos'),
                ],
              ),
            ),
          ),

          rankingsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(e.toString())),
            ),
            data: (rankings) {
              if (rankings.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay clasificación disponible',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                );
              }

              final top3 = rankings.take(3).toList();
              final rest = rankings.skip(3).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Podium
                  _Podium(top3: top3),
                  const SizedBox(height: 8),
                  const Divider(),

                  // Table header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('#', style: AppTextStyles.caption),
                        ),
                        const SizedBox(width: 10),
                        const SizedBox(width: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jugador',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        Text('Pts', style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '7d',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top 3 rows (after podium)
                  ...top3.map(
                    (e) => RankRow(
                      entry: e,
                      isCurrentUser: e.userId == currentUserId,
                    ),
                  ),

                  // Rest
                  ...rest.map(
                    (e) => RankRow(
                      entry: e,
                      isCurrentUser: e.userId == currentUserId,
                    ),
                  ),

                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<RankingEntry> top3;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // Reorder for visual podium: 2nd left, 1st center, 3rd right
    final ordered = <({RankingEntry entry, int pos})>[
      if (top3.length >= 2) (entry: top3[1], pos: 2),
      if (top3.isNotEmpty) (entry: top3[0], pos: 1),
      if (top3.length >= 3) (entry: top3[2], pos: 3),
    ];

    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ordered.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: PodiumStep(
                entry: item.entry,
                position: item.pos,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
