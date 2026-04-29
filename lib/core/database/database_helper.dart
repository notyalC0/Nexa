import 'package:flutter/foundation.dart';
import 'package:nexa/core/database/default_categories.dart';
import 'package:nexa/core/models/category_goal.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/models/credit_cards.dart';
import 'package:nexa/core/models/goals.dart';
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
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _removeDuplicateCategoriesFromDb(db);
      await _createLegacyIndexes(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN recurring_id TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN parent_id INTEGER');
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
          {'recurring_id': 'legacy-$id', 'parent_id': id},
          where: 'id = ? AND recurring_id IS NULL',
          whereArgs: [id],
        );
      }
    }
    if (oldVersion < 4) {
      await _migrateV3ToV4(db);
    }
    if (oldVersion < 5) {
      await _createCategoryGoalsTable(db);
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
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        update_at TEXT
      )
    ''');
    await _createGoalsTable(db);
    await _createCategoryGoalsTable(db);
    await _createTransactionsTableV4(db);
    await _ensureDefaultGoal(db);
    await _removeDuplicateCategoriesFromDb(db);
    await _createIndexes(db);
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name_type_unique
      ON categories(name, type)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_purchase_date
      ON transactions(purchase_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_effective_date
      ON transactions(effective_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_type_status_effective_date
      ON transactions(type, status, effective_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_card_purchase_date
      ON transactions(credit_cards_id, purchase_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_goal_id
      ON transactions(goal_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_recurring_group
      ON transactions(recurring_id, parent_id, purchase_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_goals_active
      ON goals(is_archived, is_default)
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_single_default
      ON goals(is_default)
      WHERE is_default = 1
    ''');
  }

  Future<void> _createLegacyIndexes(DatabaseExecutor db) async {
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

  Future<void> _createGoalsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount_cents INTEGER NOT NULL DEFAULT 0,
        initial_amount_cents INTEGER NOT NULL DEFAULT 0,
        target_date TEXT,
        icon TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_deletable INTEGER NOT NULL DEFAULT 1,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createCategoryGoalsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS category_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL UNIQUE,
        limit_cents INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTransactionsTableV4(DatabaseExecutor db,
      {String tableName = 'transactions'}) async {
    await db.execute('''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_cents INTEGER NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        purchase_date TEXT NOT NULL,
        effective_date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        credit_cards_id INTEGER,
        is_invoice_paid INTEGER,
        goal_id INTEGER,
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
        FOREIGN KEY (credit_cards_id) REFERENCES credit_cards(id),
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _migrateV3ToV4(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      try {
        await _createGoalsTable(txn);
        await _migrateEmergencySettingsToDefaultGoal(txn);
        await _createTransactionsTableV4(txn, tableName: 'transactions_v4');

        final cards = await txn.query('credit_cards');
        final cardMap = <int, CreditCards>{
          for (final row in cards)
            if (row['id'] != null) row['id'] as int: CreditCards.fromMap(row),
        };

        final transactions = await txn.query(
          'transactions',
          orderBy: 'id ASC',
        );

        for (final row in transactions) {
          final legacyDate = row['date'] as String?;
          if (legacyDate == null || legacyDate.isEmpty) continue;

          final purchaseDate = legacyDate;
          final creditCardId = row['credit_cards_id'] as int?;
          final card = creditCardId == null ? null : cardMap[creditCardId];
          final effectiveDate = card == null
              ? purchaseDate
              : _calculateEffectiveDateForCardPurchase(
                  purchaseDate: purchaseDate,
                  closingDay: card.closingDay,
                  dueDay: card.dueDay,
                );

          await txn.insert('transactions_v4', {
            'id': row['id'],
            'amount_cents': row['amount_cents'],
            'type': row['type'],
            'status': row['status'],
            'description': row['description'],
            'purchase_date': purchaseDate,
            'effective_date': effectiveDate,
            'category_id': row['category_id'],
            'credit_cards_id': creditCardId,
            'is_invoice_paid': null,
            'goal_id': null,
            'installment_total': row['installment_total'],
            'installment_current': row['installment_current'],
            'installment_group_id': row['installment_group_id'],
            'is_recurring': row['is_recurring'],
            'recurring_id': row['recurring_id'],
            'parent_id': row['parent_id'],
            'note': row['note'],
            'created_from_notification': row['created_from_notification'],
            'created_at': row['created_at'],
          });
        }

        await txn.execute('DROP TABLE transactions');
        await txn.execute('ALTER TABLE transactions_v4 RENAME TO transactions');
        await _createIndexes(txn);
      } finally {
        await txn.execute('PRAGMA foreign_keys = ON');
      }
    });
  }

  Future<void> _migrateEmergencySettingsToDefaultGoal(
      DatabaseExecutor db) async {
    final goalRaw = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['emergency_goal_cents'],
      limit: 1,
    );
    final currentRaw = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['emergency_current_cents'],
      limit: 1,
    );

    final targetValue =
        goalRaw.isEmpty ? null : goalRaw.first['value'] as String?;
    final currentValue =
        currentRaw.isEmpty ? null : currentRaw.first['value'] as String?;
    final targetAmount = int.tryParse(targetValue ?? '0') ?? 0;
    final initialAmount = int.tryParse(currentValue ?? '0') ?? 0;

    await _ensureDefaultGoal(
      db,
      targetAmountCents: targetAmount,
      initialAmountCents: initialAmount,
    );
  }

  Future<void> _ensureDefaultGoal(
    DatabaseExecutor db, {
    int targetAmountCents = 0,
    int initialAmountCents = 0,
  }) async {
    final existing = await db.query(
      'goals',
      columns: ['id'],
      where: 'is_default = 1',
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('goals', {
      'name': 'Reserva de emergência',
      'target_amount_cents': targetAmountCents,
      'initial_amount_cents': initialAmountCents,
      'target_date': null,
      'icon': 'shield',
      'color_hex': '#2ECC71',
      'is_default': 1,
      'is_deletable': 0,
      'is_archived': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': null,
    });
  }

  Future<void> _removeDuplicateCategoriesFromDb(DatabaseExecutor db) async {
    await db.execute('''
      DELETE FROM categories
      WHERE id NOT IN (
        SELECT MIN(id) FROM categories GROUP BY name, type
      )
    ''');
  }

  Future<void> ensureDefaultCategories(
      List<Categories> defaultCategories) async {
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

  // ─── CATEGORIES ────────────────────────────────────────────────────────────

  Future<List<Categories>> getCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy: 'type ASC, name COLLATE NOCASE ASC',
    );
    return maps.map(Categories.fromMap).toList();
  }

  Future<int> insertCategory(Categories category) async {
    final db = await database;
    return db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateCategory(Categories category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.transaction((txn) async {
      final fallbackMaps = await txn.query(
        'categories',
        columns: ['id'],
        where: 'LOWER(name) = ?',
        whereArgs: ['sem categoria'],
        limit: 1,
      );

      if (fallbackMaps.isEmpty) {
        throw Exception(
          'Não foi possível excluir a categoria porque "Sem categoria" não foi encontrada.',
        );
      }

      final fallbackId = fallbackMaps.first['id'] as int?;
      if (fallbackId == null || fallbackId == categoryId) {
        throw Exception(
          'A categoria "Sem categoria" não pode ser removida nem usada como destino inválido.',
        );
      }

      await txn.update(
        'transactions',
        {'category_id': fallbackId},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      await txn.delete(
        'category_goals',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  Future<bool> categoryHasTransactions(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total FROM transactions
      WHERE category_id = ?
    ''', [categoryId]);
    return (result.first['total'] as int? ?? 0) > 0;
  }

  // ─── GOALS ────────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals({bool includeArchived = false}) async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'is_default DESC, created_at ASC, id ASC',
    );
    return maps.map(Goal.fromMap).toList();
  }

  Future<Goal?> getGoalById(int id) async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  Future<Goal?> getDefaultGoal() async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: 'is_default = 1',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return db.insert('goals', goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete(
      'goals',
      where: 'id = ? AND is_deletable = 1',
      whereArgs: [id],
    );
  }

  Future<List<Transactions>> getTransactionsForGoal(
    int goalId, {
    bool confirmedOnly = false,
  }) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: confirmedOnly ? 'goal_id = ? AND status = ?' : 'goal_id = ?',
      whereArgs: confirmedOnly ? [goalId, 'confirmed'] : [goalId],
      orderBy: 'effective_date ASC, id ASC',
    );
    return maps.map(Transactions.fromMap).toList();
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<List<Transactions>> getTransactionsByMonth(String month) async {
    await _ensureRecurringTransactionsForMonth(month);
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'purchase_date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'purchase_date DESC, id DESC',
    );
    if (kDebugMode) {
      debugPrint('Buscando mês: $month → ${maps.length} transações');
    }
    return maps.map(Transactions.fromMap).toList();
  }

  Future<List<Transactions>> getTransactionsByEffectiveMonth(
      String month) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'effective_date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'effective_date DESC, id DESC',
    );
    return maps.map(Transactions.fromMap).toList();
  }

  Future<void> _ensureRecurringTransactionsForMonth(String month) async {
    final db = await database;
    final targetMonth = DateTime.parse('$month-01');
    final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    final targetMonthKey = _formatMonth(targetMonth);
    final cards = await db.query('credit_cards');
    final cardMap = <int, CreditCards>{
      for (final row in cards)
        if (row['id'] != null) row['id'] as int: CreditCards.fromMap(row),
    };

    final recurringMaps = await db.query(
      'transactions',
      where: 'is_recurring = 1 AND purchase_date < ?',
      whereArgs: [_formatDate(nextMonth)],
      orderBy: 'purchase_date ASC, id ASC',
    );
    if (recurringMaps.isEmpty) return;

    final existingRecurringInMonth = await db.query(
      'transactions',
      columns: [
        'amount_cents',
        'type',
        'status',
        'description',
        'purchase_date',
        'effective_date',
        'category_id',
        'credit_cards_id',
        'is_invoice_paid',
        'goal_id',
        'installment_total',
        'installment_current',
        'installment_group_id',
        'is_recurring',
        'recurring_id',
        'parent_id',
        'note',
      ],
      where: 'is_recurring = 1 AND purchase_date LIKE ?',
      whereArgs: ['$targetMonthKey%'],
    );

    final existingKeys = existingRecurringInMonth
        .map((row) => _buildRecurringKey(row, row['purchase_date'] as String))
        .toSet();

    for (final map in recurringMaps) {
      final recurring = Transactions.fromMap(map);
      final baseDate = DateTime.parse(recurring.purchaseDate);
      final rootParentId = recurring.parentId ?? recurring.id;
      final recurringId = recurring.recurringId ??
          'legacy-${rootParentId ?? recurring.id ?? 0}';

      DateTime candidateDate =
          DateTime(baseDate.year, baseDate.month + 1, baseDate.day);

      while (candidateDate.isBefore(nextMonth)) {
        if (_formatMonth(candidateDate) == targetMonthKey) {
          final candidateDateStr = _formatDate(candidateDate);
          final key = _buildRecurringKey(
            {...map, 'recurring_id': recurringId, 'parent_id': rootParentId},
            candidateDateStr,
          );
          if (!existingKeys.contains(key)) {
            final card = recurring.creditCardsId == null
                ? null
                : cardMap[recurring.creditCardsId!];
            final effectiveDate = card == null
                ? candidateDateStr
                : _calculateEffectiveDateForCardPurchase(
                    purchaseDate: candidateDateStr,
                    closingDay: card.closingDay,
                    dueDay: card.dueDay,
                  );
            await db.insert('transactions', {
              ...recurring.toMap(),
              'purchase_date': candidateDateStr,
              'effective_date': effectiveDate,
              'recurring_id': recurringId,
              'parent_id': rootParentId,
            });
            existingKeys.add(key);
          }
        }
        candidateDate = DateTime(
            candidateDate.year, candidateDate.month + 1, candidateDate.day);
      }
    }
  }

  Future<int> insertTransaction(Transactions transaction) async {
    final db = await database;
    return db.insert(
      'transactions',
      await _mapTransactionForPersistence(transaction),
    );
  }

  Future<int> updateTransaction(Transactions transaction) async {
    final db = await database;
    return db.update(
        'transactions', await _mapTransactionForPersistence(transaction),
        where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id, {bool deleteAll = false}) async {
    final db = await database;
    if (!deleteAll) {
      return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }

    final maps = await db.query('transactions',
        where: 'id = ?', whereArgs: [id], limit: 1);
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
      where: '(${clauses.join(' OR ')}) AND purchase_date >= ?',
      whereArgs: [...args, transaction.purchaseDate],
    );
  }

  Future<int> deleteGroupTransaction(String groupId) async {
    final db = await database;
    return db.delete('transactions',
        where: 'installment_group_id = ?', whereArgs: [groupId]);
  }

  /// Deleta todas as ocorrências futuras (inclusive a de [fromDate]) de uma
  /// série recorrente identificada por [recurringId].
  Future<int> deleteFutureRecurring(String recurringId, String fromDate) async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'recurring_id = ? AND purchase_date >= ?',
      whereArgs: [recurringId, fromDate],
    );
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
      orderBy: 'installment_current ASC, purchase_date ASC, id ASC',
    );
    return maps.map(Transactions.fromMap).toList();
  }

  // ─── CREDIT CARDS ──────────────────────────────────────────────────────────

  Future<List<CreditCards>> getCreditCards() async {
    final db = await database;
    final maps =
        await db.query('credit_cards', orderBy: 'name COLLATE NOCASE ASC');
    return maps.map(CreditCards.fromMap).toList();
  }

  Future<int> insertCreditCards(CreditCards card) async {
    final db = await database;
    return db.insert('credit_cards', card.toMap());
  }

  Future<int> updateCreditCards(CreditCards card) async {
    final db = await database;
    return db.update('credit_cards', card.toMap(),
        where: 'id = ?', whereArgs: [card.id]);
  }

  Future<int> deleteCreditCards(int id) async {
    final db = await database;
    return db.delete('credit_cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Busca um cartão específico pelo ID.
  /// Retorna null se não encontrado (cartão foi deletado, por exemplo).
  Future<CreditCards?> getCreditCardById(int id) async {
    final db = await database;
    final maps = await db.query('credit_cards',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return CreditCards.fromMap(maps.first);
  }

  // ─── CARD LIMIT ─────────────────────────────────────────────────────────────
  //
  // CORREÇÃO DA REGRA DE NEGÓCIO:
  //
  // O limite do cartão de crédito funciona assim no mundo real:
  //   - O cartão tem um "dia de fechamento" (ex: dia 10)
  //   - O ciclo vai do dia 11 do mês anterior até o dia 10 do mês atual
  //   - Quando a fatura fecha, o limite é "resetado" para o próximo ciclo
  //
  // Exemplo: closingDay = 10, hoje = 15/03
  //   → Ciclo atual: 11/02 até 10/03
  //   → Usamos as despesas desse período para calcular o limite usado
  //
  // O código ANTIGO somava TUDO desde sempre → limite nunca resetava (bug!)

  /// Calcula a data de fechamento para um determinado mês/ano,
  /// limitando o dia de fechamento ao último dia do mês, se necessário.
  DateTime _closingDateForMonth(int year, int month, int closingDay) {
    // DateTime(year, month + 1, 0) retorna o último dia do mês "month".
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final safeDay = closingDay > lastDayOfMonth ? lastDayOfMonth : closingDay;
    return DateTime(year, month, safeDay);
  }

  /// Retorna o intervalo do ciclo atual do cartão (início e fim)
  /// baseado no dia de fechamento.
  ({String start, String end}) _currentBillingCycle(int closingDay) {
    final now = DateTime.now();

    // Data de fechamento "real" deste mês, com o dia de fechamento
    // limitado ao último dia do mês (evita rolagem para o próximo mês).
    final thisMonthClosing =
        _closingDateForMonth(now.year, now.month, closingDay);

    final DateTime cycleStart;
    final DateTime cycleEnd;

    // Se hoje ainda não passou o dia de fechamento deste mês,
    // o ciclo atual vai do fechamento do mês passado até o fechamento deste mês.
    if (!now.isAfter(thisMonthClosing)) {
      // Ex: hoje = dia 5, fechamento = dia 10
      // Ciclo: 11/mês-passado → 10/mês-atual
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final previousClosing = _closingDateForMonth(
        previousMonth.year,
        previousMonth.month,
        closingDay,
      );
      cycleStart = previousClosing.add(const Duration(days: 1));
      cycleEnd = thisMonthClosing;
    } else {
      // Ex: hoje = dia 15, fechamento = dia 10
      // Ciclo: 11/mês-atual → 10/mês-próximo
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextClosing = _closingDateForMonth(
        nextMonth.year,
        nextMonth.month,
        closingDay,
      );
      cycleStart = thisMonthClosing.add(const Duration(days: 1));
      cycleEnd = nextClosing;
    }

    return (
      start: _formatDate(cycleStart),
      end: _formatDate(cycleEnd),
    );
  }

  /// Retorna o quanto já foi gasto no cartão NO CICLO ATUAL de faturamento.
  /// Inclui tanto despesas confirmadas quanto pendentes (estão comprometidas).
  Future<int> getCardUsedLimit(int cardId) async {
    // Busca o cartão para saber o dia de fechamento
    final db = await database;
    final cardMaps = await db.query('credit_cards',
        where: 'id = ?', whereArgs: [cardId], limit: 1);
    if (cardMaps.isEmpty) return 0;

    final card = CreditCards.fromMap(cardMaps.first);
    final cycle = _currentBillingCycle(card.closingDay);

    if (kDebugMode) {
      debugPrint('Ciclo do cartão ${card.name}: ${cycle.start} → ${cycle.end}');
    }

    final result = await db.rawQuery('''
      SELECT SUM(amount_cents) as total FROM transactions
      WHERE type = 'expense'
        AND credit_cards_id = ?
        AND status IN ('confirmed', 'pending')
        AND purchase_date >= ?
        AND purchase_date <= ?
    ''', [cardId, cycle.start, cycle.end]);

    return result.first['total'] as int? ?? 0;
  }

  /// Versão que permite consultar por um mês específico (usado em relatórios)
  Future<int> getCardUsedLimitForMonth(int cardId, String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount_cents) as total FROM transactions
      WHERE type = 'expense'
        AND credit_cards_id = ?
        AND status IN ('confirmed', 'pending')
        AND purchase_date LIKE ?
    ''', [cardId, '$month%']);
    return result.first['total'] as int? ?? 0;
  }

  // ─── BALANCE ───────────────────────────────────────────────────────────────

  Future<int> getTotalExpensesForMonth(
    String month, {
    bool neutralizeGoalTransactions = false,
    int? preservedGoalId,
  }) async {
    final db = await database;
    final goalClause = neutralizeGoalTransactions
        ? preservedGoalId == null
            ? ' AND goal_id IS NULL'
            : ' AND (goal_id IS NULL OR goal_id = ?)'
        : '';
    final args = [
      '$month%',
      if (neutralizeGoalTransactions && preservedGoalId != null)
        preservedGoalId,
    ];
    final result = await db.rawQuery('''
      SELECT SUM(amount_cents) as total FROM transactions
      WHERE type = 'expense'
        AND status = 'confirmed'
        AND effective_date LIKE ?$goalClause
    ''', args);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalPendingExpensesForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount_cents) as total FROM transactions
      WHERE type = 'expense' AND status = 'pending' AND effective_date LIKE ?
    ''', ['$month%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalIncomeForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount_cents) as total FROM transactions
      WHERE type = 'income' AND status = 'confirmed' AND effective_date LIKE ?
    ''', ['$month%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getBalanceForMonth(String month,
      {bool includeCarryOver = true}) async {
    final income = await getTotalIncomeForMonth(month);
    final expense = await getTotalExpensesForMonth(month);
    final carryOver = includeCarryOver ? await getCarryOverForMonth(month) : 0;
    return carryOver + income - expense;
  }

  // MELHORIA DE PERFORMANCE:
  // O getCarryOverForMonth original recalculava tudo do zero em loop.
  // Agora fazemos uma única query SQL agregada para somar todos os meses
  // anteriores de uma vez, em vez de chamar o banco N vezes.
  Future<int> getCarryOverForMonth(String month) async {
    final db = await database;

    // Busca todos os meses que têm transações ANTES do mês alvo
    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', effective_date) as month,
        SUM(CASE WHEN type = 'income' AND status = 'confirmed' THEN amount_cents ELSE 0 END) as income,
        SUM(CASE WHEN type = 'expense' AND status = 'confirmed' THEN amount_cents ELSE 0 END) as expense
      FROM transactions
      WHERE strftime('%Y-%m', effective_date) < ?
      GROUP BY strftime('%Y-%m', effective_date)
      ORDER BY month ASC
    ''', [month]);

    // Acumula o saldo positivo mês a mês
    // Regra: saldo negativo não é carregado para o próximo mês
    // (assumimos que dívidas são quitadas)
    int runningBalance = 0;
    for (final row in result) {
      final income = row['income'] as int? ?? 0;
      final expense = row['expense'] as int? ?? 0;
      final monthBalance = runningBalance + income - expense;
      runningBalance = monthBalance > 0 ? monthBalance : 0;
    }

    return runningBalance;
  }

  Future<DateTime?> getFirstTransactionMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT purchase_date FROM transactions
      ORDER BY purchase_date ASC, id ASC
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    final rawDate = result.first['purchase_date'] as String?;
    if (rawDate == null || rawDate.isEmpty) return null;
    final date = DateTime.parse(rawDate);
    return DateTime(date.year, date.month, 1);
  }

  Future<int> getProjectedBalanceForMonth(String month) async {
    final available = await getBalanceForMonth(month);
    final pending = await getTotalPendingExpensesForMonth(month);
    return available - pending;
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── CATEGORY GOALS ───────────────────────────────────────────────────────

  Future<List<CategoryGoal>> getCategoryGoals() async {
    final db = await database;
    final maps = await db.query(
      'category_goals',
      orderBy: 'id ASC',
    );
    return maps.map(CategoryGoal.fromMap).toList();
  }

  Future<void> upsertCategoryGoal(CategoryGoal goal) async {
    final db = await database;
    await db.insert(
      'category_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategoryGoal(int categoryId) async {
    final db = await database;
    await db.delete(
      'category_goals',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> getCategoryGoalCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM category_goals',
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      try {
        await txn.delete('transactions');
        await txn.delete('credit_cards');
        await txn.delete('category_goals');
        await txn.delete('categories');
        await txn.delete('goals');
        await txn.delete('settings');

        final batch = txn.batch();
        for (final category in buildDefaultCategories()) {
          batch.insert('categories', category.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
        await _ensureDefaultGoal(txn);

        await txn.execute('''
          DELETE FROM sqlite_sequence
          WHERE name IN (
            'transactions',
            'credit_cards',
            'categories',
            'goals',
            'category_goals'
          )
        ''');
      } finally {
        await txn.execute('PRAGMA foreign_keys = ON');
      }
    });
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatMonth(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m';
  }

  DateTime _safeDate(int year, int month, int day) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, lastDayOfMonth);
    return DateTime(year, month, safeDay);
  }

  String _calculateEffectiveDateForCardPurchase({
    required String purchaseDate,
    required int closingDay,
    required int dueDay,
  }) {
    final purchase = DateTime.parse(purchaseDate);
    final closingThisMonth =
        _safeDate(purchase.year, purchase.month, closingDay);
    final closingDate = purchase.isAfter(closingThisMonth)
        ? _safeDate(purchase.year, purchase.month + 1, closingDay)
        : closingThisMonth;
    final dueMonthOffset = dueDay > closingDay ? 0 : 1;
    final dueDate =
        _safeDate(closingDate.year, closingDate.month + dueMonthOffset, dueDay);
    return _formatDate(dueDate);
  }

  Future<Map<String, dynamic>> _mapTransactionForPersistence(
      Transactions transaction) async {
    final db = await database;
    final purchaseDate = transaction.purchaseDate;
    var effectiveDate = transaction.effectiveDate;

    if (transaction.creditCardsId == null) {
      effectiveDate = purchaseDate;
    } else {
      final maps = await db.query(
        'credit_cards',
        where: 'id = ?',
        whereArgs: [transaction.creditCardsId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        final card = CreditCards.fromMap(maps.first);
        effectiveDate = _calculateEffectiveDateForCardPurchase(
          purchaseDate: purchaseDate,
          closingDay: card.closingDay,
          dueDay: card.dueDay,
        );
      }
    }

    return {
      ...transaction.toMap(),
      'purchase_date': purchaseDate,
      'effective_date': effectiveDate,
    };
  }

  String _buildRecurringKey(Map<String, dynamic> map, String date) {
    return [
      map['amount_cents'],
      map['type'],
      map['status'],
      map['description'] ?? '',
      date,
      map['category_id'],
      map['credit_cards_id'] ?? '',
      map['is_invoice_paid'] ?? '',
      map['goal_id'] ?? '',
      map['installment_total'] ?? '',
      map['installment_current'] ?? '',
      map['installment_group_id'] ?? '',
      map['is_recurring'] ?? 0,
      map['recurring_id'] ?? '',
      map['parent_id'] ?? '',
      map['note'] ?? '',
    ].join('|');
  }
}
