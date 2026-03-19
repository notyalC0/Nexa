import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';

class AppSettingsState {
  final int salaryCents;
  final int emergencyGoalCents;
  final int emergencyCurrentCents;
  final int healthAlertThreshold;
  final bool notificationsEnabled;
  final bool darkMode;
  final bool hideBalance;
  final String selectedCurrency;

  const AppSettingsState({
    required this.salaryCents,
    required this.emergencyGoalCents,
    required this.emergencyCurrentCents,
    required this.healthAlertThreshold,
    required this.notificationsEnabled,
    required this.darkMode,
    required this.hideBalance,
    required this.selectedCurrency,
  });

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;
}

class AppSettingsNotifier extends AsyncNotifier<AppSettingsState> {
  final _db = DatabaseHelper.instance;

  @override
  Future<AppSettingsState> build() async {
    final salary = int.tryParse(await _db.getSetting('monthly_salary_cents') ?? '0') ?? 0;
    final emergencyGoal = int.tryParse(await _db.getSetting('emergency_goal_cents') ?? '0') ?? 0;
    final emergencyCurrent = int.tryParse(await _db.getSetting('emergency_current_cents') ?? '0') ?? 0;
    final threshold = int.tryParse(await _db.getSetting('health_alert_threshold') ?? '80') ?? 80;
    final notifications = (await _db.getSetting('notifications_enabled') ?? '1') == '1';
    final darkMode = (await _db.getSetting('dark_mode') ?? '0') == '1';
    final hideBalance = (await _db.getSetting('hide_balance') ?? '0') == '1';
    final currency = await _db.getSetting('selected_currency') ?? 'BRL';

    return AppSettingsState(
      salaryCents: salary,
      emergencyGoalCents: emergencyGoal,
      emergencyCurrentCents: emergencyCurrent,
      healthAlertThreshold: threshold,
      notificationsEnabled: notifications,
      darkMode: darkMode,
      hideBalance: hideBalance,
      selectedCurrency: currency,
    );
  }

  Future<void> saveMoneySetting(String key, int cents) async {
    await _db.saveSetting(key, cents.toString());
    ref.invalidateSelf();
  }

  Future<void> saveStringSetting(String key, String value) async {
    await _db.saveSetting(key, value);
    ref.invalidateSelf();
  }

  Future<void> saveBoolSetting(String key, bool value) async {
    await _db.saveSetting(key, value ? '1' : '0');
    ref.invalidateSelf();
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);
