import '../constants/app_constants.dart';

enum Objetivo { recomposicion, perdidaGrasa, gananciaMusculo }
enum NivelActividad { sedentaria, ligeramenteActiva, moderadamenteActiva, muyActiva }
enum FaseCiclo { menstruacion, folicular, ovulacion, lutea }

class MacroResult {
  final double calorias;
  final double proteinasG;
  final double carbosG;
  final double grasasG;
  final double aguaMl;
  final double masaMagraKg;

  const MacroResult({
    required this.calorias,
    required this.proteinasG,
    required this.carbosG,
    required this.grasasG,
    required this.aguaMl,
    required this.masaMagraKg,
  });
}

class NutritionCalculator {
  static double calcMasaMagra(double pesoKg, double porcentajeGrasa) {
    return pesoKg * (1 - porcentajeGrasa / 100);
  }

  static double calcBmr(double masaMagraKg) {
    return 370 + (21.6 * masaMagraKg);
  }

  static double calcTdee(double bmr, NivelActividad nivel) {
    final factors = {
      NivelActividad.sedentaria: AppConstants.activitySedentary,
      NivelActividad.ligeramenteActiva: AppConstants.activityLight,
      NivelActividad.moderadamenteActiva: AppConstants.activityModerate,
      NivelActividad.muyActiva: AppConstants.activityActive,
    };
    return bmr * (factors[nivel] ?? AppConstants.activityModerate);
  }

  static double calcTdeeFromSteps(double bmr, double avgStepsPerDay) {
    // Estimación basada en pasos: <5000 sedentaria, 5000-7500 ligera, 7500-10000 moderada, >10000 activa
    if (avgStepsPerDay < 5000) return bmr * AppConstants.activitySedentary;
    if (avgStepsPerDay < 7500) return bmr * AppConstants.activityLight;
    if (avgStepsPerDay < 10000) return bmr * AppConstants.activityModerate;
    return bmr * AppConstants.activityActive;
  }

  static double calcCaloriasObjetivo(double tdee, Objetivo objetivo) {
    switch (objetivo) {
      case Objetivo.perdidaGrasa:
        return tdee * AppConstants.deficitFatLoss;
      case Objetivo.recomposicion:
        return tdee * AppConstants.deficitRecomp;
      case Objetivo.gananciaMusculo:
        return tdee * AppConstants.surplusMuscleBuild;
    }
  }

  static MacroResult calcMacros({
    required double pesoKg,
    required double porcentajeGrasa,
    required Objetivo objetivo,
    required NivelActividad actividad,
    required FaseCiclo faseCiclo,
    required bool esDiaEntreno,
    double? stepsPromedio,
  }) {
    final masaMagra = calcMasaMagra(pesoKg, porcentajeGrasa);
    final bmr = calcBmr(masaMagra);
    final tdee = stepsPromedio != null
        ? calcTdeeFromSteps(bmr, stepsPromedio)
        : calcTdee(bmr, actividad);
    final calBase = calcCaloriasObjetivo(tdee, objetivo);

    // Ajuste por fase lútea
    double calObjetivo = calBase;
    if (faseCiclo == FaseCiclo.lutea) {
      calObjetivo += calBase * AppConstants.lutealCarbBoost;
    }
    if (esDiaEntreno) {
      calObjetivo += calBase * AppConstants.trainingDaysCarbBoost;
    }

    // 1. Proteína (basada en masa magra)
    final protFactor = faseCiclo == FaseCiclo.lutea
        ? AppConstants.proteinPerKgLeanMassLuteal
        : AppConstants.proteinPerKgLeanMass;
    final protG = masaMagra * protFactor;
    final protCal = protG * AppConstants.calPerGProtein;

    // 2. Grasas (mínimo)
    final grasasG = pesoKg * AppConstants.fatPerKgBodyWeight;
    final grasasCal = grasasG * AppConstants.calPerGFat;

    // 3. Carbos: calorías restantes
    final carbsCal = calObjetivo - protCal - grasasCal;
    final carbosG = carbsCal > 0 ? carbsCal / AppConstants.calPerGCarb : 0;

    // Agua
    double aguaMl = pesoKg * AppConstants.waterMlPerKg;
    if (esDiaEntreno) aguaMl += AppConstants.waterMlPerTrainingHour;

    return MacroResult(
      calorias: calObjetivo,
      proteinasG: protG,
      carbosG: carbosG,
      grasasG: grasasG,
      aguaMl: aguaMl,
      masaMagraKg: masaMagra,
    );
  }

  // Fórmula de la Marina de EE.UU. para estimar % grasa desde circunferencias
  static double? estimateBodyFatNavyFormula({
    required double alturaCm,
    required double cinturaCm,
    required double caderaCm,
    required double cuelloCm,
    required String sexo, // 'femenino'
  }) {
    if (sexo == 'femenino') {
      final result = 163.205 *
              (cinturaCm + caderaCm - cuelloCm).log() -
          97.684 * alturaCm.log() -
          78.387;
      return result.clamp(5, 50);
    }
    return null;
  }
}

extension on double {
  double log() => _log(this);
}

double _log(double x) {
  // log10 aproximado usando ln
  return 0.4342944819 * _ln(x);
}

double _ln(double x) {
  if (x <= 0) return double.negativeInfinity;
  // Newton-Raphson
  double result = 0;
  double temp = x;
  while (temp > 2) {
    temp /= 2;
    result += 0.6931471806; // ln(2)
  }
  while (temp < 0.5) {
    temp *= 2;
    result -= 0.6931471806;
  }
  final y = temp - 1;
  result += y - y * y / 2 + y * y * y / 3 - y * y * y * y / 4;
  return result;
}
