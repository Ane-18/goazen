import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingCard extends StatelessWidget {
  final Widget child;
  const OnboardingCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: child,
    );
  }
}
