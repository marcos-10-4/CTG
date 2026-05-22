import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { socio, entrenador, admin }

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String displayName,
    required UserRole role,
    String? photoUrl,
    String? email,
    DateTime? memberSince,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
