import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleInactivityReminder() async {
    final messages = [
      'Tu cuerpo está esperando. ¿Vamos?',
      'Un entrenamiento más cerca de tu objetivo.',
      'La consistencia gana a la perfección. 5 minutos para empezar.',
      'Tu futura yo te lo agradecerá.',
      'El descanso ya fue. Hoy toca moverse.',
    ];
    final msg = messages[DateTime.now().day % messages.length];

    await _plugin.zonedSchedule(
      1001,
      'Goazenane',
      msg,
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity',
          'Recordatorio de entrenamiento',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleWaterReminder() async {
    for (int hour in [9, 11, 13, 15, 17, 19]) {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, hour);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        2000 + hour,
        'Hidratación',
        'Recuerda beber agua — óptima recuperación muscular.',
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water',
            'Recordatorio de agua',
            importance: Importance.low,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showDeloadAlert() async {
    await _plugin.show(
      3001,
      'Semana de deload activa',
      'Tu cuerpo necesita recuperarse para crecer. Esta semana es parte del plan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deload',
          'Alerta de deload',
          importance: Importance.high,
          color: Color(0xFFFF6B2B),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showSleepAlert(String message) async {
    await _plugin.show(
      3002,
      'Recuperación',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep',
          'Alerta de sueño',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showRestTimerAlert() async {
    await _plugin.show(
      4001,
      'Descanso terminado',
      '¡Siguiente serie!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Temporizador de descanso',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showAchievementUnlocked(String title) async {
    await _plugin.show(
      5000 + DateTime.now().millisecond,
      'Logro desbloqueado!',
      title,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievement',
          'Logros',
          importance: Importance.defaultImportance,
          color: Color(0xFF4CAF50),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
