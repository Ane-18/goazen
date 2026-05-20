import 'package:drift/drift.dart';
import '../app_database.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users, BodyMetrics, CycleLog, Achievements])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<User?> getUser() => select(users).getSingleOrNull();

  Future<int> insertUser(UsersCompanion entry) => into(users).insert(entry);

  Future<bool> updateUser(UsersCompanion entry) => update(users).replace(entry);

  Stream<User?> watchUser() => select(users).watchSingleOrNull();

  // Body metrics
  Future<int> insertBodyMetric(BodyMetricsCompanion entry) =>
      into(bodyMetrics).insert(entry);

  Future<List<BodyMetric>> getBodyMetrics(int userId) =>
      (select(bodyMetrics)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
          .get();

  Stream<List<BodyMetric>> watchBodyMetrics(int userId) =>
      (select(bodyMetrics)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
          .watch();

  Future<BodyMetric?> getLatestBodyMetric(int userId) =>
      (select(bodyMetrics)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<BodyMetric>> getBodyMetricsLast7Days(int userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(bodyMetrics)
          ..where((t) => t.userId.equals(userId) & t.fecha.isBiggerThan(Variable(cutoff))))
        .get();
  }

  // Cycle log
  Future<int> insertCycleLog(CycleLogCompanion entry) =>
      into(cycleLog).insert(entry);

  Future<CycleLogData?> getLatestCycleLog(int userId) =>
      (select(cycleLog)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<CycleLogData>> watchCycleLog(int userId) =>
      (select(cycleLog)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
          .watch();

  // Achievements
  Future<int> insertAchievement(AchievementsCompanion entry) =>
      into(achievements).insert(entry);

  Future<List<Achievement>> getAchievements(int userId) =>
      (select(achievements)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fechaDesbloqueado)]))
          .get();

  Stream<List<Achievement>> watchAchievements(int userId) =>
      (select(achievements)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.fechaDesbloqueado)]))
          .watch();

  Future<bool> hasAchievement(int userId, String tipo) async {
    final result = await (select(achievements)
          ..where((t) => t.userId.equals(userId) & t.tipoLogro.equals(tipo)))
        .getSingleOrNull();
    return result != null;
  }
}
