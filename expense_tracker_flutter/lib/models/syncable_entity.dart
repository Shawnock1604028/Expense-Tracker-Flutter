/// Shared sync and audit fields for all locally stored models.
abstract class SyncableEntity {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime? get lastSynced;

  /// True when local changes have not been pushed to remote yet.
  bool get needsSync =>
      lastSynced == null || updatedAt.isAfter(lastSynced!);
}
