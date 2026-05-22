import 'package:flutter/material.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';

class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: items.map((item) {
          final isSelected = item.value == selected;
          return GestureDetector(
            onTap: () => onSelected(item.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.purple : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.purple : AppColors.line,
                ),
              ),
              child: Text(
                item.label,
                style: AppTextStyles.labelMd.copyWith(
                  color: isSelected ? AppColors.white : AppColors.ink2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
