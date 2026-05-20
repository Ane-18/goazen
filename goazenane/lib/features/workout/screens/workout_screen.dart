import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/workout_generator.dart';
import '../../../core/database/app_database.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final program = ref.watch(activeProgramProvider);
    final sessionState = ref.watch(workoutSessionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Entrenar'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            user.when(
              data: (u) {
                if (u == null) return const SizedBox();
                return _ProgramCard(user: u, program: program.value);
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 16),

            // Cardio recomendado
            user.when(
              data: (u) {
                if (u == null) return const SizedBox();
                final cardio = WorkoutGenerator.getCardioRecommendation(
                  u.faseCicloActual,
                  DateTime.now().year - u.fechaNacimiento.year,
                );
                return _CardioCard(cardio: cardio, fase: u.faseCicloActual);
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Botón principal
            sessionState.when(
              data: (session) {
                if (session != null && !session.completada) {
                  return Column(
                    children: [
                      _SessionInProgressBanner(session: session),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.go('/warmup/${session.id}'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Continuar sesión de hoy'),
                        style: _primaryBtnStyle(),
                      ),
                    ],
                  );
                }
                if (session != null && session.completada) {
                  return _SessionCompletedCard(session: session);
                }
                return FilledButton.icon(
                  onPressed: () => _startSession(context, ref),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Generar sesión de hoy'),
                  style: _primaryBtnStyle(),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text(e.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSession(BuildContext context, WidgetRef ref) async {
    try {
      final id = await ref
          .read(workoutSessionNotifierProvider.notifier)
          .generateAndStartSession();
      if (context.mounted) {
        context.go('/warmup/$id');
      }
    } catch (e) {
      if (e.toString().contains('sleep_critical') && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Con menos de 5h de sueño, hoy toca movilidad o descanso activo.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  ButtonStyle _primaryBtnStyle() => FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.headlineSmall,
      );
}

class _ProgramCard extends StatelessWidget {
  final User user;
  final WorkoutProgram? program;
  const _ProgramCard({required this.user, this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tu programa', style: AppTextStyles.headlineMedium),
              if (program?.enDeload == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('DELOAD',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (program != null) ...[
            _infoRow('Semana', '${program!.semanaActual} / 12'),
            _infoRow('Fase', _phaseLabel(program!.faseActual)),
            _infoRow('División', _divisionLabel(program!.divisionTipo)),
            _infoRow('Días/semana', '${user.diasDisponibles}'),
          ] else ...[
            Text('Primer entrenamiento → se genera tu programa de 12 semanas',
                style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  String _phaseLabel(String f) {
    switch (f) {
      case 'acumulacion': return 'Acumulación';
      case 'intensificacion': return 'Intensificación';
      case 'pico': return 'Pico';
      default: return f;
    }
  }

  String _divisionLabel(String d) {
    switch (d) {
      case 'full_body': return 'Full Body';
      case 'torso_pierna': return 'Torso / Pierna';
      case 'ppl': return 'Push Pull Legs';
      default: return d;
    }
  }
}

class _CardioCard extends StatelessWidget {
  final Map<String, dynamic> cardio;
  final String fase;
  const _CardioCard({required this.cardio, required this.fase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_run, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Cardio recomendado hoy', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cardio['descripcion'] as String,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('${cardio['duracion_min']} min', AppColors.success),
              const SizedBox(width: 8),
              _chip('${cardio['frecuencia_semana']}x/semana', AppColors.info),
              const SizedBox(width: 8),
              _chip(_tipoLabel(cardio['tipo'] as String), AppColors.primary),
            ],
          ),
          if (cardio.containsKey('fc_min')) ...[
            const SizedBox(height: 6),
            Text(
              'FC objetivo: ${cardio['fc_min']}–${cardio['fc_max']} bpm (60–70% FCmax)',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: color)),
      );

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'liss': return 'LISS';
      case 'hiit_tabata': return 'HIIT Tabata';
      case 'hiit_intervalos': return 'HIIT Intervalos';
      default: return tipo;
    }
  }
}

class _SessionInProgressBanner extends StatelessWidget {
  final WorkoutSession session;
  const _SessionInProgressBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tienes una sesión en progreso — ${_dayLabel(session.diaTipo)}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(String tipo) {
    switch (tipo) {
      case 'full_body': return 'Full Body';
      case 'torso': return 'Torso';
      case 'pierna': return 'Pierna';
      case 'empuje': return 'Empuje';
      case 'tiron': return 'Tirón';
      default: return tipo;
    }
  }
}

class _SessionCompletedCard extends StatelessWidget {
  final WorkoutSession session;
  const _SessionCompletedCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Sesión completada!', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.success)),
                Text(
                  'Volumen total: ${session.volumenTotalKg.round()} kg · ${session.duracionMin} min',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

