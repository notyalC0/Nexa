import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/features/home/screens/home_screen.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final db = DatabaseHelper.instance;
  final defaultCategories = [
    Categories(
      name: 'Alimentação',
      icon: 'restaurant',
      colorHex: '#FF6B35',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Transporte',
      icon: 'directions_car',
      colorHex: '#4D96FF',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Lazer',
      icon: 'sports_esports',
      colorHex: '#A66CFF',
      type: 'expense',
      isDefault: true,
    ),
    Categories(
      name: 'Saúde',
      icon: 'health_and_safety',
      colorHex: '#2ECC71',
      type: 'expense',
      isDefault: true,
    ),
  ];

  await db.ensureDefaultCategories(defaultCategories);

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
