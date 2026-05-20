import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_card.dart';

class Step4Preferences extends ConsumerWidget {
  const Step4Preferences({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferencias', style: AppTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text('Ajusta la app a tu ritmo de vida.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duración máxima de sesión', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  'La app organiza los ejercicios para que termines a tiempo.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [45, 60, 75, 90].map((min) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => notifier.setDuracionSesion(min),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: state.duracionSesionMax == min
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$min',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: state.duracionSesionMax == min
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'min',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: state.duracionSesionMax == min
                                      ? Colors.white70
                                      : AppColors.textDisabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descargo de responsabilidad', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GOAZENANE es una herramienta educativa basada en evidencia científica. '
                    'No sustituye a un médico, nutricionista o entrenador profesional. '
                    'Consulta con un profesional de salud antes de iniciar cualquier programa de ejercicio, '
                    'especialmente si tienes condiciones de salud preexistentes.\n\n'
                    'Resultados realistas: 0.5–1 kg de músculo por mes es el máximo fisiológicamente posible '
                    'para mujeres en condiciones óptimas (Schoenfeld, 2010).',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacidad total', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lock, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Todos tus datos — fotos, métricas, historial de entrenamiento y datos del wearable — '
                        'se almacenan exclusivamente en tu dispositivo. '
                        'Sin servidores externos. Sin Firebase. Sin rastreo.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.successLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
