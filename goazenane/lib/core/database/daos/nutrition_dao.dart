import 'package:drift/drift.dart';
import '../app_database.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [NutritionPlans, DailyNutritionLog, DailyWaterLog, FoodItems])
class NutritionDao extends DatabaseAccessor<AppDatabase>
    with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<int> insertPlan(NutritionPlansCompanion entry) =>
      into(nutritionPlans).insert(entry, mode: InsertMode.insertOrReplace);

  Future<NutritionPlan?> getTodayPlan(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(nutritionPlans)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<NutritionPlan?> watchTodayPlan(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(nutritionPlans)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .watchSingleOrNull();
  }

  // ── Daily log ──────────────────────────────────────────────────────────────

  Future<int> insertFoodLog(DailyNutritionLogCompanion entry) =>
      into(dailyNutritionLog).insert(entry);

  Future<void> deleteFoodLog(int id) =>
      (delete(dailyNutritionLog)..where((t) => t.id.equals(id))).go();

  Future<List<DailyNutritionLogData>> getTodayLog(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(dailyNutritionLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.hora)]))
        .get();
  }

  Stream<List<DailyNutritionLogData>> watchTodayLog(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(dailyNutritionLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.hora)]))
        .watch();
  }

  Future<Map<String, double>> getTodayTotals(int userId) async {
    final logs = await getTodayLog(userId);
    return {
      'calorias': logs.fold(0, (acc, l) => acc + l.calorias),
      'proteinas': logs.fold(0, (acc, l) => acc + l.proteinasG),
      'carbos': logs.fold(0, (acc, l) => acc + l.carbosG),
      'grasas': logs.fold(0, (acc, l) => acc + l.grasasG),
    };
  }

  // ── Water ──────────────────────────────────────────────────────────────────

  Future<int> upsertWaterLog(DailyWaterLogCompanion entry) =>
      into(dailyWaterLog).insert(entry, mode: InsertMode.insertOrReplace);

  Future<DailyWaterLogData?> getTodayWater(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(dailyWaterLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<DailyWaterLogData?> watchTodayWater(int userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(dailyWaterLog)
          ..where((t) =>
              t.userId.equals(userId) &
              t.fecha.isBiggerOrEqualValue(startOfDay) &
              t.fecha.isSmallerThanValue(endOfDay))
          ..limit(1))
        .watchSingleOrNull();
  }

  // ── Food items ─────────────────────────────────────────────────────────────

  Future<List<FoodItem>> searchFoods(String query) =>
      (select(foodItems)
            ..where((t) => t.nombre.like('%$query%'))
            ..limit(20))
          .get();

  Future<List<FoodItem>> getAllFoods() => select(foodItems).get();

  Future<int> insertFood(FoodItemsCompanion entry) =>
      into(foodItems).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> countFoods() async {
    final count = await customSelect('SELECT COUNT(*) as c FROM food_items').getSingle();
    return count.read<int>('c');
  }

  // ── Macro streak ──────────────────────────────────────────────────────────

  Future<int> getMacroStreak(int userId) async {
    int streak = 0;
    DateTime date = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final d = DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: i));
      final end = d.add(const Duration(days: 1));
      final plan = await (select(nutritionPlans)
            ..where((t) =>
                t.userId.equals(userId) &
                t.fecha.isBiggerOrEqualValue(d) &
                t.fecha.isSmallerThanValue(end))
            ..limit(1))
          .getSingleOrNull();
      if (plan == null) break;

      final logs = await (select(dailyNutritionLog)
            ..where((t) =>
                t.userId.equals(userId) &
                t.fecha.isBiggerOrEqualValue(d) &
                t.fecha.isSmallerThanValue(end)))
          .get();
      if (logs.isEmpty) break;

      final totalCal =
          logs.fold<double>(0, (acc, l) => acc + l.calorias);
      if (totalCal >= plan.caloriasObjetivo * 0.85) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
