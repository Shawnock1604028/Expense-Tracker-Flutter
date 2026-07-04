import 'package:flutter/foundation.dart';

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<DateTime> selectedDate = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month),
  );

  void setSelectedDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month);
  }
}
