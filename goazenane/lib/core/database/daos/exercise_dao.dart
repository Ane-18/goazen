import 'package:drift/drift.dart';
import '../app_database.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase> with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<Exercise?> getExerciseById(int id) =>
      (select(exercises)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Exercise>> getExercisesByPattern(String patron) =>
      (select(exercises)..where((t) => t.patronMovimiento.equals(patron))).get();

  Future<List<Exercise>> getExercisesByMuscle(String muscle) =>
      (select(exercises)..where((t) => t.grupoMuscular.equals(muscle))).get();

  Future<List<Exercise>> getFilteredExercises({
    required String equipamiento,
    required String nivelMinimo,
    List<String> zonasExcluidas = const [],
  }) async {
    final allExercises = await (select(exercises)
          ..where((t) => t.equipamientoRequerido.equals(equipamiento) |
              t.equipamientoRequerido.equals('peso_corporal')))
        .get();

    final nivelOrder = {'principiante': 0, 'intermedio': 1, 'avanzado': 2};
    final maxNivel = nivelOrder[nivelMinimo] ?? 1;

    return allExercises.where((e) {
      final eNivel = nivelOrder[e.nivelMinimo] ?? 0;
      if (eNivel > maxNivel) return false;
      if (zonasExcluidas.isNotEmpty) {
        for (final zona in zonasExcluidas) {
          if (e.zonasRiesgo.contains(zona)) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<int> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> countExercises() async {
    final count = await customSelect('SELECT COUNT(*) as c FROM exercises').getSingle();
    return count.read<int>('c');
  }
}
