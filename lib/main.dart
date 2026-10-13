import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'screens/mis_creaciones_screen.dart';
import 'screens/editor_dibujo_screen.dart';
import 'screens/compartir_recibir_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Criaturas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
    ),
    home: const MisCreacionesScreen(),
    routes: {
      '/editor': (_) => const EditorDibujoScreen(),
      '/intercambio': (_) => const CompartirRecibirScreen(),
    },
  );
}
