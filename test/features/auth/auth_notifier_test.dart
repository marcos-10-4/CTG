import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  const testUser = AppUser(
    id: 'uid-1',
    displayName: 'Test User',
    role: UserRole.socio,
  );

  group('SignInNotifier', () {
    test('starts in AsyncData(null)', () {
      expect(
        container.read(signInNotifierProvider),
        const AsyncData<void>(null),
      );
    });

    test('signInWithEmail emits AsyncData on success', () async {
      when(
        () => mockRepo.signInWithEmailAndPassword(any(), any()),
      ).thenAnswer((_) async => testUser);

      await container
          .read(signInNotifierProvider.notifier)
          .signInWithEmail('test@ctg.com', 'password123');

      expect(
        container.read(signInNotifierProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('signInWithEmail emits AsyncError on failure', () async {
      when(
        () => mockRepo.signInWithEmailAndPassword(any(), any()),
      ).thenThrow(Exception('Auth failed'));

      await container
          .read(signInNotifierProvider.notifier)
          .signInWithEmail('bad@ctg.com', 'wrong');

      expect(
        container.read(signInNotifierProvider),
        isA<AsyncError<void>>(),
      );
    });
  });
}
