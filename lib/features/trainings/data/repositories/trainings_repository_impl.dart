import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctg_app/features/trainings/domain/entities/training_session.dart';
import 'package:ctg_app/features/trainings/domain/repositories/trainings_repository.dart';

class TrainingsRepositoryImpl implements TrainingsRepository {
  TrainingsRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('trainings');

  @override
  Stream<List<TrainingSession>> watchSessions({String? coachId}) {
    Query<Map<String, dynamic>> q =
        _sessions.orderBy('startsAt', descending: false);

    if (coachId != null) {
      q = q.where('coachId', isEqualTo: coachId);
    }

    return q.snapshots().asyncMap((snap) async {
      final result = <TrainingSession>[];
      for (final doc in snap.docs) {
        final session = await _buildSession(doc);
        result.add(session);
      }
      return result;
    });
  }

  @override
  Future<TrainingSession> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    return _buildSession(doc);
  }

  @override
  Future<void> updateAttendance(
    String sessionId,
    List<AttendeeEntry> attendees,
  ) async {
    final batch = _db.batch();
    for (final a in attendees) {
      final ref = _sessions.doc(sessionId).collection('attendees').doc(a.userId);
      batch.set(ref, {
        'present': a.present,
        'note': a.note ?? '',
      });
    }
    await batch.commit();
  }

  @override
  Future<void> saveNotes(String sessionId, String notes) async {
    await _sessions.doc(sessionId).update({'coachNotes': notes});
  }

  @override
  Future<void> createSession({
    required String coachId,
    required String title,
    required String description,
    required String place,
    required int level,
    required int capacity,
    required DateTime startsAt,
    required Duration duration,
    bool isGroup = true,
  }) async {
    await _sessions.doc().set({
      'coachId': coachId,
      'title': title,
      'description': description,
      'place': place,
      'level': level,
      'capacity': capacity,
      'startsAt': Timestamp.fromDate(startsAt),
      'durationSeconds': duration.inSeconds,
      'isGroup': isGroup,
      'plan': <dynamic>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<TrainingSession> _buildSession(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data()!;
    data['id'] = doc.id;
    _normalizeTimestamps(data);

    // Duration from seconds int
    final durationSecs = data['durationSeconds'] as int? ?? 3600;
    data.remove('durationSeconds');

    // Fetch coach
    final coachId = data['coachId'] as String?;
    String? coachName;
    String? coachPhotoUrl;
    if (coachId != null) {
      final coachDoc = await _db.collection('users').doc(coachId).get();
      coachName = coachDoc.data()?['displayName'] as String?;
      coachPhotoUrl = coachDoc.data()?['photoUrl'] as String?;
    }

    // Fetch attendees
    final attendeesSnap =
        await _sessions.doc(doc.id).collection('attendees').get();
    final attendees = <AttendeeEntry>[];
    for (final aDoc in attendeesSnap.docs) {
      final aData = aDoc.data();
      final userDoc = await _db.collection('users').doc(aDoc.id).get();
      attendees.add(
        AttendeeEntry(
          userId: aDoc.id,
          present: aData['present'] as bool? ?? false,
          note: aData['note'] as String?,
          displayName: userDoc.data()?['displayName'] as String?,
          photoUrl: userDoc.data()?['photoUrl'] as String?,
        ),
      );
    }

    // Parse plan blocks
    final planRaw = data['plan'] as List<dynamic>? ?? [];
    final plan = planRaw
        .map((e) => TrainingBlock.fromJson(e as Map<String, dynamic>))
        .toList();

    return TrainingSession(
      id: data['id'] as String,
      coachId: coachId ?? '',
      title: data['title'] as String? ?? 'Sesión',
      description: data['description'] as String? ?? '',
      place: data['place'] as String? ?? '',
      level: data['level'] as int? ?? 1,
      capacity: data['capacity'] as int? ?? 12,
      startsAt: DateTime.parse(data['startsAt'] as String),
      duration: Duration(seconds: durationSecs),
      plan: plan,
      attendees: attendees,
      coachName: coachName,
      coachPhotoUrl: coachPhotoUrl,
      isGroup: data['isGroup'] as bool? ?? true,
    );
  }

  void _normalizeTimestamps(Map<String, dynamic> data) {
    if (data['startsAt'] is Timestamp) {
      data['startsAt'] =
          (data['startsAt'] as Timestamp).toDate().toIso8601String();
    }
  }
}
