import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ctg_app/features/auth/data/datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Stream<AppUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  Future<AppUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) =>
      _datasource.signInWithEmailAndPassword(email, password);

  @override
  Future<AppUser> signInWithGoogle() => _datasource.signInWithGoogle();

  @override
  Future<AppUser> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) =>
      _datasource.createUserWithEmailAndPassword(email, password, displayName);

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<AppUser?> getCurrentUser() => _datasource.getCurrentUser();

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = await getCurrentUser();
    if (user == null) return;
    await _datasource.updateProfile(
      uid: user.id,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
