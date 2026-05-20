import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_card.dart';
import '../../widgets/option_chip.dart';

class Step2Goal extends ConsumerWidget {
  const Step2Goal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Objetivo y contexto', style: AppTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text('Esto define cómo calculamos tu programa y tu nutrición.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),

          _section('Objetivo principal', [
            OptionChip(
              label: 'Recomposición corporal',
              subtitle: 'Perder grasa y ganar músculo simultáneamente',
              selected: state.objetivo == 'recomposicion',
              icon: Icons.swap_horiz,
              onTap: () => notifier.setObjetivo('recomposicion'),
            ),
            OptionChip(
              label: 'Pérdida de grasa',
              subtitle: 'Déficit calórico para perder grasa preservando músculo',
              selected: state.objetivo == 'perdida_grasa',
              icon: Icons.trending_down,
              onTap: () => notifier.setObjetivo('perdida_grasa'),
            ),
            OptionChip(
              label: 'Ganancia muscular',
              subtitle: 'Superávit limpio para maximizar síntesis proteica',
              selected: state.objetivo == 'ganancia_muscular',
              icon: Icons.trending_up,
              onTap: () => notifier.setObjetivo('ganancia_muscular'),
            ),
          ]),

          const SizedBox(height: 16),

          _section('Días disponibles por semana', [
            Row(
              children: [2, 3, 4, 5].map((d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _DayButton(
                    days: d,
                    selected: state.diasDisponibles == d,
                    onTap: () => notifier.setDiasDisponibles(d),
                  ),
                ),
              )).toList(),
            ),
          ]),

          const SizedBox(height: 16),

          _section('Nivel de experiencia', [
            OptionChip(
              label: 'Principiante',
              subtitle: 'Menos de 1 año entrenando con pesas',
              selected: state.nivelExperiencia == 'principiante',
              icon: Icons.star_border,
              onTap: () => notifier.setNivel('principiante'),
            ),
            OptionChip(
              label: 'Intermedio',
              subtitle: 'Entre 1 y 3 años entrenando con continuidad',
              selected: state.nivelExperiencia == 'intermedio',
              icon: Icons.star_half,
              onTap: () => notifier.setNivel('intermedio'),
            ),
            OptionChip(
              label: 'Avanzado',
              subtitle: 'Más de 3 años entrenando con progresión sistemática',
              selected: state.nivelExperiencia == 'avanzado',
              icon: Icons.star,
              onTap: () => notifier.setNivel('avanzado'),
            ),
          ]),

          const SizedBox(height: 16),

          _section('Equipamiento disponible', [
            OptionChip(
              label: 'Gimnasio completo',
              subtitle: 'Acceso a barras, poleas, máquinas y mancuernas',
              selected: state.equipamiento == 'gimnasio',
              icon: Icons.fitness_center,
              onTap: () => notifier.setEquipamiento('gimnasio'),
            ),
            OptionChip(
              label: 'Mancuernas en casa',
              subtitle: 'Mancuernas ajustables y banco opcional',
              selected: state.equipamiento == 'mancuernas',
              icon: Icons.home,
              onTap: () => notifier.setEquipamiento('mancuernas'),
            ),
            OptionChip(
              label: 'Peso corporal',
              subtitle: 'Sin equipamiento — calistenia y ejercicios funcionales',
              selected: state.equipamiento == 'peso_corporal',
              icon: Icons.accessibility_new,
              onTap: () => notifier.setEquipamiento('peso_corporal'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return OnboardingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final int days;
  final bool selected;
  final VoidCallback onTap;
  const _DayButton({required this.days, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$days',
              style: AppTextStyles.displaySmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            Text(
              'días',
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? Colors.white70 : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
