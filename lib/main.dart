import 'package:flutter/material.dart';
// firebase_core: paquete base para conectar la app con Firebase
import 'package:firebase_core/firebase_core.dart';
// firebase_auth: lo usamos para saber si ya hay sesión iniciada
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'data/criaturas_nfc.dart';
import 'data/foto_perfil_local.dart';
import 'theme/tema_provider.dart';
import 'theme/app_themes.dart';
import 'screens/ajustes_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/compartir_recibir_screen.dart';
import 'screens/editor_dibujo_screen.dart';
import 'screens/encuentro_captura_screen.dart';
import 'screens/encyclopedia_screen.dart';
import 'screens/inicio_sesion_screen.dart';
import 'screens/introduccion_permisos_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/mis_creaciones_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/resultado_captura_screen.dart';

// main es async porque esperamos a que Firebase arranque
void main() async {
  // Aseguramos que Flutter esté listo antes de llamar código nativo (Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  // Mandamos a llamar Firebase con la configuración de firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FotoPerfilLocal.recuperarSeleccionPendiente();
  runApp(await MyApp.cargar());
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.modoOscuroInicial,
    this.criaturasNfcIniciales = const {},
    super.key,
  });

  final bool modoOscuroInicial;
  final Map<String, EstadoCriaturaNfc> criaturasNfcIniciales;

  static Future<MyApp> cargar() async => MyApp(
    modoOscuroInicial: await TemaProvider.leerModoOscuro(),
    criaturasNfcIniciales: await CriaturasNfc.leer(),
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TemaProvider(modoOscuroInicial: modoOscuroInicial),
      ),
      ChangeNotifierProvider(
        create: (_) => CriaturasNfc(criaturasNfcIniciales),
      ),
    ],
    child: const _Aplicacion(),
  );
}

class _Aplicacion extends StatelessWidget {
  const _Aplicacion();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'pokemonchafa',
    debugShowCheckedModeBanner: false,
    theme: AppThemes.light,
    darkTheme: AppThemes.dark,
    themeMode: context.watch<TemaProvider>().modoOscuro
        ? ThemeMode.dark
        : ThemeMode.light,
    // Si Firebase ya recuerda una sesión vamos directo al mapa,
    // si no, mostramos el inicio de sesión
    home: FirebaseAuth.instance.currentUser == null
        ? const InicioSesionScreen()
        : const MainNavigation(),
    routes: {
      '/inicio': (_) => const InicioSesionScreen(),
      '/permisos': (_) => const IntroduccionPermisosScreen(),
      '/mapa': (_) => const MainNavigation(),
      '/perfil': (_) => const PerfilScreen(),
      '/ajustes': (_) => const AjustesScreen(),
      '/guia': (_) => const EncyclopediaScreen(),
      '/coleccion': (_) => const CollectionScreen(),
      '/creaciones': (_) => const MisCreacionesScreen(),
      '/encuentro': (_) => const EncuentroCapturaScreen(),
      '/resultado': (_) => const ResultadoCapturaScreen(),
      '/editor': (_) => const EditorDibujoScreen(),
      '/intercambio': (_) => const CompartirRecibirScreen(),
    },
  );
}
