import '../models/category.dart';
import '../models/expense.dart';
import '../models/money_entry.dart';

/// Initial local data seeded on first database open.
abstract final class SeedData {
  static final _seededAt = DateTime(2026, 5, 17, 12, 0);

  static final categories = [
    Category(
      id: 'cat_food',
      name: 'Food',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Category(
      id: 'cat_transport',
      name: 'Transport',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Category(
      id: 'cat_entertainment',
      name: 'Entertainment',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Category(
      id: 'cat_utilities',
      name: 'Utilities',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
  ];

  static final expenses = [
    Expense(
      id: 'exp_1',
      title: 'Groceries',
      amount: 84.50,
      date: DateTime(2026, 5, 15),
      categoryId: 'cat_food',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Expense(
      id: 'exp_2',
      title: 'Gas',
      amount: 45.00,
      date: DateTime(2026, 5, 14),
      categoryId: 'cat_transport',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Expense(
      id: 'exp_3',
      title: 'Netflix',
      amount: 15.99,
      date: DateTime(2026, 5, 12),
      categoryId: 'cat_entertainment',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Expense(
      id: 'exp_4',
      title: 'Electric bill',
      amount: 120.00,
      date: DateTime(2026, 5, 10),
      categoryId: 'cat_utilities',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    Expense(
      id: 'exp_5',
      title: 'Coffee shop',
      amount: 6.75,
      date: DateTime(2026, 5, 17),
      categoryId: 'cat_food',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
  ];

  static final moneyEntries = [
    MoneyEntry(
      id: 'money_1',
      title: 'Salary',
      amount: 3500.00,
      date: DateTime(2026, 5, 1),
      note: 'Monthly paycheck',
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
    MoneyEntry(
      id: 'money_2',
      title: 'Freelance',
      amount: 500.00,
      date: DateTime(2026, 5, 10),
      createdAt: _seededAt,
      updatedAt: _seededAt,
    ),
  ];
}
