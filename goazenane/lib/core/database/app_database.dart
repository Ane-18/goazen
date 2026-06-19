import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/user_dao.dart';
import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/sleep_dao.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  DateTimeColumn get fechaNacimiento => dateTime()();
  RealColumn get pesoKg => real()();
  RealColumn get alturaCm => real()();
  RealColumn get porcentajeGrasa => real()();
  TextColumn get objetivo => text()(); // recomposicion | perdida_grasa | ganancia_muscular
  TextColumn get nivelExperiencia => text()(); // principiante | intermedio | avanzado
  IntColumn get diasDisponibles => integer()();
  TextColumn get equipamiento => text()(); // gimnasio | mancuernas | peso_corporal
  TextColumn get limitaciones => text().withDefault(const Constant(''))();
  IntColumn get duracionSesionMax => integer().withDefault(const Constant(60))();
  BoolColumn get usaAnticonceptivos => boolean().withDefault(const Constant(false))();
  TextColumn get faseCicloActual => text().withDefault(const Constant('folicular'))();
  DateTimeColumn get fechaRegistro => dateTime()();
  BoolColumn get tieneMiBand => boolean().withDefault(const Constant(false))();
  TextColumn get miBandMacAddress => text().withDefault(const Constant(''))();
  BoolColumn get onboardingCompleto => boolean().withDefault(const Constant(false))();
}

class BodyMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fecha => dateTime()();
  RealColumn get pesoKg => real()();
  RealColumn get cinturaCm => real().nullable()();
  RealColumn get caderaCm => real().nullable()();
  RealColumn get pechoCm => real().nullable()();
  RealColumn get brazoCm => real().nullable()();
  RealColumn get musloCm => real().nullable()();
  TextColumn get fotoPath => text().withDefault(const Constant(''))();
}

class CycleLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get faseCiclo => text()(); // menstruacion | folicular | ovulacion | lutea
  TextColumn get notasEnergia => text().withDefault(const Constant(''))();
  TextColumn get notasDolor => text().withDefault(const Constant(''))();
}

class SleepLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fecha => dateTime()();
  RealColumn get horasTotales => real()();
  RealColumn get horasProfundo => real().nullable()();
  RealColumn get horasLigero => real().nullable()();
  TextColumn get horaDormir => text().withDefault(const Constant(''))();
  TextColumn get horaDespertar => text().withDefault(const Constant(''))();
  RealColumn get fcReposoMatutina => real().nullable()();
  TextColumn get fuente => text().withDefault(const Constant('manual'))(); // manual | mi_band
}

class WearableDaily extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fecha => dateTime()();
  IntColumn get pasos => integer().withDefault(const Constant(0))();
  RealColumn get caloriasActivas => real().withDefault(const Constant(0))();
  RealColumn get fcReposo => real().nullable()();
  RealColumn get fcMaxDia => real().nullable()();
  IntColumn get minutosActivos => integer().withDefault(const Constant(0))();
  TextColumn get fuente => text().withDefault(const Constant('manual'))();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get grupoMuscular => text()();
  TextColumn get patronMovimiento => text()();
  TextColumn get descripcionTecnica => text()();
  TextColumn get erroresComunes => text().withDefault(const Constant(''))();
  TextColumn get tempo => text().withDefault(const Constant('2-0-2-0'))();
  TextColumn get urlGif => text().withDefault(const Constant(''))();
  TextColumn get equipamientoRequerido => text()();
  TextColumn get nivelMinimo => text()();
  TextColumn get zonasRiesgo => text().withDefault(const Constant(''))();
  TextColumn get musculosSecundarios => text().withDefault(const Constant(''))();
}

class WorkoutPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get nombre => text()();
  TextColumn get faseActual => text().withDefault(const Constant('acumulacion'))();
  IntColumn get semanaActual => integer().withDefault(const Constant(1))();
  IntColumn get diasPorSemana => integer()();
  TextColumn get divisionTipo => text()(); // full_body | torso_pierna | ppl
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime()();
  BoolColumn get enDeload => boolean().withDefault(const Constant(false))();
  IntColumn get semanasAcumulacion => integer().withDefault(const Constant(5))();
  IntColumn get semanasIntensificacion => integer().withDefault(const Constant(5))();
  IntColumn get semanasPico => integer().withDefault(const Constant(2))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get programId => integer().references(WorkoutPrograms, #id)();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get diaTipo => text()(); // full_body | torso | pierna | empuje | tiron
  IntColumn get duracionMin => integer().withDefault(const Constant(0))();
  RealColumn get volumenTotalKg => real().withDefault(const Constant(0))();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
  TextColumn get notas => text().withDefault(const Constant(''))();
  RealColumn get rpePromedioSesion => real().nullable()();
  TextColumn get faseCicloRegistrada => text().withDefault(const Constant(''))();
  RealColumn get horasSuenioPrevio => real().nullable()();
  RealColumn get fcReposoDia => real().nullable()();
}

class SessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orden => integer()();
  IntColumn get setsObjetivo => integer()();
  IntColumn get repsMin => integer()();
  IntColumn get repsMax => integer()();
  RealColumn get pesoSugeridoKg => real().withDefault(const Constant(0))();
  TextColumn get patronMovimiento => text()();
  BoolColumn get esCalentamiento => boolean().withDefault(const Constant(false))();
}

class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionExerciseId => integer().references(SessionExercises, #id)();
  IntColumn get numeroSet => integer()();
  RealColumn get pesoKg => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  BoolColumn get completado => boolean().withDefault(const Constant(false))();
  RealColumn get rpe => real().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get notaFatiga => text().withDefault(const Constant(''))();
}

class CardioSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get tipo => text()(); // liss | hiit_tabata | hiit_intervalos
  IntColumn get duracionMin => integer()();
  TextColumn get faseCiclo => text()();
  RealColumn get fcPromedio => real().nullable()();
  RealColumn get fcMax => real().nullable()();
  RealColumn get fcMin => real().nullable()();
  BoolColumn get zonaCorrecta => boolean().withDefault(const Constant(true))();
  RealColumn get caloriasEstimadas => real().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
}

class DeloadLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime().nullable()();
  TextColumn get triggerCausa => text()();
  RealColumn get rpePromedioPrevio => real().nullable()();
  RealColumn get fcReposoTrigger => real().nullable()();
  BoolColumn get completado => boolean().withDefault(const Constant(false))();
}

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get tipoLogro => text()();
  DateTimeColumn get fechaDesbloqueado => dateTime()();
  TextColumn get descripcion => text()();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Users,
    BodyMetrics,
    CycleLog,
    SleepLog,
    WearableDaily,
    Exercises,
    WorkoutPrograms,
    WorkoutSessions,
    SessionExercises,
    ExerciseSets,
    CardioSessions,
    DeloadLog,
    Achievements,
  ],
  daos: [
    UserDao,
    ExerciseDao,
    WorkoutDao,
    SleepDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Drop nutrition tables removed in v2
            await m.database.customStatement('DROP TABLE IF EXISTS nutrition_plans');
            await m.database.customStatement('DROP TABLE IF EXISTS daily_nutrition_log');
            await m.database.customStatement('DROP TABLE IF EXISTS daily_water_log');
            await m.database.customStatement('DROP TABLE IF EXISTS food_items');
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'goazenane_db');
}
