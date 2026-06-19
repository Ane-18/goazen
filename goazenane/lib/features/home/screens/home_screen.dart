import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../widgets/metric_card.dart';
import '../widgets/phase_badge.dart';
import '../widgets/streak_widget.dart';
import '../widgets/alert_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final sleep = ref.watch(todaySleepProvider);
    final wearable = ref.watch(todayWearableProvider);
    final streak = ref.watch(trainingStreakProvider);
    final program = ref.watch(activeProgramProvider);
    final weekProgress = ref.watch(weeklyProgressProvider);
    final avgWeight = ref.watch(averageWeightLast7Provider);
    final sleepAlert = ref.watch(sleepAlertProvider);
    final hrAlert = ref.watch(hrAlertProvider);
    // Siembra ejercicios nuevos silenciosamente al abrir home por primera vez.
    ref.watch(exerciseSeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            title: user.when(
              data: (u) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${u?.nombre.split(' ').first ?? ''}',
                    style: AppTextStyles.headlineLarge,
                  ),
                  Text(
                    DateFormat('EEEE, d MMM', 'es').format(DateTime.now()),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            actions: [
              if (user.value?.tieneMiBand == true)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.bluetooth_connected,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: user.when(
                  data: (u) => PhaseBadge(
                    phase: u?.faseCicloActual ?? 'folicular',
                    compact: true,
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Alertas de sueño / FC
                sleepAlert.when(
                  data: (msg) => msg != null ? AlertBanner(message: msg, type: AlertType.sleep) : const SizedBox(),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                hrAlert.when(
                  data: (msg) => msg != null ? AlertBanner(message: msg, type: AlertType.hr) : const SizedBox(),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),

                // Racha + sesión de hoy
                Row(
                  children: [
                    Expanded(
                      child: streak.when(
                        data: (s) => StreakWidget(streak: s),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TodaySessionCard(program: program.value),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Métricas principales
                Row(
                  children: [
                    Expanded(
                      child: avgWeight.when(
                        data: (w) => MetricCard(
                          label: 'Peso (7 días)',
                          value: w != null ? '${w.toStringAsFixed(1)} kg' : '--',
                          icon: Icons.monitor_weight_outlined,
                          subtitle: 'Media semanal',
                          color: AppColors.info,
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: sleep.when(
                        data: (s) => MetricCard(
                          label: 'Sueño',
                          value: s != null ? '${s.horasTotales.toStringAsFixed(1)}h' : '--',
                          icon: Icons.bedtime_outlined,
                          subtitle: s?.horasProfundo != null && s!.horasTotales > 0
                              ? '${(s.horasProfundo! / s.horasTotales * 100).round()}% profundo'
                              : 'Sin datos hoy',
                          color: AppColors.info,
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: wearable.when(
                        data: (w) => MetricCard(
                          label: 'FC reposo',
                          value: w?.fcReposo != null ? '${w!.fcReposo!.round()} bpm' : '--',
                          icon: Icons.favorite_border,
                          subtitle: 'Esta mañana',
                          color: AppColors.error,
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: wearable.when(
                        data: (w) => MetricCard(
                          label: 'Pasos',
                          value: w?.pasos != null ? '${w!.pasos}' : '--',
                          icon: Icons.directions_walk,
                          subtitle: 'Hoy',
                          color: AppColors.success,
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progreso semanal
                weekProgress.when(
                  data: (completed) => _WeeklyProgressCard(
                    completed: completed,
                    target: user.value?.diasDisponibles ?? 3,
                  ),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),

                // Botón iniciar sesión
                FilledButton.icon(
                  onPressed: () => context.go('/workout'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar entrenamiento de hoy'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTextStyles.headlineSmall,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  final WorkoutProgram? program;
  const _TodaySessionCard({this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text('Sesión hoy', style: AppTextStyles.labelMedium),
          const SizedBox(height: 4),
          Text(
            program != null ? 'Semana ${program!.semanaActual}' : 'Sin programa',
            style: AppTextStyles.headlineSmall,
          ),
          if (program != null)
            Text(
              _phaseLabel(program!.faseActual),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  String _phaseLabel(String fase) {
    switch (fase) {
      case 'acumulacion': return 'Acumulación';
      case 'intensificacion': return 'Intensificación';
      case 'pico': return 'Pico';
      default: return fase;
    }
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  final int completed;
  final int target;
  const _WeeklyProgressCard({required this.completed, required this.target});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Esta semana', style: AppTextStyles.headlineSmall),
              Text('$completed / $target sesiones',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(target, (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < completed ? AppColors.success : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
