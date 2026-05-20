import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_card.dart';

class Step5Wearable extends ConsumerWidget {
  const Step5Wearable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispositivo wearable', style: AppTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text(
            'La integración con Mi Band 3 mejora la precisión de tus ajustes automáticos.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¿Tienes Mi Band o dispositivo Xiaomi?',
                              style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Sincronizamos FC en reposo, sueño, pasos y calorías activas.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.tieneMiBand,
                      onChanged: notifier.setTieneMiBand,
                      activeColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (state.tieneMiBand) ...[
            const SizedBox(height: 12),
            OnboardingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos que sincronizaremos', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  ...[
                    (Icons.favorite_border, 'FC en reposo matutina', 'Detecta sobreentreno y activa deloads', AppColors.error),
                    (Icons.bedtime_outlined, 'Horas de sueño', 'Ajusta el volumen de entrenamiento del día', AppColors.info),
                    (Icons.directions_walk, 'Pasos diarios', 'Recalcula tu TDEE real semanalmente', AppColors.success),
                    (Icons.local_fire_department_outlined, 'Calorías activas', 'Verifica el factor de actividad', AppColors.warning),
                    (Icons.monitor_heart_outlined, 'FC durante cardio', 'Confirma que estás en zona LISS o HIIT', AppColors.primary),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.$4.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.$1, color: item.$4, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2, style: AppTextStyles.labelLarge),
                              Text(item.$3, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Todos los datos del wearable se almacenan 100% en local.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.successLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!state.tieneMiBand) ...[
            const SizedBox(height: 12),
            OnboardingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sin wearable', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Sin problema. Todos los campos son de entrada manual. '
                    'Registrarás el sueño y la FC en reposo manualmente cada mañana '
                    'y la app aplicará los mismos ajustes inteligentes.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF242424)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base científica', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Schoenfeld (2010, 2016) · Israetel et al. · Helms (2014) · Stacy Sims (2022)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

