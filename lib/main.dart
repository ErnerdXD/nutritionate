import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth_gate.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const NutriScanApp());
}

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.mode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Nutritionate',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF167D4A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F8F5),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF43A875),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
