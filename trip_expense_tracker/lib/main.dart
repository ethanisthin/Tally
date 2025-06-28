import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TripExpenseTrackerApp());
}

class TripExpenseTrackerApp extends StatelessWidget {
  const TripExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}