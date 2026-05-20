import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MacroRing extends StatelessWidget {
  final double value;
  final double max;
  final Color color;
  final String label;

  const MacroRing({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${(pct * 100).round()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
        Text('${value.round()}g', style: AppTextStyles.labelMedium),
      ],
    );
  }
}
