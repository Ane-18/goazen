import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/utils/workout_generator.dart';
import '../../../core/constants/app_constants.dart';

final workoutProgramProvider = FutureProvider<WorkoutProgram?>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return null;
  return ref.watch(databaseProvider).workoutDao.getActiveProgram(user.id);
});

class WorkoutSessionNotifier extends StateNotifier<AsyncValue<WorkoutSession?>> {
  WorkoutSessionNotifier(this._db) : super(const AsyncValue.loading()) {
    _init();
  }

  final AppDatabase _db;

  Future<void> _init() async {
    final user = await _db.userDao.getUser();
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    final session = await _db.workoutDao.getTodaySession(user.id);
    state = AsyncValue.data(session);
  }

  Future<int> generateAndStartSession() async {
    final user = await _db.userDao.getUser();
    if (user == null) throw Exception('Usuario no encontrado');

    // Determinar volumen factor por sueño
    final sleep = await _db.sleepDao.getTodaySleepLog(user.id);
    final volumeFactor = WorkoutGenerator.sleepVolumeFactor(sleep?.horasTotales);

    // Si volumen 0 → no generar sesión de fuerza hoy
    if (volumeFactor == 0.0) {
      throw Exception('sleep_critical');
    }

    // Obtener o crear programa
    var program = await _db.workoutDao.getActiveProgram(user.id);
    if (program == null) {
      program = await _createNewProgram(user);
    }

    // Verificar deload
    final deloadActive = await _db.workoutDao.getActiveDeload(user.id);
    final enDeload = deloadActive != null || program.enDeload;

    // Determinar día de la semana en el programa
    final division = WorkoutGenerator.selectDivision(
        user.diasDisponibles, user.nivelExperiencia);
    final schedule =
        WorkoutGenerator.buildWeekSchedule(division, user.diasDisponibles);

    final dayIndex =
        (DateTime.now().weekday - 1) % schedule.length;
    final day = schedule[dayIndex];

    // Filtrar ejercicios disponibles
    final limitaciones = user.limitaciones.isNotEmpty
        ? user.limitaciones.split(',').where((l) => l.isNotEmpty).toList()
        : <String>[];
    final allExercises = await _db.exerciseDao.getFilteredExercises(
      equipamiento: user.equipamiento,
      nivelMinimo: user.nivelExperiencia,
      zonasExcluidas: limitaciones,
    );

    // Generar plan de sesión
    final plannedExercises = WorkoutGenerator.generateSession(
      availableExercises: allExercises,
      day: day,
      nivel: user.nivelExperiencia,
      enDeload: enDeload,
      volumeFactor: _phaseVolumeFactor(user.faseCicloActual) * volumeFactor,
    );

    // Crear sesión en DB
    final sessionId = await _db.workoutDao.insertSession(
      WorkoutSessionsCompanion(
        userId: Value(user.id),
        programId: Value(program.id),
        fecha: Value(DateTime.now()),
        diaTipo: Value(day.tipo),
        faseCicloRegistrada: Value(user.faseCicloActual),
        horasSuenioPrevio: Value(sleep?.horasTotales),
        fcReposoDia: Value(sleep?.fcReposoMatutina),
      ),
    );

    // Insertar ejercicios planificados
    for (int i = 0; i < plannedExercises.length; i++) {
      final pe = plannedExercises[i];
      final lastWeight = pe.esCalentamiento
          ? 0.0
          : await _db.workoutDao.getLastWeightForExercise(
                  user.id, pe.exercise.id, day.tipo) ??
              0.0;

      final pesoSugerido = enDeload && lastWeight > 0
          ? lastWeight * AppConstants.deloadLoadRatio
          : lastWeight;

      final seId = await _db.workoutDao.insertSessionExercise(
        SessionExercisesCompanion(
          sessionId: Value(sessionId),
          exerciseId: Value(pe.exercise.id),
          orden: Value(i),
          setsObjetivo: Value(pe.setsObjetivo),
          repsMin: Value(pe.repsMin),
          repsMax: Value(pe.repsMax),
          pesoSugeridoKg: Value(pesoSugerido),
          patronMovimiento: Value(pe.exercise.patronMovimiento),
          esCalentamiento: Value(pe.esCalentamiento),
        ),
      );

      // Pre-crear sets vacíos
      for (int s = 1; s <= pe.setsObjetivo; s++) {
        await _db.workoutDao.insertExerciseSet(
          ExerciseSetsCompanion(
            sessionExerciseId: Value(seId),
            numeroSet: Value(s),
            pesoKg: Value(pesoSugerido),
          ),
        );
      }
    }

    final session = await _db.workoutDao.getSessionById(sessionId);
    state = AsyncValue.data(session);
    return sessionId;
  }

  double _phaseVolumeFactor(String fase) {
    switch (fase) {
      case 'menstruacion':
        return AppConstants.menstrualVolumeFactor;
      default:
        return 1.0;
    }
  }

  Future<WorkoutProgram> _createNewProgram(User user) async {
    final phases =
        WorkoutGenerator.getPeriodizationPhases(user.nivelExperiencia);
    final division =
        WorkoutGenerator.selectDivision(user.diasDisponibles, user.nivelExperiencia);
    final divLabel = division == Division.fullBody
        ? 'full_body'
        : division == Division.torsopierna
            ? 'torso_pierna'
            : 'ppl';

    final now = DateTime.now();
    await _db.workoutDao.insertProgram(
      WorkoutProgramsCompanion(
        userId: Value(user.id),
        nombre: Value('Programa 12 semanas — ${user.nivelExperiencia}'),
        diasPorSemana: Value(user.diasDisponibles),
        divisionTipo: Value(divLabel),
        fechaInicio: Value(now),
        fechaFin: Value(now.add(const Duration(days: 84))),
        semanasAcumulacion: Value(phases['acumulacion']!),
        semanasIntensificacion: Value(phases['intensificacion']!),
        semanasPico: Value(phases['pico']!),
      ),
    );
    return (await _db.workoutDao.getActiveProgram(user.id))!;
  }
}

final workoutSessionNotifierProvider =
    StateNotifierProvider<WorkoutSessionNotifier, AsyncValue<WorkoutSession?>>(
  (ref) => WorkoutSessionNotifier(ref.watch(databaseProvider)),
);
