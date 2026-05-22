import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_entry.freezed.dart';
part 'ranking_entry.g.dart';

@freezed
class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required String userId,
    required int points,
    required int wins,
    required int losses,
    required int position,
    required int weeklyDelta,
    required DateTime updatedAt,
    String? displayName,
    String? photoUrl,
  }) = _RankingEntry;

  factory RankingEntry.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryFromJson(json);
}
