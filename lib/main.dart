import 'package:flutter/material.dart';
import 'ui/splash.dart';
import 'ui/style/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LivroReceitasApp());
}

class LivroReceitasApp extends StatefulWidget {
  const LivroReceitasApp({super.key});

  @override
  State<LivroReceitasApp> createState() => _LivroReceitasAppState();
}

class _LivroReceitasAppState extends State<LivroReceitasApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receitas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: SplashScreen(onToggleTheme: _toggleTheme),
    );
  }
}
