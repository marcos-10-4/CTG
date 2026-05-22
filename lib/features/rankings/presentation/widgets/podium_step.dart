import 'package:flutter/material.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';

class PodiumStep extends StatelessWidget {
  const PodiumStep({
    required this.entry,
    required this.position,
    super.key,
  });

  final RankingEntry entry;
  final int position;

  Color get _podiumColor => switch (position) {
        1 => AppColors.purple,
        2 => AppColors.purpleDeep,
        _ => AppColors.greenDeep,
      };

  double get _height => switch (position) {
        1 => 90,
        2 => 65,
        _ => 50,
      };

  double get _avatarSize => position == 1 ? 64 : 52;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Position badge
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _podiumColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$position',
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Avatar (overlapping the step)
        AppAvatar(
          name: entry.displayName ?? 'U',
          photoUrl: entry.photoUrl,
          size: _avatarSize,
          borderColor: _podiumColor,
          borderWidth: 3,
        ),
        const SizedBox(height: 6),

        Text(
          (entry.displayName ?? 'Usuario').split(' ').first,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.points} pts',
          style: AppTextStyles.monoSm.copyWith(
            color: _podiumColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        // Step block
        Container(
          width: double.infinity,
          height: _height,
          decoration: BoxDecoration(
            color: _podiumColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
