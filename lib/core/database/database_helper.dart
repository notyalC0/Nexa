import 'package:nexa/core/models/categories.dart';
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
      version: 1,
      onCreate: _createTables,
    );
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
  }

//#region Categories queries
  Future<List<Categories>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Categories.fromMap(maps[i]));
  }

  Future<int> insertCategory(Categories categories) async {
    final db = await database;
    return db.insert('categories', categories.toMap());
  }
  //#endregion



//#region Transactions queries
  Future<List<Transactions>> getTransactionsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: ['$month%'],
    );
    return List.generate(maps.length, (i) => Transactions.fromMap(maps[i]));
  }

  Future<int> insertTransaction(Transactions transactions) async {
    final db = await database;
    return db.insert('transactions', transactions.toMap());
  }
  //#endregion
}
