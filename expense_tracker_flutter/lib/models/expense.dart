import 'syncable_entity.dart';

class Expense extends SyncableEntity {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.lastSynced,
    this.categoryName,
  });

  @override
  final String id;

  final String title;
  final double amount;
  final DateTime date;

  /// References [Category.id] in the categories table.
  final String categoryId;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? lastSynced;

  /// Populated when joining with categories for display; not stored on expenses.
  final String? categoryName;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSynced,
    String? categoryName,
    bool clearLastSynced = false,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
      categoryName: categoryName ?? this.categoryName,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'category_id': categoryId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'last_synced': lastSynced?.millisecondsSinceEpoch,
      };

  factory Expense.fromMap(Map<String, Object?> map, {String? categoryName}) {
    return Expense(
      id: map['id']! as String,
      title: map['title']! as String,
      amount: (map['amount']! as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      categoryId: map['category_id']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      lastSynced: map['last_synced'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_synced']! as int),
      categoryName: categoryName ?? map['category_name'] as String?,
    );
  }
}
