import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import 'categories_page.dart';
import 'expense_tracker_list_page.dart';

class _HomeSummary {
  const _HomeSummary({
    required this.expenses,
    required this.categories,
  });

  final List<Expense> expenses;
  final List<Category> categories;

  double get totalSpent =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);
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
  }

  void _loadSummary() {
    setState(() {
      _summaryFuture = _fetchSummary();
    });
  }

  Future<_HomeSummary> _fetchSummary() async {
    final results = await Future.wait([
      AppDatabase.instance.getExpensesWithCategories(),
      AppDatabase.instance.getCategories(),
    ]);
    return _HomeSummary(
      expenses: results[0] as List<Expense>,
      categories: results[1] as List<Category>,
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
            final initials = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

            return RefreshIndicator(
              onRefresh: () async => _loadSummary(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileSection(
                    name: _userName,
                    initials: initials,
                    totalSpent: summary.totalSpent,
                    transactionCount: summary.expenses.length,
                    categoryCount: summary.categories.length,
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
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
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.name,
    required this.initials,
    required this.totalSpent,
    required this.transactionCount,
    required this.categoryCount,
  });

  final String name;
  final String initials;
  final double totalSpent;
  final int transactionCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.profileCardAsh(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.profileCardAshBorder(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initials,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
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
                  'Total expense',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '\$${totalSpent.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$transactionCount transactions · $categoryCount categories',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
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
