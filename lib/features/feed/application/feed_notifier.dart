import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ctg_app/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:ctg_app/features/feed/domain/entities/club_post.dart';
import 'package:ctg_app/features/feed/domain/entities/post_comment.dart';
import 'package:ctg_app/features/feed/domain/repositories/feed_repository.dart';

part 'feed_notifier.g.dart';

@riverpod
FeedRepository feedRepository(FeedRepositoryRef ref) {
  return FeedRepositoryImpl();
}

@riverpod
Stream<List<ClubPost>> feedPosts(FeedPostsRef ref, {PostKind? filter}) {
  return ref.watch(feedRepositoryProvider).watchPosts(filter: filter);
}

@riverpod
Stream<List<PostComment>> postComments(PostCommentsRef ref, String postId) {
  return ref.watch(feedRepositoryProvider).watchComments(postId);
}

@riverpod
class FeedFilterNotifier extends _$FeedFilterNotifier {
  @override
  PostKind? build() => null;

  void setFilter(PostKind? kind) => state = kind;
}

@riverpod
class LikeNotifier extends _$LikeNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> toggle(String postId, String userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feedRepositoryProvider).toggleLike(postId, userId),
    );
  }
}

@riverpod
class CommentNotifier extends _$CommentNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> add(String postId, String body) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(feedRepositoryProvider).addComment(postId, body),
    );
  }
}
