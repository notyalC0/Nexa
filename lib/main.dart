import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/database/default_categories.dart';
import 'package:nexa/core/notifications/notification_service.dart';
import 'package:nexa/features/home/screens/home_screen.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Inicializa SQLite FFI para desktop (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final db = DatabaseHelper.instance;
  final defaultCategories = buildDefaultCategories();

  await db.ensureDefaultCategories(defaultCategories);

  // Inicializa notificações (apenas Android/iOS)
  await NotificationService.instance.init();

  // Reagenda o lembrete diário caso o app tenha sido reiniciado
  final notifEnabled =
      (await db.getSetting('notifications_enabled') ?? '1') == '1';
  if (notifEnabled) {
    final hour =
        int.tryParse(await db.getSetting('reminder_hour') ?? '20') ?? 20;
    final minute =
        int.tryParse(await db.getSetting('reminder_minute') ?? '0') ?? 0;
    await NotificationService.instance
        .scheduleDailyReminder(hour: hour, minute: minute);
  }

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = settings.maybeWhen(
      data: (value) => value.themeMode,
      orElse: () => ThemeMode.system,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexa',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
