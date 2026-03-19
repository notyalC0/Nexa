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
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _removeDuplicateCategoriesFromDb(db);
      await _createIndexes(db);
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurring_id TEXT',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN parent_id INTEGER',
      );
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_recurring_group
        ON transactions(recurring_id, parent_id, date)
      ''');

      final recurringMaps = await db.query(
        'transactions',
        columns: ['id'],
        where: 'is_recurring = 1',
      );
      for (final row in recurringMaps) {
        final id = row['id'] as int?;
        if (id == null) continue;
        await db.update(
          'transactions',
          {
            'recurring_id': 'legacy-$id',
            'parent_id': id,
          },
          where: 'id = ? AND recurring_id IS NULL',
          whereArgs: [id],
        );
      }
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
        recurring_id TEXT,
        parent_id INTEGER,
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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_recurring_group
      ON transactions(recurring_id, parent_id, date)
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
    await _ensureRecurringTransactionsForMonth(month);
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

  Future<void> _ensureRecurringTransactionsForMonth(String month) async {
    final db = await database;
    final targetMonth = DateTime.parse('$month-01');
    final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    final targetMonthKey = _formatMonth(targetMonth);

    final recurringMaps = await db.query(
      'transactions',
      where: 'is_recurring = 1 AND date < ?',
      whereArgs: [_formatDate(nextMonth)],
      orderBy: 'date ASC, id ASC',
    );

    if (recurringMaps.isEmpty) return;

    final existingRecurringInMonth = await db.query(
      'transactions',
      columns: [
        'amount_cents',
        'type',
        'status',
        'description',
        'date',
        'category_id',
        'credit_cards_id',
        'installment_total',
        'installment_current',
        'installment_group_id',
        'is_recurring',
        'recurring_id',
        'parent_id',
        'note',
      ],
      where: 'is_recurring = 1 AND date LIKE ?',
      whereArgs: ['$targetMonthKey%'],
    );

    final existingKeys = existingRecurringInMonth
        .map((row) => _buildRecurringKey(row, row['date'] as String))
        .toSet();

    for (final map in recurringMaps) {
      final recurring = Transactions.fromMap(map);
      final baseDate = DateTime.parse(recurring.date);
      final rootParentId = recurring.parentId ?? recurring.id;
      final recurringId = recurring.recurringId ?? 'legacy-${rootParentId ?? recurring.id ?? 0}';

      DateTime candidateDate =
          DateTime(baseDate.year, baseDate.month + 1, baseDate.day);

      while (candidateDate.isBefore(nextMonth)) {
        if (_formatMonth(candidateDate) == targetMonthKey) {
          final candidateDateStr = _formatDate(candidateDate);
          final key = _buildRecurringKey({...map, 'recurring_id': recurringId, 'parent_id': rootParentId}, candidateDateStr);

          if (!existingKeys.contains(key)) {
            await db.insert('transactions', {
              ...recurring.toMap(),
              'date': candidateDateStr,
              'recurring_id': recurringId,
              'parent_id': rootParentId,
            });
            existingKeys.add(key);
          }
        }

        candidateDate =
            DateTime(candidateDate.year, candidateDate.month + 1, candidateDate.day);
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatMonth(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String _buildRecurringKey(Map<String, dynamic> transactionMap, String date) {
    return [
      transactionMap['amount_cents'],
      transactionMap['type'],
      transactionMap['status'],
      transactionMap['description'] ?? '',
      date,
      transactionMap['category_id'],
      transactionMap['credit_cards_id'] ?? '',
      transactionMap['installment_total'] ?? '',
      transactionMap['installment_current'] ?? '',
      transactionMap['installment_group_id'] ?? '',
      transactionMap['is_recurring'] ?? 0,
      transactionMap['recurring_id'] ?? '',
      transactionMap['parent_id'] ?? '',
      transactionMap['note'] ?? '',
    ].join('|');
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

  Future<int> deleteTransaction(int id, {bool deleteAll = false}) async {
    final db = await database;
    if (!deleteAll) {
      return db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return 0;

    final transaction = Transactions.fromMap(maps.first);
    if (!transaction.isRecurring) {
      return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }

    final rootParentId = transaction.parentId ?? transaction.id;
    final recurringId = transaction.recurringId;
    final clauses = <String>[];
    final args = <Object?>[];

    if (recurringId != null && recurringId.isNotEmpty) {
      clauses.add('recurring_id = ?');
      args.add(recurringId);
    }
    if (rootParentId != null) {
      clauses.add('parent_id = ?');
      args.add(rootParentId);
      clauses.add('id = ?');
      args.add(rootParentId);
    }

    if (clauses.isEmpty) {
      return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }

    return db.delete(
      'transactions',
      where: '(${clauses.join(' OR ')}) AND date >= ?',
      whereArgs: [...args, transaction.date],
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

  Future<int> getCardUsedLimit(int cardId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE type = 'expense'
    AND credit_cards_id = ?
    AND status IN ('confirmed', 'pending')
  ''', [cardId]);

    return result.first['total'] as int? ?? 0;
  }

  Future<int> getInstallmentGroupTotalAmount(String groupId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT SUM(amount_cents) as total FROM transactions
    WHERE installment_group_id = ?
  ''', [groupId]);

    return result.first['total'] as int? ?? 0;
  }

  Future<List<Transactions>> getInstallmentsByGroup(String groupId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'installment_group_id = ?',
      whereArgs: [groupId],
      orderBy: 'installment_current ASC, date ASC, id ASC',
    );

    return List.generate(maps.length, (i) => Transactions.fromMap(maps[i]));
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

  Future<int> getBalanceForMonth(String month, {bool includeCarryOver = true}) async {
    final income = await getTotalIncomeForMonth(month);
    final expense = await getTotalExpensesForMonth(month);
    final carryOver = includeCarryOver ? await getCarryOverForMonth(month) : 0;
    return carryOver + income - expense;
  }

  Future<int> getCarryOverForMonth(String month) async {
    final target = DateTime.parse('$month-01');
    var runningCarryOver = 0;
    var cursor = await getFirstTransactionMonth();

    while (cursor != null && cursor.isBefore(target)) {
      final currentMonth = _formatMonth(cursor);
      final income = await getTotalIncomeForMonth(currentMonth);
      final expense = await getTotalExpensesForMonth(currentMonth);
      final finalBalance = runningCarryOver + income - expense;
      runningCarryOver = finalBalance > 0 ? finalBalance : 0;
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return runningCarryOver;
  }

  Future<DateTime?> getFirstTransactionMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT date
      FROM transactions
      ORDER BY date ASC, id ASC
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    final rawDate = result.first['date'] as String?;
    if (rawDate == null || rawDate.isEmpty) return null;
    final date = DateTime.parse(rawDate);
    return DateTime(date.year, date.month, 1);
  }

  Future<int> getProjectedBalanceForMonth(String month) async {
    final available = await getBalanceForMonth(month);
    final pending = await getTotalPendingExpensesForMonth(month);
    return available - pending;
  }
}
