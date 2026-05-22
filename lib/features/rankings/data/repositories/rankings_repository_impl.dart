import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/rankings/domain/repositories/rankings_repository.dart';

class RankingsRepositoryImpl implements RankingsRepository {
  RankingsRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<RankingEntry>> watchRankings() {
    return _db
        .collection('rankings')
        .orderBy('position')
        .snapshots()
        .asyncMap((snap) async {
      final entries = <RankingEntry>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        data['userId'] = doc.id;
        _normalizeTimestamps(data);

        final userDoc = await _db.collection('users').doc(doc.id).get();
        final userData = userDoc.data();

        entries.add(
          RankingEntry.fromJson(data).copyWith(
            displayName: userData?['displayName'] as String?,
            photoUrl: userData?['photoUrl'] as String?,
          ),
        );
      }
      return entries;
    });
  }

  @override
  Future<RankingEntry?> getUserRanking(String userId) async {
    final doc = await _db.collection('rankings').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['userId'] = doc.id;
    _normalizeTimestamps(data);

    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data();

    return RankingEntry.fromJson(data).copyWith(
      displayName: userData?['displayName'] as String?,
      photoUrl: userData?['photoUrl'] as String?,
    );
  }

  void _normalizeTimestamps(Map<String, dynamic> data) {
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] =
          (data['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    data.putIfAbsent('updatedAt', () => DateTime.now().toIso8601String());
  }
}
