import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('displayName')
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            final roleStr = data['role'] as String? ?? 'socio';
            final role = switch (roleStr) {
              'admin' => UserRole.admin,
              'entrenador' => UserRole.entrenador,
              _ => UserRole.socio,
            };
            return AppUser(
              id: doc.id,
              displayName: data['displayName'] as String? ?? 'Sin nombre',
              email: data['email'] as String?,
              photoUrl: data['photoUrl'] as String?,
              role: role,
              memberSince:
                  (data['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),);
});

class SetUserRoleNotifier extends StateNotifier<AsyncValue<void>> {
  SetUserRoleNotifier() : super(const AsyncData(null));

  Future<void> setRole(String uid, UserRole role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fn = FirebaseFunctions.instance.httpsCallable('setUserRole');
      await fn.call<Map<String, dynamic>>({'uid': uid, 'role': role.name});
    });
  }
}

final setUserRoleProvider =
    StateNotifierProvider<SetUserRoleNotifier, AsyncValue<void>>(
  (_) => SetUserRoleNotifier(),
);
