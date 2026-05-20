import '../../core/database/app_database.dart';
import '../../core/constants/app_constants.dart';

enum Division { fullBody, torsopierna, ppl }

class WorkoutDay {
  final String tipo; // full_body | torso | pierna | empuje | tiron | piernas_ppl
  final String label;
  final List<String> patronesRequeridos;

  const WorkoutDay({
    required this.tipo,
    required this.label,
    required this.patronesRequeridos,
  });
}

class PlannedExercise {
  final Exercise exercise;
  final int setsObjetivo;
  final int repsMin;
  final int repsMax;
  final bool esCalentamiento;
  final String intensidadZona; // fuerza_hipertrofia | hipertrofia | metabolica

  const PlannedExercise({
    required this.exercise,
    required this.setsObjetivo,
    required this.repsMin,
    required this.repsMax,
    required this.esCalentamiento,
    required this.intensidadZona,
  });
}

class WorkoutGenerator {
  static Division selectDivision(int diasDisponibles, String nivel) {
    if (diasDisponibles <= 3) return Division.fullBody;
    if (diasDisponibles == 4) return Division.torsopierna;
    return nivel == 'avanzado' ? Division.ppl : Division.torsopierna;
  }

  static List<WorkoutDay> buildWeekSchedule(Division division, int dias) {
    switch (division) {
      case Division.fullBody:
        return List.generate(
            dias,
            (i) => const WorkoutDay(
                  tipo: 'full_body',
                  label: 'Full Body',
                  patronesRequeridos: [
                    'sentadilla',
                    'bisagra',
                    'empuje_horizontal',
                    'tiron_horizontal',
                  ],
                ));
      case Division.torsopierna:
        final schedule = <WorkoutDay>[];
        for (int i = 0; i < dias; i++) {
          if (i % 2 == 0) {
            schedule.add(const WorkoutDay(
              tipo: 'torso',
              label: 'Torso',
              patronesRequeridos: [
                'empuje_horizontal',
                'tiron_horizontal',
                'empuje_vertical',
                'tiron_vertical',
              ],
            ));
          } else {
            schedule.add(const WorkoutDay(
              tipo: 'pierna',
              label: 'Pierna',
              patronesRequeridos: [
                'sentadilla',
                'bisagra',
                'aislamiento',
              ],
            ));
          }
        }
        return schedule;
      case Division.ppl:
        const cycle = [
          WorkoutDay(
            tipo: 'empuje',
            label: 'Empuje',
            patronesRequeridos: [
              'empuje_horizontal',
              'empuje_vertical',
              'aislamiento',
            ],
          ),
          WorkoutDay(
            tipo: 'tiron',
            label: 'Tirón',
            patronesRequeridos: [
              'tiron_horizontal',
              'tiron_vertical',
              'aislamiento',
            ],
          ),
          WorkoutDay(
            tipo: 'pierna',
            label: 'Pierna',
            patronesRequeridos: [
              'sentadilla',
              'bisagra',
              'aislamiento',
            ],
          ),
        ];
        return List.generate(dias, (i) => cycle[i % 3]);
    }
  }

  static List<PlannedExercise> generateSession({
    required List<Exercise> availableExercises,
    required WorkoutDay day,
    required String nivel,
    required bool enDeload,
    required double volumeFactor, // 1.0 normal, <1.0 fase o sueño penalty
  }) {
    final planned = <PlannedExercise>[];

    // Calentamiento
    final warmupExercises = _selectWarmup(day.tipo, availableExercises);
    for (final ex in warmupExercises) {
      planned.add(PlannedExercise(
        exercise: ex,
        setsObjetivo: 2,
        repsMin: 10,
        repsMax: 15,
        esCalentamiento: true,
        intensidadZona: 'metabolica',
      ));
    }

    // Series por patrón según nivel
    final seriesConfig = AppConstants.weeklySeriesMin[nivel] ??
        {'min': 14, 'max': 16};
    final targetSeriesPerSession = ((seriesConfig['min']! / 2) * volumeFactor)
        .round()
        .clamp(2, 12);

    int seriesUsed = 0;
    for (final patron in day.patronesRequeridos) {
      if (seriesUsed >= targetSeriesPerSession) break;

      final candidates = availableExercises
          .where((e) => e.patronMovimiento == patron)
          .toList();
      if (candidates.isEmpty) continue;

      candidates.shuffle();
      final selected = candidates.first;
      final isCompound = _isCompound(patron);
      final setsForThis = isCompound
          ? (seriesUsed < 2 ? 4 : 3)
          : 3;
      final effectiveSets = enDeload
          ? (setsForThis * AppConstants.deloadVolumeRatio).round().clamp(1, 4)
          : setsForThis;

      // Mezclar zonas de intensidad
      final zona = _selectIntensityZone(seriesUsed, targetSeriesPerSession);

      planned.add(PlannedExercise(
        exercise: selected,
        setsObjetivo: effectiveSets,
        repsMin: _repsMin(zona),
        repsMax: _repsMax(zona),
        esCalentamiento: false,
        intensidadZona: zona,
      ));
      seriesUsed += effectiveSets;
    }

    return planned;
  }

  static List<Exercise> _selectWarmup(
      String diaTipo, List<Exercise> exercises) {
    final warmupPatterns = {
      'pierna': ['sentadilla', 'aislamiento'],
      'full_body': ['sentadilla', 'bisagra'],
      'torso': ['empuje_horizontal'],
      'empuje': ['empuje_horizontal'],
      'tiron': ['tiron_horizontal'],
    };
    final patterns = warmupPatterns[diaTipo] ?? ['sentadilla'];
    return exercises
        .where((e) =>
            patterns.contains(e.patronMovimiento) &&
            e.nivelMinimo == 'principiante')
        .take(2)
        .toList();
  }

  static bool _isCompound(String patron) {
    return [
      'sentadilla',
      'bisagra',
      'empuje_horizontal',
      'empuje_vertical',
      'tiron_horizontal',
      'tiron_vertical',
    ].contains(patron);
  }

  static String _selectIntensityZone(int index, int total) {
    if (index < total * 0.3) return 'fuerza_hipertrofia';
    if (index < total * 0.7) return 'hipertrofia';
    return 'metabolica';
  }

  static int _repsMin(String zona) {
    switch (zona) {
      case 'fuerza_hipertrofia':
        return 6;
      case 'hipertrofia':
        return 8;
      case 'metabolica':
        return 12;
      default:
        return 8;
    }
  }

  static int _repsMax(String zona) {
    switch (zona) {
      case 'fuerza_hipertrofia':
        return 8;
      case 'hipertrofia':
        return 12;
      case 'metabolica':
        return 20;
      default:
        return 12;
    }
  }

  // ── Periodización ──────────────────────────────────────────────────────────

  static Map<String, int> getPeriodizationPhases(String nivel) {
    switch (nivel) {
      case 'principiante':
        return {'acumulacion': 6, 'intensificacion': 4, 'pico': 2};
      case 'intermedio':
        return {'acumulacion': 5, 'intensificacion': 5, 'pico': 2};
      case 'avanzado':
        return {'acumulacion': 4, 'intensificacion': 5, 'pico': 3};
      default:
        return {'acumulacion': 5, 'intensificacion': 5, 'pico': 2};
    }
  }

  static String? checkPhaseTransition({
    required String faseActual,
    required int semanaEnFase,
    required int duracionFase,
    required double rpePromedio,
    required int sesionesCompletadasFase,
    required int sesionesTotalesFase,
    required bool rendimientoEstancado,
  }) {
    final completionRate = sesionesTotalesFase > 0
        ? sesionesCompletadasFase / sesionesTotalesFase
        : 1.0;

    // Completó semanas: avanzar
    if (semanaEnFase >= duracionFase) {
      if (completionRate < AppConstants.sessionCompletionMinimum) {
        return 'repetir_fase';
      }
      return _nextPhase(faseActual);
    }

    // RPE demasiado alto antes de tiempo: avanzar anticipadamente
    if (rpePromedio > AppConstants.advanceRpeThreshold &&
        semanaEnFase >= duracionFase * 0.6) {
      return _nextPhase(faseActual);
    }

    // RPE bajo en acumulación: extender
    if (faseActual == 'acumulacion' &&
        semanaEnFase == duracionFase - 1 &&
        rpePromedio < AppConstants.stallRpeThreshold) {
      return 'extender_acumulacion';
    }

    // Rendimiento estancado
    if (rendimientoEstancado && faseActual == 'acumulacion') {
      return 'intensificacion';
    }

    return null; // Sin cambio
  }

  static String _nextPhase(String current) {
    switch (current) {
      case 'acumulacion':
        return 'intensificacion';
      case 'intensificacion':
        return 'pico';
      default:
        return 'acumulacion';
    }
  }

  // ── Sobrecarga progresiva ──────────────────────────────────────────────────

  static double calcNextSessionWeight({
    required double currentWeight,
    required int setsCompletados,
    required int setsObjetivo,
  }) {
    final completionRate =
        setsObjetivo > 0 ? setsCompletados / setsObjetivo : 0;
    if (completionRate >= AppConstants.completionThresholdFull) {
      return currentWeight * (1 + AppConstants.progressionFullCompletion);
    }
    return currentWeight; // mantener peso
  }

  // ── Volume factor según sueño ─────────────────────────────────────────────

  static double sleepVolumeFactor(double? horasSuenio) {
    if (horasSuenio == null) return 1.0;
    if (horasSuenio < AppConstants.sleepThresholdCritical) return 0.0; // descanso
    if (horasSuenio < AppConstants.sleepThresholdLow) return AppConstants.sleepVolumePenaltyLow;
    return 1.0;
  }

  // ── Cardio recomendado por fase ──────────────────────────────────────────

  static Map<String, dynamic> getCardioRecommendation(
      String faseCiclo, int edad) {
    final fcmax = 220 - edad;
    switch (faseCiclo) {
      case 'menstruacion':
        return {
          'tipo': 'liss',
          'duracion_min': 25,
          'frecuencia_semana': 2,
          'fc_min': (fcmax * 0.60).round(),
          'fc_max': (fcmax * 0.70).round(),
          'descripcion': 'Caminar o bici suave — recuperación activa',
        };
      case 'folicular':
        return {
          'tipo': 'hiit_intervalos',
          'duracion_min': 18,
          'frecuencia_semana': 2,
          'descripcion': '30s trabajo / 30s descanso × 10 rondas',
        };
      case 'ovulacion':
        return {
          'tipo': 'hiit_tabata',
          'duracion_min': 16,
          'frecuencia_semana': 1,
          'descripcion': '20s trabajo / 10s descanso × 8 rondas — máxima intensidad',
        };
      case 'lutea':
        return {
          'tipo': 'liss',
          'duracion_min': 30,
          'frecuencia_semana': 2,
          'fc_min': (fcmax * 0.60).round(),
          'fc_max': (fcmax * 0.70).round(),
          'descripcion': 'LISS obligatorio — progesterona elevada',
        };
      default:
        return {
          'tipo': 'liss',
          'duracion_min': 25,
          'frecuencia_semana': 2,
          'descripcion': 'Cardio suave',
        };
    }
  }
}
