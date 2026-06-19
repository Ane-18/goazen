import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/constants/app_constants.dart';

final _sessionExercisesProvider = FutureProvider.family<List<SessionExercise>, int>(
  (ref, sessionId) =>
      ref.watch(databaseProvider).workoutDao.getSessionExercises(sessionId),
);

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const ActiveSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  int _currentExerciseIndex = 0;
  DateTime _sessionStart = DateTime.now();
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _restTimerActive = false;
  double _sessionRpe = 7.0;
  bool _saving = false;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = seconds;
      _restTimerActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        t.cancel();
        setState(() => _restTimerActive = false);
      }
    });
  }

  Future<void> _finishSession(List<SessionExercise> exercises) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final elapsed = DateTime.now().difference(_sessionStart).inMinutes;

      double totalVolume = 0;
      double rpeSum = 0;
      int rpeCount = 0;

      for (final se in exercises) {
        final sets = await db.workoutDao.getSetsForSessionExercise(se.id);
        for (final s in sets) {
          if (s.completado) {
            totalVolume += s.pesoKg * s.reps;
            if (s.rpe != null) {
              rpeSum += s.rpe!;
              rpeCount++;
            }
          }
        }
      }

      final rpeAvg = rpeCount > 0 ? rpeSum / rpeCount : _sessionRpe;

      await db.workoutDao.updateSession(WorkoutSessionsCompanion(
        id: drift.Value(widget.sessionId),
        duracionMin: drift.Value(elapsed),
        volumenTotalKg: drift.Value(totalVolume),
        completada: const drift.Value(true),
        rpePromedioSesion: drift.Value(rpeAvg),
      ));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la sesión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync =
        ref.watch(_sessionExercisesProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Sesión activa'),
        titleTextStyle: AppTextStyles.headlineLarge,
        actions: [
          exercisesAsync.when(
            data: (exercises) => TextButton(
              onPressed: () => _showFinishDialog(context, exercises),
              child: Text('Finalizar',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          final mainExercises =
              exercises.where((e) => !e.esCalentamiento).toList();
          if (mainExercises.isEmpty) {
            return const Center(child: Text('No hay ejercicios en esta sesión'));
          }
          if (_currentExerciseIndex >= mainExercises.length) {
            return _buildSummary(mainExercises);
          }
          return _buildExerciseView(mainExercises);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildExerciseView(List<SessionExercise> exercises) {
    final se = exercises[_currentExerciseIndex];
    final total = exercises.length;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Text(
                '${_currentExerciseIndex + 1} / $total',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentExerciseIndex + 1) / total,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise info
                _ExerciseHeader(sessionExerciseId: se.id, exerciseId: se.exerciseId),
                const SizedBox(height: 16),

                // Rest timer
                if (_restTimerActive) _RestTimerWidget(seconds: _restSeconds),
                if (_restTimerActive) const SizedBox(height: 12),

                // Sets
                _SetsWidget(
                  sessionExerciseId: se.id,
                  setsObjetivo: se.setsObjetivo,
                  pesoSugerido: se.pesoSugeridoKg,
                  repsMin: se.repsMin,
                  repsMax: se.repsMax,
                  onSetCompleted: (restType) =>
                      _startRest(restType == 'fuerza'
                          ? AppConstants.restStrength
                          : AppConstants.restHypertrophy),
                ),

                const SizedBox(height: 16),

                // RPE
                _RpeSelector(
                  value: _sessionRpe,
                  onChanged: (v) => setState(() => _sessionRpe = v),
                ),

                const SizedBox(height: 24),

                // Navigation
                Row(
                  children: [
                    if (_currentExerciseIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(
                              () => _currentExerciseIndex--),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Anterior'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.surfaceElevated),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (_currentExerciseIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => setState(() {
                          if (_currentExerciseIndex < exercises.length - 1) {
                            _currentExerciseIndex++;
                          }
                        }),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          _currentExerciseIndex == exercises.length - 1
                              ? 'Finalizar'
                              : 'Siguiente ejercicio',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(List<SessionExercise> exercises) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.success, size: 80),
            const SizedBox(height: 20),
            Text('¡Sesión completada!', style: AppTextStyles.displayMedium),
            const SizedBox(height: 12),
            Text(
              'Cada sesión te acerca a tu objetivo.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : () => _finishSession(exercises),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.home),
              label: Text(_saving ? 'Guardando...' : 'Guardar y volver'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFinishDialog(
      BuildContext context, List<SessionExercise> exercises) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Finalizar sesión'),
        content: const Text(
            '¿Finalizar la sesión y guardar el progreso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _finishSession(exercises);
    }
  }
}

class _ExerciseHeader extends ConsumerWidget {
  final int sessionExerciseId;
  final int exerciseId;
  const _ExerciseHeader(
      {required this.sessionExerciseId, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Exercise?>(
      future: ref.read(databaseProvider).exerciseDao.getExerciseById(exerciseId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final ex = snap.data!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ex.nombre, style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  _chip(ex.grupoMuscular, AppColors.primary),
                  const SizedBox(width: 6),
                  _chip(ex.equipamientoRequerido, AppColors.info),
                  const SizedBox(width: 6),
                  _chip('Tempo ${ex.tempo}', AppColors.surfaceElevated),
                ],
              ),
              if (ex.urlGif.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ex.urlGif,
                    fit: BoxFit.contain,
                    height: 160,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(ex.descripcionTecnica,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              if (ex.erroresComunes.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Ver errores comunes',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning)),
                  iconColor: AppColors.warning,
                  children: ex.erroresComunes
                      .split('\n')
                      .map((e) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber,
                                color: AppColors.warning, size: 16),
                            title: Text(e,
                                style: AppTextStyles.bodySmall),
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child:
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
      );
}

class _RestTimerWidget extends StatelessWidget {
  final int seconds;
  const _RestTimerWidget({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppColors.info),
          const SizedBox(width: 10),
          Text('Descanso: ', style: AppTextStyles.labelLarge),
          Text(
            '${seconds}s',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class _SetsWidget extends ConsumerStatefulWidget {
  final int sessionExerciseId;
  final int setsObjetivo;
  final double pesoSugerido;
  final int repsMin;
  final int repsMax;
  final ValueChanged<String> onSetCompleted;

  const _SetsWidget({
    required this.sessionExerciseId,
    required this.setsObjetivo,
    required this.pesoSugerido,
    required this.repsMin,
    required this.repsMax,
    required this.onSetCompleted,
  });

  @override
  ConsumerState<_SetsWidget> createState() => _SetsWidgetState();
}

class _SetsWidgetState extends ConsumerState<_SetsWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseSet>>(
      future: ref
          .read(databaseProvider)
          .workoutDao
          .getSetsForSessionExercise(widget.sessionExerciseId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final sets = snap.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Series', style: AppTextStyles.headlineSmall),
                const Spacer(),
                Text(
                  '${widget.repsMin}–${widget.repsMax} reps',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...sets.map((set) => _SetRow(
                  set: set,
                  onUpdated: () => setState(() {}),
                  onSetCompleted: widget.onSetCompleted,
                )),
          ],
        );
      },
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final ExerciseSet set;
  final VoidCallback onUpdated;
  final ValueChanged<String> onSetCompleted;

  const _SetRow({
    required this.set,
    required this.onUpdated,
    required this.onSetCompleted,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _pesoCtrl;
  late TextEditingController _repsCtrl;
  double _rpe = 7.0;

  @override
  void initState() {
    super.initState();
    _pesoCtrl = TextEditingController(
        text: widget.set.pesoKg > 0 ? widget.set.pesoKg.toString() : '');
    _repsCtrl = TextEditingController(
        text: widget.set.reps > 0 ? widget.set.reps.toString() : '');
    _rpe = widget.set.rpe ?? 7.0;
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleComplete() async {
    final peso = double.tryParse(_pesoCtrl.text) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    final newCompleted = !widget.set.completado;

    await ref.read(databaseProvider).workoutDao.updateExerciseSet(
      ExerciseSetsCompanion(
        id: drift.Value(widget.set.id),
        pesoKg: drift.Value(peso),
        reps: drift.Value(reps),
        completado: drift.Value(newCompleted),
        rpe: drift.Value(_rpe),
      ),
    );

    if (newCompleted) {
      widget.onSetCompleted('hipertrofia');
    }
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.set.completado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: completed
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.surfaceElevated,
          ),
        ),
        child: Row(
          children: [
            Text(
              'S${widget.set.numeroSet}',
              style: AppTextStyles.labelLarge.copyWith(
                color: completed ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'kg',
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
                ),
              ),
            ),
            const Text('×', style: TextStyle(color: AppColors.textDisabled)),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'reps',
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // RPE mini
            SizedBox(
              width: 60,
              child: DropdownButton<double>(
                value: _rpe,
                isDense: true,
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                items: [6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10]
                    .map((r) => DropdownMenuItem(
                          value: r.toDouble(),
                          child: Text('RPE $r',
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _rpe = v!),
              ),
            ),
            GestureDetector(
              onTap: () => _showRpeHelpDialog(context),
              child: const Icon(Icons.info_outline, size: 13, color: AppColors.textDisabled),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _toggleComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: completed ? AppColors.success : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Icons.check : Icons.radio_button_unchecked,
                  color: completed ? Colors.white : AppColors.textDisabled,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRpeHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('¿Qué es el RPE?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RPE = esfuerzo percibido (1-10).',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 12),
          ...[
            ('10', 'Al fallo total — no podías hacer ni una rep más.'),
            ('9', '1 repetición en el tanque.'),
            ('8', '2 reps en el tanque — serie muy exigente.'),
            ('7', '3–4 reps en el tanque — esfuerzo notable.'),
            ('6', 'Serie cómoda, con margen de sobra.'),
          ].map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        r.$1,
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(r.$2, style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Text(
            'Ser precisa con el RPE ayuda a la app a ajustar el peso la semana siguiente.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _RpeSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _RpeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RPE de la sesión', style: AppTextStyles.labelLarge),
              Row(
                children: [
                  Text(
                    '${value.toStringAsFixed(1)} / 10',
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showRpeHelpDialog(context),
                    child: const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_rpeDescription(value), style: AppTextStyles.bodySmall),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _rpeColor(value),
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: _rpeColor(value),
              overlayColor: _rpeColor(value).withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 18,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _rpeDescription(double rpe) {
    if (rpe <= 5) return 'Muy fácil — podrías hacer muchas más reps';
    if (rpe <= 6.5) return 'Fácil — buena técnica, sin fatiga significativa';
    if (rpe <= 7.5) return 'Moderado — esfuerzo notable, técnica intacta';
    if (rpe <= 8.5) return 'Duro — pocas reps en reserva';
    if (rpe < 10) return 'Muy duro — 1 rep en reserva';
    return 'Máximo esfuerzo — al fallo';
  }

  Color _rpeColor(double rpe) {
    if (rpe <= 6) return AppColors.success;
    if (rpe <= 8) return AppColors.warning;
    return AppColors.error;
  }
}

