import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class StreakWidget extends StatelessWidget {
  final int streak;
  const StreakWidget({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: streak >= 7
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: streak > 0 ? AppColors.primary : AppColors.textDisabled,
                size: 20,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$streak',
            style: AppTextStyles.metricLarge,
          ),
          Text('días seguidos', style: AppTextStyles.labelMedium),
          Text(
            _streakMessage(streak),
            style: AppTextStyles.bodySmall.copyWith(
              color: streak > 0 ? AppColors.primary : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  String _streakMessage(int streak) {
    if (streak == 0) return 'Empieza hoy';
    if (streak < 7) return '¡Sigue así!';
    if (streak < 30) return 'Constancia real';
    return 'Eres imparable';
  }
}

