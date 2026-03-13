import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/features/home/screens/home_screen.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed temporário — remove depois
  final db = DatabaseHelper.instance;
// Apaga o banco para começar limpo
  final dbPath = join(await getDatabasesPath(), 'nexa.db');
  await deleteDatabase(dbPath);

  await db.insertCategory(Categories(
    name: 'Alimentação',
    icon: 'restaurant',
    colorHex: '#FF6B35',
    type: 'expense',
  ));

  await db.insertTransaction(Transactions(
    amountCents: 4750,
    type: 'expense',
    status: 'confirmed',
    date: '2026-03-10',
    categoryID: 1,
    isRecurring: false,
    createdFromNotification: false,
    description: 'Mercado',
  ));

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
