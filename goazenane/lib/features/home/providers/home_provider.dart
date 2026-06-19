import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/exercises_data.dart';

final userProvider = StreamProvider<User?>((ref) {
  return ref.watch(databaseProvider).userDao.watchUser();
});

final todaySleepProvider = FutureProvider<SleepLogData?>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return null;
  return ref.watch(databaseProvider).sleepDao.getTodaySleepLog(user.id);
});

final todayWearableProvider = FutureProvider<WearableDailyData?>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return null;
  return ref.watch(databaseProvider).sleepDao.getTodayWearable(user.id);
});

final trainingStreakProvider = FutureProvider<int>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return 0;
  return ref.watch(databaseProvider).workoutDao.getTrainingStreak(user.id);
});

final activeProgramProvider = StreamProvider<WorkoutProgram?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.userDao.watchUser().asyncExpand((user) {
    if (user == null) return Stream.value(null);
    return db.workoutDao.watchActiveProgram(user.id);
  });
});

final weeklyProgressProvider = FutureProvider<int>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return 0;
  return ref.watch(databaseProvider).workoutDao
      .countCompletedSessionsCurrentWeek(user.id);
});

final averageWeightLast7Provider = FutureProvider<double?>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return null;
  final metrics = await ref
      .watch(databaseProvider)
      .userDao
      .getBodyMetricsLast7Days(user.id);
  if (metrics.isEmpty) return null;
  return metrics.fold<double>(0, (acc, m) => acc + m.pesoKg) / metrics.length;
});

final sleepAlertProvider = FutureProvider<String?>((ref) async {
  final sleep = await ref.watch(todaySleepProvider.future);
  if (sleep == null) return null;
  if (sleep.horasTotales < AppConstants.sleepThresholdCritical) {
    return 'Tu recuperación es incompleta. Un día de movilidad hoy vale más que forzar.';
  }
  if (sleep.horasTotales < AppConstants.sleepThresholdLow) {
    return 'Dormiste poco. Hoy entrenamos más inteligente, no más duro.';
  }
  final deepPercent = sleep.horasProfundo != null
      ? sleep.horasProfundo! / sleep.horasTotales
      : 1.0;
  if (deepPercent < AppConstants.sleepDeepMinPercent) {
    return 'Tus horas de sueño fueron suficientes pero la calidad fue baja. Reducimos el volumen de hoy.';
  }
  return null;
});

final hrAlertProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(databaseProvider).userDao.getUser();
  if (user == null) return null;
  final elevated = await ref
      .watch(databaseProvider)
      .sleepDao
      .isHrRestElevated3Days(user.id);
  if (elevated) {
    return 'Tu frecuencia cardíaca en reposo está elevada. Considera descanso o movilidad hoy.';
  }
  return null;
});

// Siembra ejercicios nuevos del catálogo si el usuario ya completó el onboarding.
// Usa seedIfMissing (por nombre) para no duplicar ni alterar IDs existentes.
final exerciseSeedProvider = FutureProvider<void>((ref) async {
  final db = ref.read(databaseProvider);
  final count = await db.exerciseDao.countExercises();
  if (count < exercisesCatalog.length) {
    await db.exerciseDao.seedIfMissing(exercisesCatalog);
  }
});
