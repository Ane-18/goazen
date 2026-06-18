import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_card.dart';
import '../../widgets/labeled_slider.dart';

class Step1Physical extends ConsumerWidget {
  const Step1Physical({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perfil físico', style: AppTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Necesitamos estos datos para calcular tus necesidades energéticas con precisión.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: state.nombre,
                  onChanged: notifier.setNombre,
                  style: AppTextStyles.bodyLarge,
                  decoration: _inputDec('¿Cómo te llamas?'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha de nacimiento', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.fechaNacimiento ?? DateTime(1995),
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) notifier.setFechaNacimiento(date);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          state.fechaNacimiento != null
                              ? '${state.fechaNacimiento!.day}/${state.fechaNacimiento!.month}/${state.fechaNacimiento!.year}'
                              : 'Seleccionar fecha',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: state.fechaNacimiento != null
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              children: [
                LabeledSlider(
                  label: 'Peso actual',
                  value: state.pesoKg,
                  min: 40,
                  max: 150,
                  unit: 'kg',
                  decimals: 1,
                  onChanged: notifier.setPeso,
                ),
                const Divider(color: AppColors.surfaceElevated, height: 24),
                LabeledSlider(
                  label: 'Altura',
                  value: state.alturaCm,
                  min: 140,
                  max: 200,
                  unit: 'cm',
                  onChanged: notifier.setAltura,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('% de grasa corporal', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  'Usa una báscula de bioimpedancia o estima visualmente.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                LabeledSlider(
                  label: '% Grasa',
                  value: state.porcentajeGrasa,
                  min: 10,
                  max: 50,
                  unit: '%',
                  decimals: 1,
                  onChanged: notifier.setPorcentajeGrasa,
                ),
                const SizedBox(height: 12),
                Text('O calcula desde circunferencias', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _circumField('Cintura (cm)', (v) => notifier.setCintura(double.tryParse(v)))),
                    const SizedBox(width: 8),
                    Expanded(child: _circumField('Cadera (cm)', (v) => notifier.setCadera(double.tryParse(v)))),
                    const SizedBox(width: 8),
                    Expanded(child: _circumField('Cuello (cm)', (v) => notifier.setCuello(double.tryParse(v)))),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: notifier.estimateBodyFatFromCircumferences,
                    child: const Text('Calcular % grasa'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circumField(String label, ValueChanged<String> onChanged) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: AppTextStyles.bodyLarge,
      decoration: _inputDec(label),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

