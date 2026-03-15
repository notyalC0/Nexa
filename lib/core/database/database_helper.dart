import 'package:flutter/foundation.dart';
import 'package:nexa/core/database/default_categories.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/models/credit_cards.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'nexa.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _removeDuplicateCategoriesFromDb(db);
      await _createIndexes(db);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color_hex TEXT NOT NULL,
      type TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0
    )
  ''');
    await db.execute('''
    CREATE TABLE credit_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_limit_cents INTEGER NOT NULL,
        closing_day INTEGER NOT NULL,
        due_day INTEGER NOT NULL,
        color_hex TEXT,
        bank_keyword TEXT NOT NULL
        )
  ''');
    await db.execute('''
    CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_cents INTEGER NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        credit_cards_id INTEGER,
        installment_total INTEGER,
        installment_current INTEGER,
        installment_group_id TEXT,
        is_recurring INTEGER,
        note TEXT,
        created_from_notification INTEGER,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (credit_cards_id) REFERENCES credit_cards(id)
        )
  ''');
    await db.execute('''
    CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        update_at TEXT
        )
  ''');
    await _removeDuplicateCategoriesFromDb(db);
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name_type_unique
      ON categories(name, type)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_date
      ON transactions(date)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_type_status_date
      ON transactions(type, status, date)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_card_date
      ON transactions(credit_cards_id, date)
    ''');
  }

  Future<void> _removeDuplicateCategoriesFromDb(DatabaseExecutor db) async {
    await db.execute('''
      DELETE FROM categories
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM categories
        GROUP BY name, type
      )
    ''');
  }

  Future<void> ensureDefaultCategories(List<Categories> defaultCategories) async {
    final db = await database;
    await db.transaction((txn) async {
      await _removeDuplicateCategoriesFromDb(txn);
      final batch = txn.batch();

      for (final category in defaultCategories) {
        batch.insert(
          'categories',
          category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(noResult: true);
    });
  }

//queries

//#region Category
  Future<List<Categories>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'type ASC, name COLLATE NOCASE ASC',
    );
    return List.generate(maps.length, (i) => Categories.fromMap(maps[i]));
  }

  Future<int> insertCategory(Categories categories) async {
    final db = await database;
    return db.insert(
      'categories',
      categories.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

//#endregion

//#region Transactions
  Future<List<Transactions>> getTransactionsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'date DESC, id DESC',
    );
    if (kDebugMode) {
      debugPrint('Buscando mês: $month');
      debugPrint('Encontrou: ${maps.length} transações');
    }
    return List.generate(maps.length, (i) => Transactions.fromMap(maps[i]));
  }

  Future<int> insertTransaction(Transactions transaction) async {
    final db = await database;
    return db.insert(
      'transactions',
      transaction.toMap(),
    );
  }

  Future<int> updateTransaction(Transactions transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGroupTransaction(String groupId) async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'installment_group_id = ?',
      whereArgs: [groupId],
    );
  }
//#endregion

//#region CreditCards
  Future<List<CreditCards>> getCreditCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'credit_cards',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return List.generate(maps.length, (i) => CreditCards.fromMap(maps[i]));
  }

  Future<int> insertCreditCards(CreditCards creditCards) async {
    final db = await database;
    return db.insert('credit_cards', creditCards.toMap());
  }

  Future<int> updateCreditCards(CreditCards creditCards) async {
    final db = await database;
    return db.update(
      'credit_cards',
      creditCards.toMap(),
      where: 'id = ?',
      whereArgs: [creditCards.id],
    );
  }

  Future<int> deleteCreditCards(int id) async {
    final db = await database;
    return db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
//#endregion

  Future<int> getCardUsedLimitForMonth(int cardId, String month) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE type = 'expense'
    AND credit_cards_id = ?
    AND status IN ('confirmed', 'pending')
    AND date LIKE ?
  ''', [cardId, '$month%']);

    return result.first['total'] as int? ?? 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      try {
        await txn.delete('transactions');
        await txn.delete('credit_cards');
        await txn.delete('categories');
        await txn.delete('settings');

        final batch = txn.batch();
        for (final category in buildDefaultCategories()) {
          batch.insert(
            'categories',
            category.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);

        await txn.execute('''
          DELETE FROM sqlite_sequence
          WHERE name IN ('transactions', 'credit_cards', 'categories')
        ''');
      } finally {
        await txn.execute('PRAGMA foreign_keys = ON');
      }
    });
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getTotalExpensesForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE type = 'expense'
    AND status = 'confirmed'
    AND date LIKE ?
  ''', ['$month%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalPendingExpensesForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE type = 'expense'
    AND status = 'pending'
    AND date LIKE ?
  ''', ['$month%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalIncomeForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE type = 'income'
    AND status = 'confirmed'
    AND date LIKE ?
  ''', ['$month%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getBalanceForMonth(String month) async {
    final income = await getTotalIncomeForMonth(month);
    final expense = await getTotalExpensesForMonth(month);
    return income - expense;
  }

  Future<int> getProjectedBalanceForMonth(String month) async {
    final available = await getBalanceForMonth(month);
    final pending = await getTotalPendingExpensesForMonth(month);
    return available - pending;
  }
}
