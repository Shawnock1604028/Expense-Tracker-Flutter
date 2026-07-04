import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/app_state.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/monthly_balance.dart';
import '../theme/app_colors.dart';
import 'categories_page.dart';
import 'expense_tracker_list_page.dart';
import 'money_entries_page.dart';
import 'settings_page.dart';

class _HomeSummary {
  const _HomeSummary({
    required this.expenses,
    required this.categories,
    required this.monthlyBalance,
  });

  final List<Expense> expenses;
  final List<Category> categories;
  final MonthlyBalance monthlyBalance;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _userName = 'Shawnock Guha Paul';

  late Future<_HomeSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    AppState.instance.selectedDate.addListener(_loadSummary);
  }

  @override
  void dispose() {
    AppState.instance.selectedDate.removeListener(_loadSummary);
    super.dispose();
  }

  void _loadSummary() {
    setState(() {
      _summaryFuture = _fetchSummary();
    });
  }

  Future<_HomeSummary> _fetchSummary() async {
    final selectedDate = AppState.instance.selectedDate.value;
    final results = await Future.wait([
      AppDatabase.instance.getExpensesWithCategories(forMonth: selectedDate),
      AppDatabase.instance.getCategories(),
      AppDatabase.instance.getMonthlyBalance(forMonth: selectedDate),
    ]);
    return _HomeSummary(
      expenses: results[0] as List<Expense>,
      categories: results[1] as List<Category>,
      monthlyBalance: results[2] as MonthlyBalance,
    );
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

  void _openExpenses() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => const ExpenseTrackerListPage(),
          ),
        )
        .then((_) {
      if (mounted) _loadSummary();
    });
  }

  void _openCategories() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => const CategoriesPage(),
          ),
        )
        .then((_) {
      if (mounted) _loadSummary();
    });
  }

  void _openMoneyEntries() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => const MoneyEntriesPage(),
          ),
        )
        .then((_) {
      if (mounted) _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = AppState.instance.selectedDate.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_HomeSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final summary = snapshot.data!;
            final initials =
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

            return RefreshIndicator(
              onRefresh: () async => _loadSummary(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileSection(
                    name: _userName,
                    initials: initials,
                    monthlyBalance: summary.monthlyBalance,
                    transactionCount: summary.expenses.length,
                    categoryCount: summary.categories.length,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick access',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      _MenuCard(
                        title: 'Money',
                        subtitle: 'Income & deposits',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: _openMoneyEntries,
                      ),
                      _MenuCard(
                        title: 'Expenses',
                        subtitle: '${summary.expenses.length} transactions',
                        icon: Icons.receipt_long,
                        onTap: _openExpenses,
                      ),
                      _MenuCard(
                        title: 'Categories',
                        subtitle: '${summary.categories.length} categories',
                        icon: Icons.category_outlined,
                        onTap: _openCategories,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.name,
    required this.initials,
    required this.monthlyBalance,
    required this.transactionCount,
    required this.categoryCount,
  });

  final String name;
  final String initials;
  final MonthlyBalance monthlyBalance;
  final int transactionCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = monthlyBalance.remainingBalance;
    final remainingColor = remaining >= 0
        ? Colors.green.shade700
        : theme.colorScheme.error;

    return Card(
      color: AppColors.profileCardAsh(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.profileCardAshBorder(context)),
      ),
      child: ValueListenableBuilder<Currency>(
        valueListenable: AppState.instance.selectedCurrency,
        builder: (context, currency, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initials,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Total balance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${currency.symbol}${monthlyBalance.totalBalance.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Remaining',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${currency.symbol}${remaining.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: remainingColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Spent ${currency.symbol}${monthlyBalance.totalExpenses.toStringAsFixed(2)} · '
                    '$transactionCount transactions · $categoryCount categories',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
