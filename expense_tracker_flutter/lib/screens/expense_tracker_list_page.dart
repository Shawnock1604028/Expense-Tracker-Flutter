import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/expense.dart';

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
    _expensesFuture = AppDatabase.instance.getExpensesWithCategories();
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
          final pendingSyncCount =
              expenses.where((e) => e.needsSync).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total spent',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${expenses.length} expenses',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (pendingSyncCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$pendingSyncCount pending sync',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        onPressed: () {},
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

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.receipt_long,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(expense.title),
        subtitle: Text('$categoryLabel · $dateLabel'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expense.needsSync)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
