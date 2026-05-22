import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:ctg_app/core/errors/app_exception.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().asyncMap(
        (user) => user != null ? _fetchAppUser(user) : null,
      );

  Future<AppUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fetchAppUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthCode(e.code));
    }
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw const AuthException('Inicio de sesión cancelado.');

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return _fetchAppUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthCode(e.code));
    }
  }

  Future<AppUser> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);
      return _fetchAppUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthCode(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchAppUser(user);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(uid).update(updates);
    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
  }

  Future<AppUser> _fetchAppUser(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set({
        'displayName': user.displayName ?? 'Sin nombre',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final doc = await ref.get();

    final data = doc.data();

    // Role from custom claims (set by Cloud Functions) or Firestore fallback
    final idTokenResult = await user.getIdTokenResult(true);
    final claimRole = idTokenResult.claims?['role'] as String?;
    final firestoreRole = data?['role'] as String?;
    final roleStr = claimRole ?? firestoreRole ?? 'socio';

    final role = switch (roleStr) {
      'admin' => UserRole.admin,
      'entrenador' => UserRole.entrenador,
      _ => UserRole.socio,
    };
    return AppUser(
      id: user.uid,
      displayName: data?['displayName'] as String? ??
          user.displayName ??
          'Sin nombre',
      photoUrl: data?['photoUrl'] as String? ?? user.photoURL,
      email: user.email,
      role: role,
      memberSince: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String _mapAuthCode(String code) => switch (code) {
        'user-not-found' => 'No existe ninguna cuenta con ese email.',
        'wrong-password' => 'Contraseña incorrecta.',
        'email-already-in-use' => 'Este email ya está registrado.',
        'weak-password' => 'La contraseña es demasiado débil.',
        'invalid-email' => 'El formato del email no es válido.',
        'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Inténtalo más tarde.',
        _ => 'Error de autenticación.',
      };
}
