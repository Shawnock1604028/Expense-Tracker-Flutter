import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../models/category.dart';
import '../models/expense.dart';

Future<bool> showAddExpenseDialog(BuildContext context) =>
    showExpenseFormDialog(context);

Future<bool> showExpenseFormDialog(
  BuildContext context, {
  Expense? expense,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _ExpenseFormDialog(expense: expense),
  );
  return result ?? false;
}

class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog({this.expense});

  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  List<Category> _categories = [];
  Category? _selectedCategory;
  late DateTime _selectedDate;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense != null ? expense.amount.toStringAsFixed(2) : '',
    );
    _selectedDate = expense?.date ?? DateTime.now();
    _loadCategories(expense?.categoryId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories(String? categoryId) async {
    final categories = await AppDatabase.instance.getCategories();
    if (!mounted) return;

    Category? selected;
    if (categoryId != null) {
      for (final category in categories) {
        if (category.id == categoryId) {
          selected = category;
          break;
        }
      }
    }

    setState(() {
      _categories = categories;
      _selectedCategory = selected ??
          (categories.isNotEmpty ? categories.first : null);
      _loadingCategories = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    final now = DateTime.now();
    final amount = double.parse(_amountController.text.trim());

    if (widget.isEditing) {
      final updated = widget.expense!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategory!.id,
        updatedAt: now,
      );
      await AppDatabase.instance.updateExpense(updated);
    } else {
      final expense = Expense(
        id: 'exp_${now.millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategory!.id,
        createdAt: now,
        updatedAt: now,
      );
      await AppDatabase.instance.insertExpense(expense);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit expense' : 'New expense'),
      content: _loadingCategories
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : _categories.isEmpty
              ? const Text('No categories available. Add a category first.')
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(_formatDate(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) =>
                              value == null ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter an amount';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loadingCategories || _categories.isEmpty ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
