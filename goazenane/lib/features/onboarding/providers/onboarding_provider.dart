import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../../data/exercises_data.dart';
import '../../../data/foods_data.dart';
import '../../../core/utils/nutrition_calculator.dart';

class OnboardingState {
  final String nombre;
  final DateTime? fechaNacimiento;
  final double pesoKg;
  final double alturaCm;
  final double porcentajeGrasa;
  final double? cinturaCm;
  final double? caderaCm;
  final double? cuelloCm;
  final String objetivo; // recomposicion | perdida_grasa | ganancia_muscular
  final int diasDisponibles;
  final String nivelExperiencia;
  final String equipamiento;
  final List<String> limitaciones;
  final int duracionSesionMax;
  final bool usaAnticonceptivos;
  final String faseCicloActual;
  final bool tieneMiBand;
  final bool loading;
  final String? error;

  const OnboardingState({
    this.nombre = '',
    this.fechaNacimiento,
    this.pesoKg = 60,
    this.alturaCm = 165,
    this.porcentajeGrasa = 25,
    this.cinturaCm,
    this.caderaCm,
    this.cuelloCm,
    this.objetivo = 'recomposicion',
    this.diasDisponibles = 3,
    this.nivelExperiencia = 'principiante',
    this.equipamiento = 'gimnasio',
    this.limitaciones = const [],
    this.duracionSesionMax = 60,
    this.usaAnticonceptivos = false,
    this.faseCicloActual = 'folicular',
    this.tieneMiBand = false,
    this.loading = false,
    this.error,
  });

  OnboardingState copyWith({
    String? nombre,
    DateTime? fechaNacimiento,
    double? pesoKg,
    double? alturaCm,
    double? porcentajeGrasa,
    double? cinturaCm,
    double? caderaCm,
    double? cuelloCm,
    String? objetivo,
    int? diasDisponibles,
    String? nivelExperiencia,
    String? equipamiento,
    List<String>? limitaciones,
    int? duracionSesionMax,
    bool? usaAnticonceptivos,
    String? faseCicloActual,
    bool? tieneMiBand,
    bool? loading,
    String? error,
  }) {
    return OnboardingState(
      nombre: nombre ?? this.nombre,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      pesoKg: pesoKg ?? this.pesoKg,
      alturaCm: alturaCm ?? this.alturaCm,
      porcentajeGrasa: porcentajeGrasa ?? this.porcentajeGrasa,
      cinturaCm: cinturaCm ?? this.cinturaCm,
      caderaCm: caderaCm ?? this.caderaCm,
      cuelloCm: cuelloCm ?? this.cuelloCm,
      objetivo: objetivo ?? this.objetivo,
      diasDisponibles: diasDisponibles ?? this.diasDisponibles,
      nivelExperiencia: nivelExperiencia ?? this.nivelExperiencia,
      equipamiento: equipamiento ?? this.equipamiento,
      limitaciones: limitaciones ?? this.limitaciones,
      duracionSesionMax: duracionSesionMax ?? this.duracionSesionMax,
      usaAnticonceptivos: usaAnticonceptivos ?? this.usaAnticonceptivos,
      faseCicloActual: faseCicloActual ?? this.faseCicloActual,
      tieneMiBand: tieneMiBand ?? this.tieneMiBand,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._db) : super(const OnboardingState());

  final AppDatabase _db;

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setFechaNacimiento(DateTime v) => state = state.copyWith(fechaNacimiento: v);
  void setPeso(double v) => state = state.copyWith(pesoKg: v);
  void setAltura(double v) => state = state.copyWith(alturaCm: v);
  void setPorcentajeGrasa(double v) => state = state.copyWith(porcentajeGrasa: v);
  void setCintura(double? v) => state = state.copyWith(cinturaCm: v);
  void setCadera(double? v) => state = state.copyWith(caderaCm: v);
  void setCuello(double? v) => state = state.copyWith(cuelloCm: v);
  void setObjetivo(String v) => state = state.copyWith(objetivo: v);
  void setDiasDisponibles(int v) => state = state.copyWith(diasDisponibles: v);
  void setNivel(String v) => state = state.copyWith(nivelExperiencia: v);
  void setEquipamiento(String v) => state = state.copyWith(equipamiento: v);
  void setLimitaciones(List<String> v) => state = state.copyWith(limitaciones: v);
  void setDuracionSesion(int v) => state = state.copyWith(duracionSesionMax: v);
  void setUsaAnticonceptivos(bool v) => state = state.copyWith(usaAnticonceptivos: v);
  void setFaseCiclo(String v) => state = state.copyWith(faseCicloActual: v);
  void setTieneMiBand(bool v) => state = state.copyWith(tieneMiBand: v);

  void estimateBodyFatFromCircumferences() {
    final c = state.cinturaCm;
    final h = state.caderaCm;
    final n = state.cuelloCm;
    if (c != null && h != null && n != null) {
      final estimated = NutritionCalculator.estimateBodyFatNavyFormula(
        alturaCm: state.alturaCm,
        cinturaCm: c,
        caderaCm: h,
        cuelloCm: n,
        sexo: 'femenino',
      );
      if (estimated != null) {
        state = state.copyWith(porcentajeGrasa: estimated);
      }
    }
  }

  Future<bool> saveAndFinish() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final userId = await _db.userDao.insertUser(UsersCompanion(
        nombre: Value(state.nombre),
        fechaNacimiento: Value(state.fechaNacimiento ?? DateTime(1990)),
        pesoKg: Value(state.pesoKg),
        alturaCm: Value(state.alturaCm),
        porcentajeGrasa: Value(state.porcentajeGrasa),
        objetivo: Value(state.objetivo),
        nivelExperiencia: Value(state.nivelExperiencia),
        diasDisponibles: Value(state.diasDisponibles),
        equipamiento: Value(state.equipamiento),
        limitaciones: Value(state.limitaciones.join(',')),
        duracionSesionMax: Value(state.duracionSesionMax),
        usaAnticonceptivos: Value(state.usaAnticonceptivos),
        faseCicloActual: Value(state.faseCicloActual),
        fechaRegistro: Value(DateTime.now()),
        tieneMiBand: Value(state.tieneMiBand),
        onboardingCompleto: const Value(true),
      ));

      // Registrar peso inicial
      await _db.userDao.insertBodyMetric(BodyMetricsCompanion(
        userId: Value(userId),
        fecha: Value(DateTime.now()),
        pesoKg: Value(state.pesoKg),
      ));

      // Seed exercises
      final count = await _db.exerciseDao.countExercises();
      if (count == 0) {
        for (final ex in exercisesCatalog) {
          await _db.exerciseDao.insertExercise(ex);
        }
      }

      // Seed foods
      final foodCount = await _db.nutritionDao.countFoods();
      if (foodCount == 0) {
        for (final food in foodsCatalog) {
          await _db.nutritionDao.insertFood(food);
        }
      }

      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.watch(databaseProvider));
});
