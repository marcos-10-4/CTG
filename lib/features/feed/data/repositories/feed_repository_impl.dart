import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ctg_app/features/feed/domain/entities/club_post.dart';
import 'package:ctg_app/features/feed/domain/entities/post_comment.dart';
import 'package:ctg_app/features/feed/domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  @override
  Stream<List<ClubPost>> watchPosts({PostKind? filter}) {
    Query<Map<String, dynamic>> q = _posts.orderBy('pinned', descending: true);

    if (filter != null) {
      q = q.where('kind', isEqualTo: filter.name);
    }

    q = q.orderBy('createdAt', descending: true);

    return q.snapshots().asyncMap((snap) async {
      final uid = _auth.currentUser?.uid;
      final posts = <ClubPost>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        _normalizeTimestamps(data);

        bool likedByMe = false;
        if (uid != null) {
          final likeDoc =
              await _posts.doc(doc.id).collection('likes').doc(uid).get();
          likedByMe = likeDoc.exists;
        }

        // Fetch author info
        final authorDoc = await _db
            .collection('users')
            .doc(data['authorId'] as String?)
            .get();
        final authorData = authorDoc.data();

        posts.add(
          ClubPost.fromJson(data).copyWith(
            likedByMe: likedByMe,
            authorName: authorData?['displayName'] as String?,
            authorPhotoUrl: authorData?['photoUrl'] as String?,
            authorRole: authorData?['role'] as String?,
          ),
        );
      }
      return posts;
    });
  }

  @override
  Future<ClubPost> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    final data = doc.data()!;
    data['id'] = doc.id;
    _normalizeTimestamps(data);
    return ClubPost.fromJson(data);
  }

  @override
  Stream<List<PostComment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .asyncMap((snap) async {
      final comments = <PostComment>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        _normalizeTimestamps(data);

        final authorDoc = await _db
            .collection('users')
            .doc(data['authorId'] as String?)
            .get();
        final authorData = authorDoc.data();

        comments.add(
          PostComment.fromJson(data).copyWith(
            authorName: authorData?['displayName'] as String?,
            authorPhotoUrl: authorData?['photoUrl'] as String?,
          ),
        );
      }
      return comments;
    });
  }

  @override
  Future<void> toggleLike(String postId, String userId) async {
    final ref = _posts.doc(postId);
    final likeRef = ref.collection('likes').doc(userId);

    await _db.runTransaction((t) async {
      final likeDoc = await t.get(likeRef);
      final postDoc = await t.get(ref);

      if (likeDoc.exists) {
        t.delete(likeRef);
        t.update(ref, {
          'likesCount': (postDoc.data()?['likesCount'] as int? ?? 1) - 1,
        });
      } else {
        t.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        t.update(ref, {
          'likesCount': (postDoc.data()?['likesCount'] as int? ?? 0) + 1,
        });
      }
    });
  }

  @override
  Future<void> addComment(String postId, String body) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final commentRef =
        _posts.doc(postId).collection('comments').doc();
    final postRef = _posts.doc(postId);

    await _db.runTransaction((t) async {
      final postDoc = await t.get(postRef);
      t.set(commentRef, {
        'authorId': uid,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.update(postRef, {
        'commentsCount':
            (postDoc.data()?['commentsCount'] as int? ?? 0) + 1,
      });
    });
  }

  @override
  Future<void> createPost(ClubPost post) async {
    await _posts.doc(post.id).set({
      'authorId': post.authorId,
      'kind': post.kind.name,
      'title': post.title,
      'body': post.body,
      'mediaUrls': post.mediaUrls,
      'likesCount': 0,
      'commentsCount': 0,
      'pinned': post.pinned,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  void _normalizeTimestamps(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
  }
}
