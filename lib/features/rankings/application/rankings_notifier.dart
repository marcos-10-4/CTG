import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/rankings/data/repositories/rankings_repository_impl.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/rankings/domain/repositories/rankings_repository.dart';

part 'rankings_notifier.g.dart';

@riverpod
RankingsRepository rankingsRepository(RankingsRepositoryRef ref) {
  return RankingsRepositoryImpl();
}

@riverpod
Stream<List<RankingEntry>> rankings(RankingsRef ref) {
  return ref.watch(rankingsRepositoryProvider).watchRankings();
}

@riverpod
Future<RankingEntry?> userRanking(UserRankingRef ref, String userId) {
  return ref.watch(rankingsRepositoryProvider).getUserRanking(userId);
}

enum RankingCategory { individual, doubles, veterans }

@riverpod
class RankingCategoryNotifier extends _$RankingCategoryNotifier {
  @override
  RankingCategory build() => RankingCategory.individual;

  void set(RankingCategory category) => state = category;
}
