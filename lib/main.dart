import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trip_expense_tracker/firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TripExpenseTrackerApp());
}

class TripExpenseTrackerApp extends StatelessWidget {
  const TripExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tally',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF00A8CF),
          onPrimary: Colors.white,
          secondary: Color(0xFFFBF2E9),
          onSecondary: Color(0xFF1E1E1E),
          background: Color(0xFFFBF2E9),
          onBackground: Color(0xFF1E1E1E),
          surface: Colors.white,
          onSurface: Color(0xFF1E1E1E),
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF2E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Poppins',
              bodyColor: const Color(0xFF1E1E1E),
              displayColor: const Color(0xFF1E1E1E),
            ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}