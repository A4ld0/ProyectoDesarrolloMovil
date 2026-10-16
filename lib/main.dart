import 'package:flutter/material.dart';

import 'theme/app_theme_scope.dart';
import 'theme/app_themes.dart';
import 'screens/main_navigation.dart'; //° nuestro nuevo navegador inferior
import 'screens/editor_dibujo_screen.dart';
import 'screens/compartir_recibir_screen.dart';
import 'screens/introduccion_permisos_screen.dart';
import 'screens/inicio_sesion_screen.dart';
import 'screens/encuentro_captura_screen.dart';
import 'screens/resultado_captura_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _modoOscuro = false;

  void _cambiarModoOscuro(bool valor) {
    setState(() => _modoOscuro = valor);
  }

  @override
  Widget build(BuildContext context) => AppThemeScope(
    modoOscuro: _modoOscuro,
    cambiarModoOscuro: _cambiarModoOscuro,
    child: MaterialApp(
      title: 'pokemonchafa',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: _modoOscuro ? ThemeMode.dark : ThemeMode.light,
      home: const InicioSesionScreen(),
      routes: {
        '/inicio': (_) => const InicioSesionScreen(),
        '/permisos': (_) => const IntroduccionPermisosScreen(),
        '/mapa': (_) => const MainNavigation(),
        '/creaciones': (_) => const MainNavigation(initialIndex: 2),
        '/encuentro': (_) => const EncuentroCapturaScreen(),
        '/resultado': (_) => const ResultadoCapturaScreen(),
        '/editor': (_) => const EditorDibujoScreen(),
        '/intercambio': (_) => const CompartirRecibirScreen(),
      },
    ),
  );
}
