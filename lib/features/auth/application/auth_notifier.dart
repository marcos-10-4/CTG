import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:ctg_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/features/auth/domain/repositories/auth_repository.dart';

part 'auth_notifier.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(FirebaseAuthDatasource());
}

@riverpod
Stream<AppUser?> authNotifier(AuthNotifierRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
class SignInNotifier extends _$SignInNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email,
            password,
          ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

@riverpod
class RegisterNotifier extends _$RegisterNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).createUserWithEmailAndPassword(
            email,
            password,
            displayName,
          ),
    );
  }
}
