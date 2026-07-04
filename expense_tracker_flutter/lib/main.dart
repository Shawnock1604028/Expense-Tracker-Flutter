import 'package:flutter/material.dart';

import 'data/database_bootstrap.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling to catch crashes
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
  };

  try {
    configureDatabaseFactory();
    runApp(const MyApp());
  } catch (e) {
    debugPrint('STARTUP ERROR: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App failed to start: $e')),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
