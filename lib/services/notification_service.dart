import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../model/debt.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Inicialización ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Pedir permiso en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ─── Detalles de canal ───────────────────────────────────────────────────

  NotificationDetails get _debtNotificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(   // sin const
      'debt_reminders',
      'Recordatorios de Deudas',
      channelDescription: 'Notificaciones de vencimiento de deudas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE53935),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─── Programar recordatorio para una deuda ───────────────────────────────

  /// Programa tres notificaciones para una deuda:
  ///   • 7 días antes del vencimiento
  ///   • 3 días antes
  ///   • El día del vencimiento
  Future<void> scheduleDebtReminders(Debt debt) async {
    await initialize();
    if (debt.id == null) return;

    // Cancelar recordatorios previos de esta deuda antes de reprogramar
    await cancelDebtReminders(debt.id!);

    final offsets = [7, 3, 0];

    for (final daysBeforeDue in offsets) {
      final notifDate =
          debt.dueDate.subtract(Duration(days: daysBeforeDue));

      // No programar si la fecha ya pasó
      if (notifDate.isBefore(DateTime.now())) continue;

      final tzDate = tz.TZDateTime.from(notifDate, tz.local);

      final String title;
      final String body;

      if (daysBeforeDue == 0) {
        title = '⚠️ Deuda vence HOY';
        body = '"${debt.name}" vence hoy. Saldo pendiente: \$${debt.remaining.toStringAsFixed(2)}';
      } else {
        title = '🔔 Deuda próxima a vencer';
        body =
            '"${debt.name}" vence en $daysBeforeDue días. Saldo: \$${debt.remaining.toStringAsFixed(2)}';
      }

      // ID único: debtId * 10 + offset (evita colisiones)
      final notifId = _notifId(debt.id!, daysBeforeDue);

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tzDate,
        _debtNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'debt_${debt.id}',
      );
    }
  }

  /// Cancela todos los recordatorios de una deuda específica
  Future<void> cancelDebtReminders(int debtId) async {
    for (final offset in [7, 3, 0]) {
      await _plugin.cancel(_notifId(debtId, offset));
    }
  }

  /// Reprograma los recordatorios de todas las deudas activas.
  /// Llamar desde main.dart al arrancar la app.
  Future<void> rescheduleAllDebtReminders(List<Debt> activeDebts) async {
    await initialize();
    for (final debt in activeDebts) {
      if (debt.remaining > 0) {
        await scheduleDebtReminders(debt);
      } else {
        if (debt.id != null) await cancelDebtReminders(debt.id!);
      }
    }
  }

  /// Muestra una notificación inmediata (útil para pruebas o confirmaciones)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(id, title, body, _debtNotificationDetails);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Genera un ID de notificación único basado en debtId y días antes
  int _notifId(int debtId, int daysOffset) {
    // daysOffset puede ser 0, 3 o 7 → mapeamos a 0, 1, 2
    final slot = daysOffset == 0
        ? 0
        : daysOffset == 3
            ? 1
            : 2;
    return debtId * 10 + slot;
  }
}