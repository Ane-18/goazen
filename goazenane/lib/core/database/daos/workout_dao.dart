import 'package:drift/drift.dart';
import '../app_database.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [
  WorkoutPrograms,
  WorkoutSessions,
  SessionExercises,
  ExerciseSets,
  CardioSessions,
  DeloadLog,
])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ── Programs ──────────────────────────────────────────────────────────────

  Future<WorkoutProgram?> getActiveProgram(int userId) =>
      (select(workoutPrograms)
            ..where((t) => t.userId.equals(userId) & t.activo.equals(true))
            ..limit(1))
          .getSingleOrNull();

  Stream<WorkoutProgram?> watchActiveProgram(int userId) =>
      (select(workoutPrograms)
            ..where((t) => t.userId.equals(userId) & t.activo.equals(true))
            ..limit(1))
          .watchSingleOrNull();

  Future<int> insertProgram(WorkoutProgramsCompanion entry) =>
      into(workoutPrograms).insert(entry);

  Future<bool> updateProgram(WorkoutProgramsCompanion entry) =>
      update(workoutPrograms).replace(entry);

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  Future<bool> updateSession(WorkoutSessionsCompanion entry) =>
      update(workoutSessions).replace(entry);

  Future<WorkoutSession?> getSessionById(int id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<WorkoutSession?> getTodaySession(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> getRecentSessions(int userId, {int limit = 20}) =>
      (select(workoutSessions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(limit))
          .get();

  Stream<List<WorkoutSession>> watchRecentSessions(int userId, {int limit = 10}) =>
      (select(workoutSessions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(limit))
          .watch();

  Future<List<WorkoutSession>> getSessionsLast5(int userId) =>
      (select(workoutSessions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(5))
          .get();

  Future<double?> getAverageRpeLast5(int userId) async {
    final sessions = await getSessionsLast5(userId);
    final rpeSessions =
        sessions.where((s) => s.rpePromedioSesion != null).toList();
    if (rpeSessions.isEmpty) return null;
    final sum =
        rpeSessions.fold<double>(0, (acc, s) => acc + s.rpePromedioSesion!);
    return sum / rpeSessions.length;
  }

  Future<int> countCompletedSessionsCurrentWeek(int userId) async {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final sessions = await (select(workoutSessions)
          ..where((t) =>
              t.userId.equals(userId) &
              t.completada.equals(true) &
              t.fecha.isBiggerOrEqualValue(weekStart)))
        .get();
    return sessions.length;
  }

  // ── Session exercises ──────────────────────────────────────────────────────

  Future<int> insertSessionExercise(SessionExercisesCompanion entry) =>
      into(sessionExercises).insert(entry);

  Future<List<SessionExercise>> getSessionExercises(int sessionId) =>
      (select(sessionExercises)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
          .get();

  Stream<List<SessionExercise>> watchSessionExercises(int sessionId) =>
      (select(sessionExercises)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
          .watch();

  // ── Exercise sets ──────────────────────────────────────────────────────────

  Future<int> insertExerciseSet(ExerciseSetsCompanion entry) =>
      into(exerciseSets).insert(entry);

  Future<bool> updateExerciseSet(ExerciseSetsCompanion entry) =>
      update(exerciseSets).replace(entry);

  Future<List<ExerciseSet>> getSetsForSessionExercise(int sessionExerciseId) =>
      (select(exerciseSets)
            ..where((t) => t.sessionExerciseId.equals(sessionExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.numeroSet)]))
          .get();

  Stream<List<ExerciseSet>> watchSetsForSessionExercise(int sessionExerciseId) =>
      (select(exerciseSets)
            ..where((t) => t.sessionExerciseId.equals(sessionExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.numeroSet)]))
          .watch();

  Future<double?> getLastWeightForExercise(
      int userId, int exerciseId, String diaTipo) async {
    final sessions = await (select(workoutSessions)
          ..where((t) =>
              t.userId.equals(userId) &
              t.diaTipo.equals(diaTipo) &
              t.completada.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(3))
        .get();

    for (final session in sessions) {
      final seExercises = await (select(sessionExercises)
            ..where((t) =>
                t.sessionId.equals(session.id) &
                t.exerciseId.equals(exerciseId)))
          .get();
      if (seExercises.isEmpty) continue;
      final sets = await getSetsForSessionExercise(seExercises.first.id);
      final completedSets = sets.where((s) => s.completado && s.pesoKg > 0);
      if (completedSets.isNotEmpty) {
        return completedSets
            .map((s) => s.pesoKg)
            .reduce((a, b) => a > b ? a : b);
      }
    }
    return null;
  }

  // ── Cardio ────────────────────────────────────────────────────────────────

  Future<int> insertCardioSession(CardioSessionsCompanion entry) =>
      into(cardioSessions).insert(entry);

  Future<List<CardioSession>> getCardioSessions(int userId, {int limit = 20}) =>
      (select(cardioSessions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(limit))
          .get();

  // ── Deload ────────────────────────────────────────────────────────────────

  Future<int> insertDeloadLog(DeloadLogCompanion entry) =>
      into(deloadLog).insert(entry);

  Future<bool> updateDeloadLog(DeloadLogCompanion entry) =>
      update(deloadLog).replace(entry);

  Future<DeloadLogData?> getActiveDeload(int userId) =>
      (select(deloadLog)
            ..where((t) =>
                t.userId.equals(userId) & t.completado.equals(false))
            ..limit(1))
          .getSingleOrNull();

  // ── Performance tracking ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getVolumeProgressForExercise(
      int userId, int exerciseId) async {
    final result = <Map<String, dynamic>>[];
    final sessions = await (select(workoutSessions)
          ..where((t) => t.userId.equals(userId) & t.completada.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.fecha)])
          ..limit(30))
        .get();

    for (final session in sessions) {
      final seExercises = await (select(sessionExercises)
            ..where((t) =>
                t.sessionId.equals(session.id) &
                t.exerciseId.equals(exerciseId)))
          .get();
      if (seExercises.isEmpty) continue;

      double totalVolume = 0;
      for (final se in seExercises) {
        final sets = await getSetsForSessionExercise(se.id);
        for (final s in sets) {
          if (s.completado) totalVolume += s.pesoKg * s.reps;
        }
      }
      if (totalVolume > 0) {
        result.add({'fecha': session.fecha, 'volumen': totalVolume});
      }
    }
    return result;
  }

  Future<int> getTrainingStreak(int userId) async {
    final sessions = await (select(workoutSessions)
          ..where((t) => t.userId.equals(userId) & t.completada.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
        .get();

    if (sessions.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final session in sessions) {
      final sessionDate = DateTime(
          session.fecha.year, session.fecha.month, session.fecha.day);
      if (lastDate == null) {
        lastDate = sessionDate;
        streak = 1;
      } else {
        final diff = lastDate.difference(sessionDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = sessionDate;
        } else if (diff == 0) {
          // same day, skip
        } else {
          break;
        }
      }
    }
    return streak;
  }
}
