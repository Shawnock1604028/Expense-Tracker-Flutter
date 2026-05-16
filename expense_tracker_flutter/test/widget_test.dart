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

  testWidgets('Expense list shows seeded data from local database',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('\$272.24'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
  });
}
