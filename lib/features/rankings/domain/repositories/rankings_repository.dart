import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';

abstract interface class RankingsRepository {
  Stream<List<RankingEntry>> watchRankings();
  Future<RankingEntry?> getUserRanking(String userId);
}
