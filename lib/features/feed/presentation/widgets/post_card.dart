import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/shared/widgets/kind_chip.dart';
import 'package:ctg_app/features/feed/domain/entities/club_post.dart';

class PostCard extends ConsumerWidget {
  const PostCard({required this.post, required this.onTap, super.key});

  final ClubPost post;
  final VoidCallback onTap;

  Color _kindColor(PostKind kind) => switch (kind) {
        PostKind.tournament => AppColors.purple,
        PostKind.announcement => AppColors.green,
        PostKind.news => AppColors.ink2,
        PostKind.photo => AppColors.muted,
      };

  String _kindLabel(PostKind kind) => switch (kind) {
        PostKind.tournament => 'Torneo',
        PostKind.announcement => 'Aviso',
        PostKind.news => 'Noticia',
        PostKind.photo => 'Foto',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  AppAvatar(
                    name: post.authorName ?? 'U',
                    photoUrl: post.authorPhotoUrl,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName ?? 'Staff CTG',
                              style: AppTextStyles.labelMd,
                            ),
                            if (post.authorRole != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  post.authorRole!.toUpperCase(),
                                  style: AppTextStyles.monoSm.copyWith(
                                    fontSize: 9,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          timeago.format(post.createdAt, locale: 'es'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  KindChip(
                    label: _kindLabel(post.kind),
                    color: _kindColor(post.kind),
                  ),
                ],
              ),
            ),

            // Pinned badge
            if (post.pinned)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.push_pin,
                        size: 11,
                        color: AppColors.greenDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FIJADO',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.greenDeep,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Title + body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: AppTextStyles.headingSm),
                  const SizedBox(height: 4),
                  Text(
                    post.body,
                    style: AppTextStyles.bodySm,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Image
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            // Action bar
            if (post.mediaUrls.isEmpty) const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: '${post.likesCount}',
                    color: post.likedByMe ? Colors.red : AppColors.muted,
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentsCount}',
                    onTap: onTap,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    color: AppColors.muted,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color ?? AppColors.muted),
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color ?? AppColors.muted,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
