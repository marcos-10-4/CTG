import 'package:flutter/material.dart';

import 'package:ctg_app/core/extensions/datetime_extensions.dart';
import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/capacity_bar.dart';
import 'package:ctg_app/shared/widgets/kind_chip.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';

class EventRow extends StatelessWidget {
  const EventRow({
    required this.event,
    required this.onTap,
    super.key,
  });

  final ClubEvent event;
  final VoidCallback onTap;

  Color _kindColor(EventKind kind) => switch (kind) {
        EventKind.tournament => AppColors.purple,
        EventKind.clinic => AppColors.green,
        EventKind.groupSession => AppColors.ink2,
      };

  String _kindLabel(EventKind kind) => switch (kind) {
        EventKind.tournament => 'Torneo',
        EventKind.clinic => 'Clínic',
        EventKind.groupSession => 'Grupo',
      };

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(event.kind);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // Date block
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    event.startsAt.dayShort,
                    style: AppTextStyles.displayMd.copyWith(
                      color: color,
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    event.startsAt.monthShort,
                    style: AppTextStyles.monoSm.copyWith(color: color),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KindChip(label: _kindLabel(event.kind), color: color),
                        if (event.myStatus == RegistrationStatus.registered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'INSCRITO',
                              style: AppTextStyles.monoSm.copyWith(
                                color: AppColors.white,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: AppTextStyles.headingSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.startsAt.hourMinute,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.place,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CapacityBar(
                      registered: event.registeredCount,
                      capacity: event.capacity,
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
