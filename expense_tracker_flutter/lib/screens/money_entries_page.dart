import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/app_state.dart';
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
    AppState.instance.selectedDate.addListener(_reload);
  }

  @override
  void dispose() {
    AppState.instance.selectedDate.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    final selectedDate = AppState.instance.selectedDate.value;
    setState(() {
      _dataFuture = _fetchData(selectedDate.year, selectedDate.month);
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
    final selectedDate = AppState.instance.selectedDate.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money entries'),
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

          return ValueListenableBuilder<Currency>(
            valueListenable: AppState.instance.selectedCurrency,
            builder: (context, currency, _) {
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
                                  '${currency.symbol}${balance.totalBalance.toStringAsFixed(2)}',
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
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 0,
                              bottom: 80,
                            ),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return _MoneyEntryTile(
                                entry: entry,
                                currencySymbol: currency.symbol,
                                onEdit: () => _editEntry(entry),
                                onDelete: () => _deleteEntry(entry),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
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
    required this.currencySymbol,
    required this.onEdit,
    required this.onDelete,
  });

  final MoneyEntry entry;
  final String currencySymbol;
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
              '$currencySymbol${entry.amount.toStringAsFixed(2)}',
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
