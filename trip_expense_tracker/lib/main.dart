import 'package:flutter/material.dart';
import 'screens/home_screen.dart';


void main(){
  runApp(const TripExpenseTrackerApp());
}

class TripExpenseTrackerApp extends StatelessWidget {
  const TripExpenseTrackerApp({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tally App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        
      );
  }
}