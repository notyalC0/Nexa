import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço singleton para gerenciamento de notificações locais.
///
/// Suporte: Android e iOS apenas. Em desktop e web, todos os métodos
/// retornam imediatamente sem efeito colateral.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── IDs dos canais / notificações ────────────────────────────────────────
  static const int _dailyReminderId = 0;
  static const String _channelId = 'nexa_reminders';
  static const String _channelName = 'Lembretes Nexa';
  static const String _channelDesc =
      'Lembretes diários para registrar seus gastos no Nexa.';

  // ── Guard de plataforma ──────────────────────────────────────────────────

  /// Indica se notificações locais são suportadas na plataforma atual.
  /// Retorna [true] apenas em Android e iOS.
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ── Inicialização ────────────────────────────────────────────────────────

  /// Inicializa o plugin de notificações e configura os fusos horários.
  /// Deve ser chamado uma única vez em [main].
  Future<void> init() async {
    if (!isSupported) return;
    if (_initialized) return;

    // Carrega base de dados de fusos horários e define o fuso local
    tz.initializeTimeZones();
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Fallback: mantém UTC se não conseguir o fuso
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const iosSettings = DarwinInitializationSettings(
      // Permissões são pedidas explicitamente via requestPermissions()
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ── Permissões ───────────────────────────────────────────────────────────

  /// Solicita permissão ao sistema para exibir notificações.
  /// Retorna [true] se a permissão foi concedida.
  Future<bool> requestPermissions() async {
    if (!_initialized) return false;

    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await impl?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await impl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  // ── Lembrete diário ──────────────────────────────────────────────────────

  /// Agenda um lembrete diário recorrente no horário [hour]:[minute].
  /// Substitui qualquer lembrete anterior agendado.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) return;

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '💰 Hora de registrar!',
      'Não se esqueça de anotar seus gastos de hoje no Nexa.',
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // inexact: não requer SCHEDULE_EXACT_ALARM; tolerância de alguns minutos
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // repete diariamente no mesmo horário
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela o lembrete diário agendado.
  Future<void> cancelDailyReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyReminderId);
  }

  /// Ativa ou desativa o lembrete diário conforme [enabled].
  /// Quando ativando, agenda no horário [hour]:[minute].
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  /// Cancela absolutamente todas as notificações do app.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Retorna o próximo [tz.TZDateTime] correspondente a [hour]:[minute].
  /// Se o horário de hoje já passou, retorna o de amanhã.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
