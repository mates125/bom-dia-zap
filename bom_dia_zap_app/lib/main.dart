import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'widgets/banner_ad_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se restaurar a sessão travar ou falhar por qualquer motivo, o app
  // ainda assim precisa abrir — o usuário só ficaria deslogado.
  try {
    await authService.loadSession().timeout(const Duration(seconds: 5));
  } catch (_) {
    // segue sem sessão restaurada
  }

  unawaited(AdService.instance.initialize());

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
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD166),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      // Banner fixo embaixo, presente em todas as telas do app (não some ao
      // navegar) — mantido montado uma única vez aqui na raiz.
      builder: (context, child) {
        return Column(
          children: [
            Expanded(child: child!),
            const SafeArea(top: false, child: BannerAdWidget()),
          ],
        );
      },
      home: const HomeScreen(),
    );
  }
}
