import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class HowRoutineWorksScreen extends StatelessWidget {
  const HowRoutineWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('¿Cómo funciona tu rutina?'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: const [
          _Section(
            icon: Icons.tune,
            title: '¿Cómo se eligen los ejercicios?',
            content: [
              _Paragraph(
                'Cuando generas una sesión, la app filtra el catálogo de ejercicios '
                'usando tres criterios que tú definiste en el onboarding:',
              ),
              _BulletPoint(
                'Equipamiento disponible',
                'Solo aparecen ejercicios que puedas hacer con lo que tienes (gimnasio completo, mancuernas, o solo peso corporal).',
              ),
              _BulletPoint(
                'Nivel de experiencia',
                'Los ejercicios avanzados quedan bloqueados hasta que el programa considera que estás lista para ellos.',
              ),
              _BulletPoint(
                'Lesiones y zonas de riesgo',
                'Si indicaste limitaciones (p. ej. "rodilla"), la app excluye automáticamente los ejercicios que implican carga en esa articulación.',
              ),
              _Paragraph(
                'Además, el tipo de sesión del día (Full Body, Torso, Pierna…) determina '
                'qué grupos musculares se trabajan. La app equilibra los patrones de movimiento '
                '— empuje, tirón, bisagra, sentadilla — para que no haya sobreentrenamiento.',
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            icon: Icons.trending_up,
            title: '¿Qué es la sobrecarga progresiva?',
            content: [
              _Paragraph(
                'El músculo solo crece si cada semana le das un estímulo ligeramente '
                'mayor que la semana anterior. Esto se llama sobrecarga progresiva.',
              ),
              _Paragraph(
                'La app lo gestiona así:',
              ),
              _BulletPoint(
                'Si completaste todas las series con buena técnica (RPE ≤ 8)',
                'La semana siguiente sube el peso un 2,5 %. Si no tienes ese peso exacto, usa el más cercano.',
              ),
              _BulletPoint(
                'Si no llegaste al rango de reps objetivo',
                'El peso se mantiene igual la semana siguiente hasta que lo consigas.',
              ),
              _BulletPoint(
                'Si el RPE fue muy alto (≥ 8,5) varios días seguidos',
                'La app baja el volumen o activa un deload para que te recuperes antes de volver a progresar.',
              ),
              _Paragraph(
                'Los números del peso sugerido que ves en cada serie no son arbitrarios: '
                'son el resultado de tu historial de las semanas anteriores.',
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            icon: Icons.flag_outlined,
            title: '¿Qué significa cada fase del programa?',
            content: [
              _PhaseCard(
                phase: 'Acumulación',
                weeks: 'Semanas 1–5',
                color: AppColors.success,
                description:
                    'Más series y repeticiones, pesos moderados. El objetivo es acumular '
                    'volumen de entrenamiento para crear el estímulo máximo de hipertrofia. '
                    'Es normal sentirse fatigada — es parte del proceso.',
              ),
              _PhaseCard(
                phase: 'Intensificación',
                weeks: 'Semanas 6–10',
                color: AppColors.warning,
                description:
                    'Menos series, más peso. Se reduce el volumen y sube la carga para '
                    'consolidar la fuerza ganada. Te sentirás más fresca pero los pesos '
                    'serán más exigentes.',
              ),
              _PhaseCard(
                phase: 'Pico',
                weeks: 'Semanas 11–12',
                color: AppColors.primary,
                description:
                    'Volumen bajo, intensidad alta. Es el momento de rendir al máximo '
                    'en los ejercicios principales. Aquí se expresan las ganancias del ciclo.',
              ),
              _PhaseCard(
                phase: 'Deload',
                weeks: 'Automático o entre bloques',
                color: AppColors.info,
                description:
                    'Una semana con el 40–50 % del volumen habitual y pesos ligeros. '
                    'No es perder el tiempo: el músculo se repara y crece durante el descanso. '
                    'El deload se activa automáticamente si el RPE promedio supera 8,5 varios '
                    'días o si la frecuencia cardíaca en reposo lleva 3 días elevada.',
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            icon: Icons.psychology_outlined,
            title: 'Por qué importa el RPE',
            content: [
              _Paragraph(
                'El RPE (esfuerzo percibido del 1 al 10) es la señal que le das a la app '
                'sobre cómo te encontraste en esa sesión. Sin ese dato, el algoritmo trabaja '
                'a ciegas.',
              ),
              _Paragraph(
                'Un RPE honesto → la app ajusta los pesos correctamente. '
                'Un RPE inflado → la app sube el peso demasiado rápido y aumenta el riesgo de lesión. '
                'Un RPE deflado → la app no sube el peso y pierdes semanas de progreso.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> content;

  const _Section({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTextStyles.headlineMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String label;
  final String description;
  const _BulletPoint(this.label, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String phase;
  final String weeks;
  final Color color;
  final String description;

  const _PhaseCard({
    required this.phase,
    required this.weeks,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                phase,
                style: AppTextStyles.headlineSmall.copyWith(color: color),
              ),
              const SizedBox(width: 8),
              Text(
                weeks,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
