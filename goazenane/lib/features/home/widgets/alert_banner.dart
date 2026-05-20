import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

enum AlertType { sleep, hr, deload }

class AlertBanner extends StatelessWidget {
  final String message;
  final AlertType type;
  const AlertBanner({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _config(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: config.$1.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: config.$1.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(config.$2, color: config.$1, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.bodySmall.copyWith(color: config.$1)),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _config(AlertType type) {
    switch (type) {
      case AlertType.sleep:
        return (AppColors.info, Icons.bedtime_outlined);
      case AlertType.hr:
        return (AppColors.error, Icons.favorite_border);
      case AlertType.deload:
        return (AppColors.warning, Icons.shield_outlined);
    }
  }
}

