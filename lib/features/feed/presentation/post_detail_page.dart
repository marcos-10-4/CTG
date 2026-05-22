import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/feed/application/feed_notifier.dart';
import 'package:ctg_app/features/feed/domain/entities/club_post.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({required this.postId, super.key});
  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await ref.read(commentNotifierProvider.notifier).add(widget.postId, text);
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider());
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final userAsync = ref.watch(authNotifierProvider);

    final post = postsAsync.valueOrNull
        ?.firstWhere((p) => p.id == widget.postId, orElse: () => _empty);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero image or purple header
              SliverAppBar(
                expandedHeight: post?.mediaUrls.isNotEmpty == true ? 260 : 160,
                pinned: true,
                backgroundColor: AppColors.purple,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _GlassButton(
                    onTap: () => context.pop(),
                    icon: Icons.arrow_back,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _GlassButton(onTap: () {}, icon: Icons.share_outlined),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: post?.mediaUrls.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: post!.mediaUrls.first,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.25),
                          colorBlendMode: BlendMode.darken,
                        )
                      : Container(color: AppColors.purple),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post != null) ...[
                        Text(post.title, style: AppTextStyles.displayMd),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AppAvatar(
                              name: post.authorName ?? 'CTG',
                              photoUrl: post.authorPhotoUrl,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.authorName ?? 'Club CTG',
                              style: AppTextStyles.labelMd,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likesCount}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(post.body, style: AppTextStyles.bodyMd),

                        // Tournament CTA
                        if (post.kind == PostKind.tournament) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.purpleSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.purple.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events_outlined,
                                  color: AppColors.purple,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Torneo disponible',
                                        style: AppTextStyles.headingSm.copyWith(
                                          color: AppColors.purple,
                                        ),
                                      ),
                                      Text(
                                        'Inscríbete en la sección de eventos',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Text(
                          'Comentarios',
                          style: AppTextStyles.headingSm,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // Comments
              commentsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text(e.toString())),
                ),
                data: (comments) => SliverList.builder(
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppAvatar(
                            name: c.authorName ?? 'U',
                            photoUrl: c.authorPhotoUrl,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.authorName ?? 'Usuario',
                                        style: AppTextStyles.labelMd,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        timeago.format(c.createdAt, locale: 'es'),
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.body, style: AppTextStyles.bodyMd),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // Reply bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  userAsync.whenData(
                    (u) => AppAvatar(
                      name: u?.displayName ?? 'U',
                      photoUrl: u?.photoUrl,
                      size: 32,
                    ),
                  ).value ?? const SizedBox.square(dimension: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _empty = ClubPost(
    id: '',
    authorId: '',
    title: 'Cargando...',
    body: '',
    kind: PostKind.news,
    likesCount: 0,
    commentsCount: 0,
    pinned: false,
    createdAt: DateTime.now(),
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }
}
