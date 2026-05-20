import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sleep_dao.g.dart';

@DriftAccessor(tables: [SleepLog, WearableDaily])
class SleepDao extends DatabaseAccessor<AppDatabase> with _$SleepDaoMixin {
  SleepDao(super.db);

  // ── Sleep log ─────────────────────────────────────────────────────────────

  Future<int> insertSleepLog(SleepLogCompanion entry) =>
      into(sleepLog).insert(entry, mode: InsertMode.insertOrReplace);

  Future<SleepLogData?> getTodaySleepLog(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(sleepLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<SleepLogData?> watchTodaySleepLog(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(sleepLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<SleepLogData>> getSleepLast7Days(int userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(sleepLog)
          ..where((t) =>
              t.userId.equals(userId) & t.fecha.isBiggerThan(Variable(cutoff)))
          ..orderBy([(t) => OrderingTerm.asc(t.fecha)]))
        .get();
  }

  Future<List<SleepLogData>> getSleepHistory(int userId, {int limit = 30}) =>
      (select(sleepLog)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(limit))
          .get();

  Future<double?> getAverageRestingHr7Days(int userId) async {
    final logs = await getSleepLast7Days(userId);
    final withHr = logs.where((l) => l.fcReposoMatutina != null).toList();
    if (withHr.isEmpty) return null;
    return withHr.fold<double>(0, (acc, l) => acc + l.fcReposoMatutina!) /
        withHr.length;
  }

  Future<bool> isHrRestElevated3Days(int userId) async {
    final avg = await getAverageRestingHr7Days(userId);
    if (avg == null) return false;
    final logs = await (select(sleepLog)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(3))
        .get();
    if (logs.length < 3) return false;
    return logs.every(
        (l) => l.fcReposoMatutina != null && l.fcReposoMatutina! - avg >= 7);
  }

  Future<int> getSleepStreak(int userId) async {
    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final d = DateTime(date.year, date.month, date.day);
      final end = d.add(const Duration(days: 1));
      final log = await (select(sleepLog)
            ..where((t) =>
                t.userId.equals(userId) &
                t.fecha.isBiggerOrEqualValue(d) &
                t.fecha.isSmallerThanValue(end))
            ..limit(1))
          .getSingleOrNull();
      if (log != null && log.horasTotales >= 7) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Wearable daily ────────────────────────────────────────────────────────

  Future<int> insertWearableData(WearableDailyCompanion entry) =>
      into(wearableDaily).insert(entry, mode: InsertMode.insertOrReplace);

  Future<WearableDailyData?> getTodayWearable(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(wearableDaily)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<WearableDailyData?> watchTodayWearable(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(wearableDaily)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<WearableDailyData>> getWearableLast7Days(int userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(wearableDaily)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerThan(Variable(cutoff)))
          ..orderBy([(t) => OrderingTerm.asc(t.fecha)]))
        .get();
  }

  Future<double> getAverageStepsLast7Days(int userId) async {
    final data = await getWearableLast7Days(userId);
    if (data.isEmpty) return 0;
    return data.fold<double>(0, (acc, d) => acc + d.pasos) / data.length;
  }

  Future<int> getWaterStreak(int userId) => Future.value(0); // delegado a NutritionDao
}
