import 'package:ctg_app/features/trainings/domain/entities/training_session.dart';

abstract interface class TrainingsRepository {
  Stream<List<TrainingSession>> watchSessions({String? coachId});
  Future<TrainingSession> getSession(String sessionId);
  Future<void> updateAttendance(String sessionId, List<AttendeeEntry> attendees);
  Future<void> saveNotes(String sessionId, String notes);
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
  });
}
