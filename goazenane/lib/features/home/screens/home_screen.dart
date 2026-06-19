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
import '../widgets/macro_ring.dart';
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
    final macroProgress = ref.watch(todayMacroProgressProvider);
    final nutritionPlan = ref.watch(todayNutritionPlanProvider);

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

                // Progreso de macros del día
                _MacroProgressSection(
                  macros: macroProgress.value ?? {},
                  plan: nutritionPlan.value,
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

class _MacroProgressSection extends StatelessWidget {
  final Map<String, double> macros;
  final NutritionPlan? plan;
  const _MacroProgressSection({required this.macros, this.plan});

  @override
  Widget build(BuildContext context) {
    final calConsumed = macros['calorias'] ?? 0;
    final calTarget = plan?.caloriasObjetivo ?? 2000;
    final protConsumed = macros['proteinas'] ?? 0;
    final protTarget = plan?.proteinasG ?? 150;

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
              Text('Nutrición de hoy', style: AppTextStyles.headlineSmall),
              Text(
                '${calConsumed.round()} / ${calTarget.round()} kcal',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MacroBar(label: 'Proteína', consumed: protConsumed, target: plan?.proteinasG ?? 150, color: AppColors.info),
          const SizedBox(height: 8),
          _MacroBar(label: 'Carbos', consumed: macros['carbos'] ?? 0, target: plan?.carbosG ?? 200, color: AppColors.warning),
          const SizedBox(height: 8),
          _MacroBar(label: 'Grasas', consumed: macros['grasas'] ?? 0, target: plan?.grasasG ?? 60, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  const _MacroBar({required this.label, required this.consumed, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (consumed / target).clamp(0, 1).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text('$label', style: AppTextStyles.labelMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${consumed.round()}g',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
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

