import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';
import 'database_constants.dart';
import 'seed_data.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'expense_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${TableNames.categories} (
            ${SyncColumns.id} TEXT PRIMARY KEY,
            ${CategoryColumns.name} TEXT NOT NULL,
            ${SyncColumns.createdAt} INTEGER NOT NULL,
            ${SyncColumns.updatedAt} INTEGER NOT NULL,
            ${SyncColumns.lastSynced} INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE ${TableNames.expenses} (
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

        await _seedIfEmpty(db);
      },
      onOpen: (db) async {
        await _seedIfEmpty(db);
      },
    );
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
    await batch.commit(noResult: true);
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

  /// Opens an in-memory database for tests.
  Future<void> openForTesting() async {
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${TableNames.categories} (
            ${SyncColumns.id} TEXT PRIMARY KEY,
            ${CategoryColumns.name} TEXT NOT NULL,
            ${SyncColumns.createdAt} INTEGER NOT NULL,
            ${SyncColumns.updatedAt} INTEGER NOT NULL,
            ${SyncColumns.lastSynced} INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE ${TableNames.expenses} (
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
        await _seedIfEmpty(db);
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
