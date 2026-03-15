import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final db = DatabaseHelper.instance;

  await db.insertCategory(Categories(
    name: 'Alimentação',
    icon: 'restaurant',
    colorHex: '#FF6B35',
    type: 'expense',
  ));

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nexa',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen());
  }
}
