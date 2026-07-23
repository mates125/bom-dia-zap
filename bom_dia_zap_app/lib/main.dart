import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BomDiaZapApp());
}

class BomDiaZapApp extends StatelessWidget {
  const BomDiaZapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bom Dia Zap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD166),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
