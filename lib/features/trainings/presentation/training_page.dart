import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ctg_app/core/extensions/datetime_extensions.dart';
import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/shared/widgets/kind_chip.dart';
import 'package:ctg_app/features/trainings/application/trainings_notifier.dart';
import 'package:ctg_app/features/trainings/domain/entities/training_session.dart';

class TrainingPage extends ConsumerStatefulWidget {
  const TrainingPage({required this.sessionId, super.key});
  final String sessionId;

  @override
  ConsumerState<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends ConsumerState<TrainingPage> {
  final _notesController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(trainingSessionProvider(widget.sessionId));

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (session) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(attendanceNotifierProvider(widget.sessionId).notifier)
                .init(session.attendees);
          });
          _initialized = true;
        }
        return _TrainingContent(
          session: session,
          notesController: _notesController,
        );
      },
    );
  }
}

class _TrainingContent extends ConsumerWidget {
  const _TrainingContent({
    required this.session,
    required this.notesController,
  });

  final TrainingSession session;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState =
        ref.watch(attendanceNotifierProvider(session.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.startsAt.dayMonthYear,
              style: AppTextStyles.monoSm,
            ),
            Text('Sesión', style: AppTextStyles.labelMd),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level + type chips
            Row(
              children: [
                KindChip(
                  label: 'NIVEL ${session.level}',
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                KindChip(
                  label: session.isGroup
                      ? 'GRUPAL · ${session.capacity}'
                      : 'INDIVIDUAL',
                  color: AppColors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(session.title, style: AppTextStyles.headingLg),
            const SizedBox(height: 6),
            Text(
              session.description,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(session.place, style: AppTextStyles.caption),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  '${session.startsAt.hourMinute} · '
                  '${session.duration.inMinutes} min',
                  style: AppTextStyles.caption,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Training plan
            if (session.plan.isNotEmpty) ...[
              Text('Plan de la sesión', style: AppTextStyles.headingSm),
              const SizedBox(height: 10),
              ...session.plan.asMap().entries.map((entry) {
                final i = entry.key;
                final block = entry.value;
                final isEven = i % 2 == 0;
                return _PlanBlock(block: block, isEven: isEven);
              }),
              const SizedBox(height: 24),
            ],

            // Attendance
            Text('Asistencia', style: AppTextStyles.headingSm),
            const SizedBox(height: 10),
            attendanceState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
              data: (attendees) => Column(
                children: attendees.map((attendee) {
                  return _AttendeeRow(
                    attendee: attendee,
                    onToggle: () => ref
                        .read(attendanceNotifierProvider(session.id).notifier)
                        .toggle(attendee.userId),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            Text('Notas del entrenador', style: AppTextStyles.headingSm),
            const SizedBox(height: 10),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Añade tus observaciones de la sesión...',
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Bottom buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink2,
                  side: const BorderSide(color: AppColors.line),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(
                        attendanceNotifierProvider(session.id).notifier,
                      )
                      .save(session.id);
                  if (notesController.text.isNotEmpty) {
                    await ref
                        .read(trainingsRepositoryProvider)
                        .saveNotes(session.id, notesController.text);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión guardada')),
                    );
                  }
                },
                child: const Text('Guardar notas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBlock extends StatelessWidget {
  const _PlanBlock({required this.block, required this.isEven});
  final TrainingBlock block;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final color = isEven ? AppColors.purpleSoft : AppColors.greenSoft;
    final textColor = isEven ? AppColors.purple : AppColors.greenDeep;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${block.startMinute}–${block.endMinute}',
              style: AppTextStyles.monoSm.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: AppTextStyles.labelMd.copyWith(color: textColor),
                ),
                if (block.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    block.description!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({
    required this.attendee,
    required this.onToggle,
  });
  final AttendeeEntry attendee;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppAvatar(
            name: attendee.displayName ?? 'U',
            photoUrl: attendee.photoUrl,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attendee.displayName ?? 'Jugador',
              style: AppTextStyles.labelMd,
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: attendee.present ? AppColors.green : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      attendee.present ? AppColors.green : AppColors.line,
                  width: 2,
                ),
              ),
              child: attendee.present
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
