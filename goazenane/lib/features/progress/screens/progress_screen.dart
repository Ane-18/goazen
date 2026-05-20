import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../home/providers/home_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Progreso'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      body: user.when(
        data: (u) {
          if (u == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              // Peso semanal
              _WeightChart(userId: u.id),
              const SizedBox(height: 16),

              // Acciones rápidas
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.photo_camera,
                      label: 'Foto progreso',
                      onTap: () => context.go('/photos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.straighten,
                      label: 'Medidas',
                      onTap: () => context.go('/body-metrics'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sueño vs rendimiento
              _SleepPerformanceChart(userId: u.id),
              const SizedBox(height: 16),

              // Rachas
              _StreaksSummary(userId: u.id),
              const SizedBox(height: 16),

              // Logros
              _AchievementsGrid(userId: u.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

class _WeightChart extends ConsumerWidget {
  final int userId;
  const _WeightChart({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<BodyMetric>>(
      future: ref.read(databaseProvider).userDao.getBodyMetrics(userId),
      builder: (context, snap) {
        final metrics = snap.data ?? [];
        if (metrics.isEmpty) {
          return _emptyCard('Peso semanal', 'Aún no hay datos de peso registrados.');
        }

        final recent = metrics.take(30).toList().reversed.toList();
        final spots = recent.asMap().entries.map((e) =>
          FlSpot(e.key.toDouble(), e.value.pesoKg)
        ).toList();

        final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
        final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

        // Media 7 días
        final last7 = metrics.take(7).map((m) => m.pesoKg).toList();
        final avg7 = last7.isEmpty ? 0 : last7.fold<double>(0, (a, b) => a + b) / last7.length;

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
                  Text('Peso corporal', style: AppTextStyles.headlineMedium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${avg7.toStringAsFixed(1)} kg', style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary)),
                      Text('media 7 días', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Media semanal — elimina el ruido hormonal', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.chartGrid,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            v.toStringAsFixed(0),
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.chartLine,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.chartFill,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepPerformanceChart extends ConsumerWidget {
  final int userId;
  const _SleepPerformanceChart({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<SleepLogData>>(
      future: ref.read(databaseProvider).sleepDao.getSleepHistory(userId, limit: 14),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return _emptyCard('Sueño', 'Registra tu sueño diariamente para ver la correlación con tu rendimiento.');
        }

        final reversed = logs.reversed.toList();
        final sleepSpots = reversed.asMap().entries.map((e) =>
          FlSpot(e.key.toDouble(), e.value.horasTotales)
        ).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sueño — 14 días', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('El sueño ES parte del entrenamiento.', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barGroups: reversed.asMap().entries.map((e) {
                      final hours = e.value.horasTotales;
                      final color = hours >= 7
                          ? AppColors.success
                          : hours >= 6
                              ? AppColors.warning
                              : AppColors.error;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: hours,
                            color: color,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legend(AppColors.success, '≥7h'),
                  const SizedBox(width: 12),
                  _legend(AppColors.warning, '6–7h'),
                  const SizedBox(width: 12),
                  _legend(AppColors.error, '<6h'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _StreaksSummary extends ConsumerWidget {
  final int userId;
  const _StreaksSummary({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        ref.read(databaseProvider).workoutDao.getTrainingStreak(userId),
        ref.read(databaseProvider).nutritionDao.getMacroStreak(userId),
        ref.read(databaseProvider).sleepDao.getSleepStreak(userId),
      ]),
      builder: (context, snap) {
        final data = snap.data ?? [0, 0, 0];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rachas activas', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StreakItem(icon: Icons.fitness_center, label: 'Entrenos', streak: data[0], color: AppColors.primary),
                  _StreakItem(icon: Icons.restaurant, label: 'Macros', streak: data[1], color: AppColors.success),
                  _StreakItem(icon: Icons.bedtime, label: 'Sueño ≥7h', streak: data[2], color: AppColors.info),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int streak;
  final Color color;
  const _StreakItem({required this.icon, required this.label, required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: streak > 0 ? color : AppColors.textDisabled),
          const SizedBox(height: 4),
          Text('$streak', style: AppTextStyles.displaySmall.copyWith(color: color)),
          Text('días', style: AppTextStyles.bodySmall),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends ConsumerWidget {
  final int userId;
  const _AchievementsGrid({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Achievement>>(
      future: ref.read(databaseProvider).userDao.getAchievements(userId),
      builder: (context, snap) {
        final achieved = snap.data ?? [];
        const allAchievements = [
          ('primera_semana', 'Primera semana', Icons.calendar_today),
          ('primer_pr', 'Primer PR', Icons.emoji_events),
          ('30_dias', '30 días seguidos', Icons.local_fire_department),
          ('fase_completa', 'Fase completada', Icons.flag),
          ('primera_foto', 'Primera foto', Icons.photo_camera),
          ('hidratacion_7', 'Hidratación 7 días', Icons.water_drop),
          ('suenio_7', 'Sueño ≥7h 7 días', Icons.bedtime),
          ('sin_deload', 'Sin deload', Icons.shield),
        ];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Logros', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: allAchievements.map((a) {
                  final unlocked = achieved.any((ach) => ach.tipoLogro == a.$1);
                  return Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: unlocked
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          a.$3,
                          color: unlocked ? AppColors.success : AppColors.textDisabled,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.$2,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: unlocked ? AppColors.textPrimary : AppColors.textDisabled,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.labelLarge),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

Widget _emptyCard(String title, String msg) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.headlineMedium),
      const SizedBox(height: 8),
      Text(msg, style: AppTextStyles.bodyMedium),
    ],
  ),
);
