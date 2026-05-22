import 'package:ctg_app/features/events/domain/entities/club_event.dart';

abstract interface class EventsRepository {
  Stream<List<ClubEvent>> watchEvents({EventKind? filter});
  Future<ClubEvent> getEvent(String eventId);
  Future<void> registerForEvent(String eventId);
  Future<void> unregisterFromEvent(String eventId);
  Future<List<String>> getRegisteredUserIds(String eventId);
}
