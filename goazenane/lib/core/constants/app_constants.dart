abstract class AppConstants {
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
