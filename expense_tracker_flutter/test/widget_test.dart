import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_flutter/data/app_database.dart';
import 'package:expense_tracker_flutter/data/database_bootstrap.dart';
import 'package:expense_tracker_flutter/main.dart';

void main() {
  setUpAll(configureDatabaseFactory);

  setUp(() async {
    await AppDatabase.instance.close();
    await AppDatabase.instance.openForTesting();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('Home shows balance and navigates to expenses',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Shawnock'), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('\$4000.00'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
