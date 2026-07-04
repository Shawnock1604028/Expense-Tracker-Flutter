/// Shared column names for syncable tables.
abstract final class SyncColumns {
  static const id = 'id';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const lastSynced = 'last_synced';
}

abstract final class TableNames {
  static const categories = 'categories';
  static const expenses = 'expenses';
  static const moneyEntries = 'money_entries';
  static const settings = 'settings';
}

abstract final class CategoryColumns {
  static const name = 'name';
}

abstract final class ExpenseColumns {
  static const title = 'title';
  static const amount = 'amount';
  static const date = 'date';
  static const categoryId = 'category_id';
}

abstract final class MoneyEntryColumns {
  static const title = 'title';
  static const amount = 'amount';
  static const date = 'date';
  static const note = 'note';
}

abstract final class SettingColumns {
  static const key = 'key';
  static const value = 'value';
}
