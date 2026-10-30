import 'package:flutter/material.dart';
// firebase_core: paquete base para conectar la app con Firebase
import 'package:firebase_core/firebase_core.dart';
// firebase_auth: lo usamos para saber si ya hay sesión iniciada
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'theme/app_theme_scope.dart';
import 'theme/app_themes.dart';
import 'screens/main_navigation.dart'; //° nuestro nuevo navegador inferior
import 'screens/editor_dibujo_screen.dart';
import 'screens/compartir_recibir_screen.dart';
import 'screens/introduccion_permisos_screen.dart';
import 'screens/inicio_sesion_screen.dart';
import 'screens/encuentro_captura_screen.dart';
import 'screens/resultado_captura_screen.dart';

// main es async porque esperamos a que Firebase arranque
void main() async {
  // Aseguramos que Flutter esté listo antes de llamar código nativo (Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  // Mandamos a llamar Firebase con la configuración de firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

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
      // Si Firebase ya recuerda una sesión vamos directo al mapa,
      // si no, mostramos el inicio de sesión
      home: FirebaseAuth.instance.currentUser == null
          ? const InicioSesionScreen()
          : const MainNavigation(),
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
