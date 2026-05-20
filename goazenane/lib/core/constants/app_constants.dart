abstract class AppConstants {
  // Nutrición
  static const double proteinPerKgLeanMass = 2.4;
  static const double proteinPerKgLeanMassLuteal = 2.6;
  static const double fatPerKgBodyWeight = 0.8;
  static const double waterMlPerKg = 35.0;
  static const double waterMlPerTrainingHour = 500.0;
  static const double waterMlHiit = 300.0;

  // Calorías por macro
  static const double calPerGProtein = 4.0;
  static const double calPerGCarb = 4.0;
  static const double calPerGFat = 9.0;

  // Factores de actividad (Katch-McArdle)
  static const double activitySedentary = 1.2;
  static const double activityLight = 1.375;
  static const double activityModerate = 1.55;
  static const double activityActive = 1.725;

  // Déficit/superávit calórico
  static const double deficitFatLoss = 0.80;        // TDEE × 0.80
  static const double deficitRecomp = 0.925;         // TDEE × 0.925
  static const double surplusMuscleBuild = 1.10;     // TDEE × 1.10

  // Sobrecarga progresiva
  static const double progressionFullCompletion = 0.025;  // +2.5%
  static const double completionThresholdFull = 1.0;
  static const double completionThresholdPartial = 0.90;
  static const double completionThresholdIncomplete = 0.80;

  // Deload triggers
  static const double deloadRpeThreshold = 8.5;
  static const double performanceDropThreshold = 0.05;   // -5%
  static const int fatigueReportDays = 3;
  static const double hrRestRiseThreshold = 7.0;         // +7 bpm
  static const int hrRestRiseDays = 3;

  // Deload protocol
  static const double deloadVolumeRatio = 0.45;   // 40-50%
  static const double deloadLoadRatio = 0.65;     // 60-70%

  // Sueño
  static const double sleepThresholdLow = 6.0;
  static const double sleepThresholdCritical = 5.0;
  static const double sleepDeepMinPercent = 0.20;
  static const double sleepVolumePenaltyLow = 0.85;

  // Ciclo menstrual
  static const double menstrualVolumeFactor = 0.80;
  static const double lutealCarbBoost = 0.125;           // +12.5% promedio
  static const double trainingDaysCarbBoost = 0.15;

  // Cardio zonas FC
  static const double lissMinHrPercent = 0.60;
  static const double lissMaxHrPercent = 0.70;

  // Periodización volumen series semanales por grupo
  static const Map<String, Map<String, int>> weeklySeriesMin = {
    'principiante': {'min': 10, 'max': 12},
    'intermedio': {'min': 14, 'max': 16},
    'avanzado': {'min': 16, 'max': 20},
  };

  // Descanso entre series (segundos)
  static const int restHypertrophy = 90;
  static const int restStrength = 150;

  // Transición de fases
  static const double advanceRpeThreshold = 8.0;
  static const double stallRpeThreshold = 6.5;
  static const double sessionCompletionMinimum = 0.80;
}
