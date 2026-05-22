import 'package:freezed_annotation/freezed_annotation.dart';

part 'club_event.freezed.dart';
part 'club_event.g.dart';

enum EventKind { tournament, clinic, groupSession }

enum RegistrationStatus { none, registered, waitlist }

@freezed
class ClubEvent with _$ClubEvent {
  const factory ClubEvent({
    required String id,
    required String title,
    required String description,
    required String place,
    required EventKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    required int registeredCount,
    String? coverUrl,
    String? coachId,
    String? coachName,
    String? coachPhotoUrl,
    @Default(RegistrationStatus.none) RegistrationStatus myStatus,
    @Default(1) int level,
  }) = _ClubEvent;

  factory ClubEvent.fromJson(Map<String, dynamic> json) =>
      _$ClubEventFromJson(json);
}
