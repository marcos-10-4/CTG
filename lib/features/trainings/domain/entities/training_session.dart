import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_session.freezed.dart';
part 'training_session.g.dart';

@freezed
class TrainingBlock with _$TrainingBlock {
  const factory TrainingBlock({
    required int startMinute,
    required int endMinute,
    required String title,
    String? description,
  }) = _TrainingBlock;

  factory TrainingBlock.fromJson(Map<String, dynamic> json) =>
      _$TrainingBlockFromJson(json);
}

@freezed
class AttendeeEntry with _$AttendeeEntry {
  const factory AttendeeEntry({
    required String userId,
    required bool present,
    String? displayName,
    String? photoUrl,
    String? note,
  }) = _AttendeeEntry;

  factory AttendeeEntry.fromJson(Map<String, dynamic> json) =>
      _$AttendeeEntryFromJson(json);
}

@freezed
class TrainingSession with _$TrainingSession {
  const factory TrainingSession({
    required String id,
    required String coachId,
    required String title,
    required String description,
    required String place,
    required int level,
    required int capacity,
    required DateTime startsAt,
    required Duration duration,
    @Default([]) List<TrainingBlock> plan,
    @Default([]) List<AttendeeEntry> attendees,
    String? coachName,
    String? coachPhotoUrl,
    @Default(false) bool isGroup,
  }) = _TrainingSession;

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionFromJson(json);
}
