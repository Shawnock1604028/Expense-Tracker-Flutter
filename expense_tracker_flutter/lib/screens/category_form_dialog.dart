import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/category.dart';

Future<bool> showCategoryFormDialog(
  BuildContext context, {
  Category? category,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _CategoryFormDialog(category: category),
  );
  return result ?? false;
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final Category? category;

  bool get isEditing => category != null;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final name = _nameController.text.trim();

    if (widget.isEditing) {
      final updated = widget.category!.copyWith(
        name: name,
        updatedAt: now,
      );
      await AppDatabase.instance.updateCategory(updated);
    } else {
      final category = Category(
        id: 'cat_${now.millisecondsSinceEpoch}',
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      await AppDatabase.instance.insertCategory(category);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit category' : 'New category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a category name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
