import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'format.dart';
import 'screens/login.dart';
import 'screens/home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState()..init(),
      child: const BudgetApp(),
    ),
  );
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가계부',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: incomeColor,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isAuthed ? const HomeScreen() : const LoginScreen();
  }
}
