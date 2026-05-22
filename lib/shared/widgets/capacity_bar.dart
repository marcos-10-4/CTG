import 'package:flutter/material.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';

class CapacityBar extends StatelessWidget {
  const CapacityBar({
    required this.registered,
    required this.capacity,
    super.key,
  });

  final int registered;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final ratio = capacity > 0 ? (registered / capacity).clamp(0.0, 1.0) : 0.0;
    final available = capacity - registered;
    final isFull = available <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(
              isFull ? AppColors.error : AppColors.green,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFull ? 'COMPLETO' : '$available PLAZAS',
          style: AppTextStyles.monoSm.copyWith(
            color: isFull ? AppColors.error : AppColors.greenDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
