import 'package:ctg_app/features/feed/domain/entities/club_post.dart';
import 'package:ctg_app/features/feed/domain/entities/post_comment.dart';

abstract interface class FeedRepository {
  Stream<List<ClubPost>> watchPosts({PostKind? filter});
  Future<ClubPost> getPost(String postId);
  Stream<List<PostComment>> watchComments(String postId);
  Future<void> toggleLike(String postId, String userId);
  Future<void> addComment(String postId, String body);
  Future<void> createPost(ClubPost post);
  Future<void> deletePost(String postId);
}
