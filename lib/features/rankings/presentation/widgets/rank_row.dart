import 'package:flutter/material.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';

class RankRow extends StatelessWidget {
  const RankRow({
    required this.entry,
    required this.isCurrentUser,
    super.key,
  });

  final RankingEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.purpleSoft : Colors.transparent,
        border: isCurrentUser
            ? const Border(
                left: BorderSide(color: AppColors.purple, width: 3),
              )
            : null,
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              '${entry.position}',
              style: AppTextStyles.monoMd.copyWith(
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? AppColors.purple : AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          AppAvatar(
            name: entry.displayName ?? 'U',
            photoUrl: entry.photoUrl,
            size: 36,
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              entry.displayName ?? 'Usuario',
              style: AppTextStyles.labelMd.copyWith(
                color: isCurrentUser ? AppColors.purple : AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ELO points
          Text(
            '${entry.points}',
            style: AppTextStyles.monoMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),

          // Weekly delta
          _DeltaBadge(delta: entry.weeklyDelta),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Text('—', style: AppTextStyles.caption);
    }

    final isUp = delta > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: isUp ? AppColors.green : AppColors.error,
          size: 16,
        ),
        Text(
          isUp ? '+$delta' : '$delta',
          style: AppTextStyles.monoSm.copyWith(
            color: isUp ? AppColors.greenDeep : AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
