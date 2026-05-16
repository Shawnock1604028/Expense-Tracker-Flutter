import 'syncable_entity.dart';

class Category extends SyncableEntity {
  const Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.lastSynced,
  });

  @override
  final String id;

  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? lastSynced;

  Category copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSynced,
    bool clearLastSynced = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'last_synced': lastSynced?.millisecondsSinceEpoch,
      };

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id']! as String,
      name: map['name']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      lastSynced: map['last_synced'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_synced']! as int),
    );
  }
}
