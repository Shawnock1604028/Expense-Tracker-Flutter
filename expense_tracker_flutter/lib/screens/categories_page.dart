import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/category.dart';
import '../theme/action_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'category_form_dialog.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = AppDatabase.instance.getCategories();
    });
  }

  Future<void> _openAddCategoryDialog() async {
    final added = await showCategoryFormDialog(context);
    if (added) _reloadCategories();
  }

  Future<void> _editCategory(Category category) async {
    final updated = await showCategoryFormDialog(context, category: category);
    if (updated) _reloadCategories();
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete category',
      message: 'Delete "${category.name}"?',
    );
    if (!confirmed || !mounted) return;

    final deleted = await AppDatabase.instance.deleteCategory(category.id);
    if (!mounted) return;

    if (deleted) {
      _reloadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: category is used by expenses'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: ActionColors.edit,
                        tooltip: 'Edit',
                        onPressed: () => _editCategory(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: ActionColors.delete,
                        tooltip: 'Delete',
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCategoryDialog,
        tooltip: 'Add category',
        backgroundColor: ActionColors.add,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
