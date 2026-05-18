import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/money_entry.dart';
import '../models/monthly_balance.dart';
import '../theme/action_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'money_entry_form_dialog.dart';

class MoneyEntriesPage extends StatefulWidget {
  const MoneyEntriesPage({super.key});

  @override
  State<MoneyEntriesPage> createState() => _MoneyEntriesPageState();
}

class _MoneyEntriesPageState extends State<MoneyEntriesPage> {
  late Future<({MonthlyBalance balance, List<MoneyEntry> entries})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final now = DateTime.now();
    setState(() {
      _dataFuture = _fetchData(now.year, now.month);
    });
  }

  Future<({MonthlyBalance balance, List<MoneyEntry> entries})> _fetchData(
    int year,
    int month,
  ) async {
    final balance = await AppDatabase.instance.getMonthlyBalance(
      forMonth: DateTime(year, month),
    );
    final entries =
        await AppDatabase.instance.getMoneyEntriesForMonth(year, month);
    return (balance: balance, entries: entries);
  }

  Future<void> _openAddDialog() async {
    final added = await showMoneyEntryFormDialog(context);
    if (added) _reload();
  }

  Future<void> _editEntry(MoneyEntry entry) async {
    final updated = await showMoneyEntryFormDialog(context, entry: entry);
    if (updated) _reload();
  }

  Future<void> _deleteEntry(MoneyEntry entry) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete entry',
      message: 'Delete "${entry.title}"?',
    );
    if (!confirmed || !mounted) return;

    await AppDatabase.instance.deleteMoneyEntry(entry.id);
    if (!mounted) return;

    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money entries'),
      ),
      body: FutureBuilder<({MonthlyBalance balance, List<MoneyEntry> entries})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final balance = data.balance;
          final entries = data.entries;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.monthLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Month total'),
                            const Spacer(),
                            Text(
                              '\$${balance.totalBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ActionColors.add,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${entries.length} entries this month',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text('No money entries for this month'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _MoneyEntryTile(
                            entry: entry,
                            onEdit: () => _editEntry(entry),
                            onDelete: () => _deleteEntry(entry),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        tooltip: 'Add money',
        backgroundColor: ActionColors.add,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MoneyEntryTile extends StatelessWidget {
  const _MoneyEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final MoneyEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${entry.date.month}/${entry.date.day}/${entry.date.year}';
    final subtitle = entry.note != null && entry.note!.isNotEmpty
        ? '$dateLabel · ${entry.note}'
        : dateLabel;

    return Card(
      child: ListTile(
        title: Text(entry.title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${entry.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ActionColors.add,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: ActionColors.edit,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: ActionColors.delete,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
