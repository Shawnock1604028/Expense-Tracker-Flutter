import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/app_state.dart';
import '../models/expense.dart';
import '../theme/action_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
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
    AppState.instance.selectedDate.addListener(_reloadExpenses);
  }

  @override
  void dispose() {
    AppState.instance.selectedDate.removeListener(_reloadExpenses);
    super.dispose();
  }

  void _reloadExpenses() {
    setState(() {
      _expensesFuture = AppDatabase.instance.getExpensesWithCategories(
        forMonth: AppState.instance.selectedDate.value,
      );
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    DateTime tempDate = AppState.instance.selectedDate.value;
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month & Year'),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => setDialogState(() => tempDate = DateTime(tempDate.year - 1, tempDate.month)),
                        ),
                        Text(
                          '${tempDate.year}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => setDialogState(() => tempDate = DateTime(tempDate.year + 1, tempDate.month)),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = tempDate.month == month;
                          return InkWell(
                            onTap: () => Navigator.pop(context, DateTime(tempDate.year, month)),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthName(month),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      AppState.instance.setSelectedDate(picked);
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _openAddExpenseDialog() async {
    final added = await showAddExpenseDialog(context);
    if (added) _reloadExpenses();
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await showExpenseFormDialog(context, expense: expense);
    if (updated) _reloadExpenses();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete expense',
      message: 'Delete "${expense.title}"?',
    );
    if (!confirmed || !mounted) return;

    await AppDatabase.instance.deleteExpense(expense.id);
    if (!mounted) return;

    _reloadExpenses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = AppState.instance.selectedDate.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: () => _selectMonth(context),
            icon: const Icon(Icons.calendar_month),
            label: Text(
              '${_monthName(selectedDate.month)} ${selectedDate.year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                                applyHeightToFirstAscent: false,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ' Total ${expenses.length} transactions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                          left: 2,
                          right: 2,
                          top: 2,
                          bottom: 100,
                        ),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 0),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _ExpenseListTile(
                            expense: expense,
                            onEdit: () => _editExpense(expense),
                            onDelete: () => _deleteExpense(expense),
                          );
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
        backgroundColor: ActionColors.add,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${expense.date.month}/${expense.date.day}/${expense.date.year}';
    final categoryLabel = expense.categoryName ?? 'Unknown';
    final title = expense.title;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        title: Text(
          '$dateLabel · $categoryLabel · $title',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: ActionColors.edit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: ActionColors.delete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
