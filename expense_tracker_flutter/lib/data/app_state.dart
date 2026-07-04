import 'package:flutter/foundation.dart';
import 'app_database.dart';

class Currency {
  final String name;
  final String symbol;
  final String code;

  const Currency({required this.name, required this.symbol, required this.code});

  static Currency fromCode(String code) {
    return AppState.availableCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => AppState.availableCurrencies[0],
    );
  }
}

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  static const List<Currency> availableCurrencies = [
    Currency(name: 'United States Dollar', symbol: '\$', code: 'USD'),
    Currency(name: 'Bangladeshi Taka', symbol: '৳', code: 'BDT'),
    Currency(name: 'Indian Rupee', symbol: '₹', code: 'INR'),
    Currency(name: 'Euro', symbol: '€', code: 'EUR'),
    Currency(name: 'British Pound', symbol: '£', code: 'GBP'),
  ];

  final ValueNotifier<DateTime> selectedDate = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );

  final ValueNotifier<Currency> selectedCurrency = ValueNotifier(availableCurrencies[0]);

  Future<void> loadSettings() async {
    final currencyCode = await AppDatabase.instance.getSetting('currency_code');
    if (currencyCode != null) {
      selectedCurrency.value = Currency.fromCode(currencyCode);
    }
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month);
  }

  Future<void> setSelectedCurrency(Currency currency) async {
    selectedCurrency.value = currency;
    await AppDatabase.instance.saveSetting('currency_code', currency.code);
  }
}
