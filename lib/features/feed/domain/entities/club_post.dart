import 'package:freezed_annotation/freezed_annotation.dart';

part 'club_post.freezed.dart';
part 'club_post.g.dart';

enum PostKind { news, photo, announcement, tournament }

@freezed
class ClubPost with _$ClubPost {
  const factory ClubPost({
    required String id,
    required String authorId,
    required String title,
    required String body,
    required PostKind kind,
    required int likesCount,
    required int commentsCount,
    required bool pinned,
    required DateTime createdAt,
    @Default([]) List<String> mediaUrls,
    String? authorName,
    String? authorPhotoUrl,
    String? authorRole,
    @Default(false) bool likedByMe,
  }) = _ClubPost;

  factory ClubPost.fromJson(Map<String, dynamic> json) =>
      _$ClubPostFromJson(json);
}
