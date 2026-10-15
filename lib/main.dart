import 'package:flutter/material.dart';

import 'theme/app_colors.dart'; //° colores globales de tu compañero
import 'screens/main_navigation.dart'; //° nuestro nuevo navegador inferior
import 'screens/editor_dibujo_screen.dart';
import 'screens/compartir_recibir_screen.dart';
import 'screens/introduccion_permisos_screen.dart';
import 'screens/encuentro_captura_screen.dart';
import 'screens/resultado_captura_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Criaturas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.navy,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
    ),
    home: const IntroduccionPermisosScreen(),
    routes: {
      '/mapa': (_) => const MainNavigation(),
      '/creaciones': (_) => const MainNavigation(initialIndex: 2),
      '/encuentro': (_) => const EncuentroCapturaScreen(),
      '/resultado': (_) => const ResultadoCapturaScreen(),
      '/editor': (_) => const EditorDibujoScreen(),
      '/intercambio': (_) => const CompartirRecibirScreen(),
    },
  );
}
