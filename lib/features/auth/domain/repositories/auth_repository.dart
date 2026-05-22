import 'package:ctg_app/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Future<void> updateProfile({String? displayName, String? photoUrl});
}
