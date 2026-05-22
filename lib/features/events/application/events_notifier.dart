import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/events/data/repositories/events_repository_impl.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';
import 'package:ctg_app/features/events/domain/repositories/events_repository.dart';

part 'events_notifier.g.dart';

@riverpod
EventsRepository eventsRepository(EventsRepositoryRef ref) {
  return EventsRepositoryImpl();
}

@riverpod
Stream<List<ClubEvent>> events(EventsRef ref, {EventKind? filter}) {
  return ref.watch(eventsRepositoryProvider).watchEvents(filter: filter);
}

@riverpod
class EventsFilterNotifier extends _$EventsFilterNotifier {
  @override
  EventKind? build() => null;

  void setFilter(EventKind? kind) => state = kind;
}

@riverpod
class EventRegistrationNotifier extends _$EventRegistrationNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> register(String eventId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(eventsRepositoryProvider).registerForEvent(eventId),
    );
  }

  Future<void> unregister(String eventId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(eventsRepositoryProvider).unregisterFromEvent(eventId),
    );
  }
}
