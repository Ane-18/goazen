import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PhaseBadge extends StatelessWidget {
  final String phase;
  final bool compact;
  const PhaseBadge({super.key, required this.phase, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final config = _phaseConfig(phase);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.$3, color: config.$1, size: compact ? 12 : 16),
          const SizedBox(width: 4),
          Text(
            compact ? config.$2 : 'Fase ${config.$2}',
            style: (compact ? AppTextStyles.bodySmall : AppTextStyles.labelMedium)
                .copyWith(color: config.$1),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _phaseConfig(String phase) {
    switch (phase) {
      case 'menstruacion':
        return (AppColors.phaseMenstrual, 'Menstrual', Icons.water_drop);
      case 'folicular':
        return (AppColors.phaseFolicular, 'Folicular', Icons.arrow_upward);
      case 'ovulacion':
        return (AppColors.phaseOvulacion, 'Ovulación', Icons.flash_on);
      case 'lutea':
        return (AppColors.phaseLutea, 'Lútea', Icons.arrow_downward);
      default:
        return (AppColors.phaseFolicular, 'Folicular', Icons.arrow_upward);
    }
  }
}

