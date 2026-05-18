class MonthlyBalance {
  const MonthlyBalance({
    required this.year,
    required this.month,
    required this.totalBalance,
    required this.totalExpenses,
  });

  final int year;
  final int month;
  final double totalBalance;
  final double totalExpenses;

  double get remainingBalance => totalBalance - totalExpenses;

  String get monthLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month - 1]} $year';
  }
}
