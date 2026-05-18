import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/expense.dart';
import 'add_expense_dialog.dart';

class ExpenseTrackerListPage extends StatefulWidget {
  const ExpenseTrackerListPage({super.key});

  @override
  State<ExpenseTrackerListPage> createState() => _ExpenseTrackerListPageState();
}

class _ExpenseTrackerListPageState extends State<ExpenseTrackerListPage> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _reloadExpenses();
  }

  void _reloadExpenses() {
    setState(() {
      _expensesFuture = AppDatabase.instance.getExpensesWithCategories();
    });
  }

  Future<void> _openAddExpenseDialog() async {
    final added = await showAddExpenseDialog(context);
    if (added) {
      _reloadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data ?? [];
          final total = expenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );
          // final pendingSyncCount =
          //     expenses.where((e) => e.needsSync).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Total spent',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                height: 1.0,
                              ),
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false, // Forces flush left/top alignment
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ' Total ${expenses.length} transactions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // if (pendingSyncCount > 0) ...[
                        //   const SizedBox(height: 8),
                        //   Text(
                        //     '$pendingSyncCount pending sync',
                        //     style: theme.textTheme.bodySmall?.copyWith(
                        //       color: theme.colorScheme.tertiary,
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 0),
                        itemBuilder: (context, index) {
                          return _ExpenseListTile(expense: expenses[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseDialog,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${expense.date.month}/${expense.date.day}/${expense.date.year}';
    final categoryLabel = expense.categoryName ?? 'Unknown';
    final title = expense.title;

    return Card(
      // Removes extra default margin around the card to keep it compact
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: ListTile(
        dense: true, // 1. Shrinks font metrics and default tile height
        visualDensity: const VisualDensity(vertical: -2), // 2. Compresses vertical padding further (-4 is max)
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), // 3. Zeroes out extra vertical space
        
        title: Text(
          '$dateLabel · $categoryLabel · $title', // Cleaned up the dot spacing
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
