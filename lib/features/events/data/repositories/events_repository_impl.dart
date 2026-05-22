import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ctg_app/core/errors/app_exception.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';
import 'package:ctg_app/features/events/domain/repositories/events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  @override
  Stream<List<ClubEvent>> watchEvents({EventKind? filter}) {
    Query<Map<String, dynamic>> q =
        _events.orderBy('startsAt', descending: false);

    if (filter != null) {
      q = q.where('kind', isEqualTo: filter.name);
    }

    return q.snapshots().asyncMap((snap) async {
      final uid = _auth.currentUser?.uid;
      final result = <ClubEvent>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        _normalizeTimestamps(data);

        RegistrationStatus myStatus = RegistrationStatus.none;
        if (uid != null) {
          final regDoc = await _events
              .doc(doc.id)
              .collection('registrations')
              .doc(uid)
              .get();
          if (regDoc.exists) {
            myStatus = RegistrationStatus.registered;
          }
        }

        // Fetch coach if present
        String? coachName;
        String? coachPhotoUrl;
        final coachId = data['coachId'] as String?;
        if (coachId != null) {
          final coachDoc =
              await _db.collection('users').doc(coachId).get();
          coachName = coachDoc.data()?['displayName'] as String?;
          coachPhotoUrl = coachDoc.data()?['photoUrl'] as String?;
        }

        result.add(
          ClubEvent.fromJson(data).copyWith(
            myStatus: myStatus,
            coachName: coachName,
            coachPhotoUrl: coachPhotoUrl,
          ),
        );
      }
      return result;
    });
  }

  @override
  Future<ClubEvent> getEvent(String eventId) async {
    final doc = await _events.doc(eventId).get();
    final data = doc.data()!;
    data['id'] = doc.id;
    _normalizeTimestamps(data);
    return ClubEvent.fromJson(data);
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    try {
      final callable = _functions.httpsCallable('registerForEvent');
      await callable.call<dynamic>({'eventId': eventId});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw const CapacityException();
      }
      throw UnknownException(e.message ?? 'Error al inscribirse.');
    }
  }

  @override
  Future<void> unregisterFromEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.runTransaction((t) async {
      final regRef =
          _events.doc(eventId).collection('registrations').doc(uid);
      final eventRef = _events.doc(eventId);

      final regDoc = await t.get(regRef);
      if (!regDoc.exists) return;

      final eventDoc = await t.get(eventRef);
      final count = (eventDoc.data()?['registeredCount'] as int? ?? 1);

      t.delete(regRef);
      t.update(eventRef, {'registeredCount': count > 0 ? count - 1 : 0});
    });
  }

  @override
  Future<List<String>> getRegisteredUserIds(String eventId) async {
    final snap = await _events
        .doc(eventId)
        .collection('registrations')
        .limit(50)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  void _normalizeTimestamps(Map<String, dynamic> data) {
    for (final key in ['startsAt', 'endsAt']) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
  }
}

