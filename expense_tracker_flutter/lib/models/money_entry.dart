import 'syncable_entity.dart';

class MoneyEntry extends SyncableEntity {
  MoneyEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.lastSynced,
  });

  @override
  final String id;

  final String title;
  final double amount;
  final DateTime date;
  final String? note;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? lastSynced;

  MoneyEntry copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSynced,
    bool clearNote = false,
    bool clearLastSynced = false,
  }) {
    return MoneyEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'last_synced': lastSynced?.millisecondsSinceEpoch,
      };

  factory MoneyEntry.fromMap(Map<String, Object?> map) {
    return MoneyEntry(
      id: map['id']! as String,
      title: map['title']! as String,
      amount: (map['amount']! as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      lastSynced: map['last_synced'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_synced']! as int),
    );
  }
}
