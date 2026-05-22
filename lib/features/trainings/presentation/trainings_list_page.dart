import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/auth/domain/entities/app_user.dart';
import 'package:ctg_app/features/trainings/application/trainings_notifier.dart';
import 'package:ctg_app/features/trainings/domain/entities/training_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TrainingsListPage extends ConsumerWidget {
  const TrainingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final user = userAsync.valueOrNull;

    final coachId =
        user?.role == UserRole.entrenador ? user?.id : null;
    final sessionsAsync =
        ref.watch(trainingSessionsProvider(coachId: coachId));

    final canCreate = user?.role == UserRole.admin ||
        user?.role == UserRole.entrenador;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMM', 'es')
                      .format(DateTime.now())
                      .toUpperCase(),
                  style: AppTextStyles.monoSm,
                ),
                Text('Entrenamientos', style: AppTextStyles.headingLg),
              ],
            ),
          ),
          sessionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(e.toString())),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay sesiones programadas',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: sessions.length,
                itemBuilder: (_, i) => _SessionCard(
                  session: sessions[i],
                  onTap: () =>
                      context.push('/trainings/${sessions[i].id}'),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context, ref, user!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateSheet(
      BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateSessionSheet(coachId: user.id),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final TrainingSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM · HH:mm', 'es');
    final levelColors = [
      AppColors.green,
      AppColors.purple,
      Colors.orange,
      AppColors.error,
    ];
    final levelColor =
        levelColors[(session.level - 1).clamp(0, 3)];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.purpleSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: AppTextStyles.labelMd),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(session.startsAt),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(session.place, style: AppTextStyles.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Niv. ${session.level}',
                    style: AppTextStyles.labelSm
                        .copyWith(color: levelColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.attendees.length}/${session.capacity}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSessionSheet extends ConsumerStatefulWidget {
  const _CreateSessionSheet({required this.coachId});
  final String coachId;

  @override
  ConsumerState<_CreateSessionSheet> createState() =>
      _CreateSessionSheetState();
}

class _CreateSessionSheetState
    extends ConsumerState<_CreateSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 3600; // seconds
  int _level = 2;
  int _capacity = 12;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final startsAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    try {
      await ref.read(trainingsRepositoryProvider).createSession(
            coachId: widget.coachId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            place: _placeCtrl.text.trim(),
            level: _level,
            capacity: _capacity,
            startsAt: startsAt,
            duration: Duration(seconds: _duration),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Nueva sesión', style: AppTextStyles.headingMd),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Título *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Lugar *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          DateFormat('d MMM yyyy', 'es').format(_date),),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_time.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null) {
                          setState(() => _time = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Duración'),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3600, label: Text('1 h')),
                  ButtonSegment(value: 5400, label: Text('1.5 h')),
                  ButtonSegment(value: 7200, label: Text('2 h')),
                ],
                selected: {_duration},
                onSelectionChanged: (s) =>
                    setState(() => _duration = s.first),
              ),
              const SizedBox(height: 16),
              Text('Nivel: $_level', style: AppTextStyles.labelSm),
              Slider(
                value: _level.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '$_level',
                onChanged: (v) => setState(() => _level = v.round()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Capacidad'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _capacity > 1
                        ? () => setState(() => _capacity--)
                        : null,
                  ),
                  Text('$_capacity', style: AppTextStyles.labelMd),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _capacity++),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,),
                        )
                      : const Text('Crear sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
