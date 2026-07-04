import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../models/money_entry.dart';
import '../models/monthly_balance.dart';
import 'database_constants.dart';
import 'seed_data.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbVersion = 2;

  Database? _db;
  bool _isOpening = false;

  Future<Database> get database async {
    if (_db != null) return _db!;

    if (_isOpening) {
      // If already opening, wait for it to finish
      while (_isOpening) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _db!;
    }

    _isOpening = true;
    try {
      _db = await _open();
    } finally {
      _isOpening = false;
    }
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'expense_tracker.db');
    
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
        await _seedIfEmpty(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Run all creations with IF NOT EXISTS to be safe
        await _createAllTables(db);
      },
      onOpen: (db) async {
        // Final safety check
        try {
          await _createAllTables(db);
          await _seedIfEmpty(db);
        } catch (e) {
          //debugPrint('Error during database onOpen: $e');
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await _createCategoriesTable(db);
    await _createExpensesTable(db);
    await _createMoneyEntriesTable(db);
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.categories} (
        ${SyncColumns.id} TEXT PRIMARY KEY,
        ${CategoryColumns.name} TEXT NOT NULL,
        ${SyncColumns.createdAt} INTEGER NOT NULL,
        ${SyncColumns.updatedAt} INTEGER NOT NULL,
        ${SyncColumns.lastSynced} INTEGER
      )
    ''');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.expenses} (
        ${SyncColumns.id} TEXT PRIMARY KEY,
        ${ExpenseColumns.title} TEXT NOT NULL,
        ${ExpenseColumns.amount} REAL NOT NULL,
        ${ExpenseColumns.date} INTEGER NOT NULL,
        ${ExpenseColumns.categoryId} TEXT NOT NULL,
        ${SyncColumns.createdAt} INTEGER NOT NULL,
        ${SyncColumns.updatedAt} INTEGER NOT NULL,
        ${SyncColumns.lastSynced} INTEGER,
        FOREIGN KEY (${ExpenseColumns.categoryId})
          REFERENCES ${TableNames.categories} (${SyncColumns.id})
      )
    ''');
  }

  Future<void> _createMoneyEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.moneyEntries} (
        ${SyncColumns.id} TEXT PRIMARY KEY,
        ${MoneyEntryColumns.title} TEXT NOT NULL,
        ${MoneyEntryColumns.amount} REAL NOT NULL,
        ${MoneyEntryColumns.date} INTEGER NOT NULL,
        ${MoneyEntryColumns.note} TEXT,
        ${SyncColumns.createdAt} INTEGER NOT NULL,
        ${SyncColumns.updatedAt} INTEGER NOT NULL,
        ${SyncColumns.lastSynced} INTEGER
      )
    ''');
  }

  static (int startMs, int endMs) _monthRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  Future<double> _sumAmountInMonth(
    Database db,
    String table,
    String amountColumn,
    String dateColumn,
    int year,
    int month,
  ) async {
    final (startMs, endMs) = _monthRange(year, month);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM($amountColumn), 0) AS total '
      'FROM $table WHERE $dateColumn >= ? AND $dateColumn < ?',
      [startMs, endMs],
    );
    return (result.first['total']! as num).toDouble();
  }

  Future<void> _seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.categories}'),
    );
    if (count != null && count > 0) return;

    final batch = db.batch();
    for (final category in SeedData.categories) {
      batch.insert(TableNames.categories, category.toMap());
    }
    for (final expense in SeedData.expenses) {
      batch.insert(TableNames.expenses, expense.toMap());
    }
    for (final entry in SeedData.moneyEntries) {
      batch.insert(TableNames.moneyEntries, entry.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<MonthlyBalance> getMonthlyBalance({DateTime? forMonth}) async {
    final target = forMonth ?? DateTime.now();
    final db = await database;

    final totalBalance = await _sumAmountInMonth(
      db,
      TableNames.moneyEntries,
      MoneyEntryColumns.amount,
      MoneyEntryColumns.date,
      target.year,
      target.month,
    );

    final totalExpenses = await _sumAmountInMonth(
      db,
      TableNames.expenses,
      ExpenseColumns.amount,
      ExpenseColumns.date,
      target.year,
      target.month,
    );

    return MonthlyBalance(
      year: target.year,
      month: target.month,
      totalBalance: totalBalance,
      totalExpenses: totalExpenses,
    );
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query(
      TableNames.categories,
      orderBy: '${CategoryColumns.name} ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(TableNames.categories, category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      TableNames.categories,
      category.toMap(),
      where: '${SyncColumns.id} = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> countExpensesForCategory(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${TableNames.expenses} '
      'WHERE ${ExpenseColumns.categoryId} = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> deleteCategory(String id) async {
    final inUse = await countExpensesForCategory(id);
    if (inUse > 0) return false;

    final db = await database;
    await db.delete(
      TableNames.categories,
      where: '${SyncColumns.id} = ?',
      whereArgs: [id],
    );
    return true;
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(TableNames.expenses, expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      TableNames.expenses,
      expense.toMap(),
      where: '${SyncColumns.id} = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      TableNames.expenses,
      where: '${SyncColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getExpensesWithCategories() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        e.*,
        c.${CategoryColumns.name} AS category_name
      FROM ${TableNames.expenses} e
      INNER JOIN ${TableNames.categories} c
        ON e.${ExpenseColumns.categoryId} = c.${SyncColumns.id}
      ORDER BY e.${ExpenseColumns.date} DESC
    ''');
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<List<MoneyEntry>> getMoneyEntries() async {
    final db = await database;
    final rows = await db.query(
      TableNames.moneyEntries,
      orderBy: '${MoneyEntryColumns.date} DESC',
    );
    return rows.map(MoneyEntry.fromMap).toList();
  }

  Future<List<MoneyEntry>> getMoneyEntriesForMonth(int year, int month) async {
    final db = await database;
    final (startMs, endMs) = _monthRange(year, month);
    final rows = await db.query(
      TableNames.moneyEntries,
      where: '${MoneyEntryColumns.date} >= ? AND ${MoneyEntryColumns.date} < ?',
      whereArgs: [startMs, endMs],
      orderBy: '${MoneyEntryColumns.date} DESC',
    );
    return rows.map(MoneyEntry.fromMap).toList();
  }

  Future<void> insertMoneyEntry(MoneyEntry entry) async {
    final db = await database;
    await db.insert(TableNames.moneyEntries, entry.toMap());
  }

  Future<void> updateMoneyEntry(MoneyEntry entry) async {
    final db = await database;
    await db.update(
      TableNames.moneyEntries,
      entry.toMap(),
      where: '${SyncColumns.id} = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteMoneyEntry(String id) async {
    final db = await database;
    await db.delete(
      TableNames.moneyEntries,
      where: '${SyncColumns.id} = ?',
      whereArgs: [id],
    );
  }

  /// Opens an in-memory database for tests.
  Future<void> openForTesting() async {
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
        await _seedIfEmpty(db);
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
