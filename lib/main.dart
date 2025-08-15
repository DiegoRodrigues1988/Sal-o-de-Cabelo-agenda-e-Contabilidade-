import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_senha.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SalaoDeBelezaApp());
}

class SalaoDeBelezaApp extends StatelessWidget {
  const SalaoDeBelezaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salão de Beleza App',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D1B2A),
        scaffoldBackgroundColor: Colors.black,
        hintColor: const Color(0xFFFFD700),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D1B2A),
          secondary: Color(0xFFFFD700),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          surface: Color(0xFF1B263B),
          onSurface: Color(0xFFE0E1DD),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E1DD)),
          bodyMedium: TextStyle(color: Color(0xFFE0E1DD)),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFFFFD700), fontStyle: FontStyle.italic),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B263B),
          labelStyle: const TextStyle(color: Color(0xFFE0E1DD)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF415A77)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
          ),
        ),
      ),
      // CORREÇÃO: Adicionado 'const' para otimização
      home: const LoginPage(),
    );
  }
}
