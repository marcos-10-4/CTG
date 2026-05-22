import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:ctg_app/core/extensions/string_extensions.dart';
import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.photoUrl,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 0,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final Widget content = photoUrl != null && photoUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: photoUrl!,
            imageBuilder: (_, imageProvider) => _circle(
              child: Image(image: imageProvider, fit: BoxFit.cover),
            ),
            placeholder: (_, __) => _initialsCircle(),
            errorWidget: (_, __, ___) => _initialsCircle(),
          )
        : _initialsCircle();

    if (borderWidth > 0 && borderColor != null) {
      return Container(
        width: size + borderWidth * 2,
        height: size + borderWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor,
        ),
        child: Center(child: content),
      );
    }

    return content;
  }

  Widget _circle({required Widget child}) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _initialsCircle() {
    final fontSize = size * 0.38;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.purpleSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        name.initials,
        style: AppTextStyles.labelMd.copyWith(
          fontSize: fontSize,
          color: AppColors.purple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
