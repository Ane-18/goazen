import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_card.dart';
import '../../widgets/option_chip.dart';

class Step3Health extends ConsumerStatefulWidget {
  const Step3Health({super.key});

  @override
  ConsumerState<Step3Health> createState() => _Step3HealthState();
}

class _Step3HealthState extends ConsumerState<Step3Health> {
  static const _zonas = [
    ('rodillas', 'Rodillas'),
    ('lumbar', 'Espalda baja'),
    ('hombro', 'Hombro'),
    ('muñeca', 'Muñeca'),
    ('cadera', 'Cadera'),
    ('codo', 'Codo'),
    ('cervical', 'Cervical'),
  ];

  static const _fases = [
    ('menstruacion', 'Menstruación', 'Día 1-5 del ciclo', Icons.water_drop),
    ('folicular', 'Folicular', 'Día 6-13 — alta energía', Icons.arrow_upward),
    ('ovulacion', 'Ovulación', 'Día 14 — pico de rendimiento', Icons.flash_on),
    ('lutea', 'Lútea', 'Día 15-28 — más fatiga', Icons.arrow_downward),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salud y limitaciones', style: AppTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text('Esta información nos permite adaptar tu programa con seguridad.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zonas con lesiones o molestias', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text('Marcá las zonas que quieres excluir de los ejercicios.',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _zonas.map((zona) {
                    final selected = state.limitaciones.contains(zona.$1);
                    return FilterChip(
                      label: Text(zona.$2),
                      selected: selected,
                      onSelected: (_) {
                        final current = List<String>.from(state.limitaciones);
                        if (selected) {
                          current.remove(zona.$1);
                        } else {
                          current.add(zona.$1);
                        }
                        notifier.setLimitaciones(current);
                      },
                      backgroundColor: AppColors.surfaceVariant,
                      selectedColor: AppColors.error.withOpacity(0.3),
                      checkmarkColor: AppColors.error,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: selected ? AppColors.error : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.error : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Fase del ciclo menstrual actual',
                        style: AppTextStyles.labelLarge),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Ajustamos el entrenamiento y la nutrición\na tu fisiología real (Stacy Sims, 2022)',
                      child: const Icon(Icons.info_outline,
                          size: 16, color: AppColors.info),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Esto nos permite ajustar tu entrenamiento y nutrición a tu fisiología real.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                ..._fases.map((fase) => OptionChip(
                      label: fase.$2,
                      subtitle: fase.$3,
                      selected: state.faseCicloActual == fase.$1,
                      icon: fase.$4,
                      onTap: () => notifier.setFaseCiclo(fase.$1),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Usas anticonceptivos hormonales?',
                          style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Algunos anticonceptivos eliminan la variabilidad cíclica natural.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.usaAnticonceptivos,
                  onChanged: notifier.setUsaAnticonceptivos,
                  activeColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                ),
              ],
            ),
          ),

          if (state.usaAnticonceptivos) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los ajustes por ciclo menstrual se desactivarán. Tu plan se basará en principios generales de rendimiento.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.infoLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
