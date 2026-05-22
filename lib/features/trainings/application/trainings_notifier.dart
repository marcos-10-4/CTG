import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/trainings/data/repositories/trainings_repository_impl.dart';
import 'package:ctg_app/features/trainings/domain/entities/training_session.dart';
import 'package:ctg_app/features/trainings/domain/repositories/trainings_repository.dart';

part 'trainings_notifier.g.dart';

@riverpod
TrainingsRepository trainingsRepository(TrainingsRepositoryRef ref) {
  return TrainingsRepositoryImpl();
}

@riverpod
Stream<List<TrainingSession>> trainingSessions(TrainingSessionsRef ref, {String? coachId}) {
  return ref
      .watch(trainingsRepositoryProvider)
      .watchSessions(coachId: coachId);
}

@riverpod
Future<TrainingSession> trainingSession(TrainingSessionRef ref, String sessionId) {
  return ref.watch(trainingsRepositoryProvider).getSession(sessionId);
}

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  AsyncValue<List<AttendeeEntry>> build(String sessionId) {
    return const AsyncLoading();
  }

  void init(List<AttendeeEntry> initial) {
    state = AsyncData(List.of(initial));
  }

  void toggle(String userId) {
    final entries = state.valueOrNull ?? [];
    state = AsyncData(
      entries.map((e) {
        if (e.userId == userId) return e.copyWith(present: !e.present);
        return e;
      }).toList(),
    );
  }

  Future<void> save(String sessionId) async {
    final entries = state.valueOrNull ?? [];
    await ref
        .read(trainingsRepositoryProvider)
        .updateAttendance(sessionId, entries);
  }
}
