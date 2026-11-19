import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datos_app.dart';
import 'data/foto_perfil_local.dart';
import 'firebase_options.dart';
import 'screens/ajustes_screen.dart';
import 'screens/amigos_screen.dart';
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
import 'theme/app_themes.dart';
import 'theme/tema_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FotoPerfilLocal.recuperarSeleccionPendiente();
  runApp(await MyApp.cargar());
}

class MyApp extends StatelessWidget {
  const MyApp({required this.modoOscuroInicial, this.datos, super.key});
  final bool modoOscuroInicial;
  final DatosApp? datos;

  static Future<MyApp> cargar() async =>
      MyApp(modoOscuroInicial: await TemaProvider.leerModoOscuro());

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TemaProvider(modoOscuroInicial: modoOscuroInicial),
      ),
      ChangeNotifierProvider(create: (_) => datos ?? (DatosApp()..iniciar())),
    ],
    child: const _Aplicacion(),
  );
}

class _Aplicacion extends StatelessWidget {
  const _Aplicacion();

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    return MaterialApp(
      key: ValueKey(datos.usuario?.uid),
      title: 'pokemonchafa',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: context.watch<TemaProvider>().modoOscuro
          ? ThemeMode.dark
          : ThemeMode.light,
      home: datos.usuario == null
          ? const InicioSesionScreen()
          : const _ConDatos(child: MainNavigation()),
      routes: {
        '/inicio': (_) => const InicioSesionScreen(),
        '/permisos': (_) =>
            const _ConDatos(child: IntroduccionPermisosScreen()),
        '/mapa': (_) => const _ConDatos(child: MainNavigation()),
        '/perfil': (_) => const _ConDatos(child: PerfilScreen()),
        '/amigos': (_) => const _ConDatos(child: AmigosScreen()),
        '/ajustes': (_) => const _ConDatos(child: AjustesScreen()),
        '/guia': (_) => const _ConDatos(child: EncyclopediaScreen()),
        '/coleccion': (_) => const _ConDatos(child: CollectionScreen()),
        '/creaciones': (_) => const _ConDatos(child: MisCreacionesScreen()),
        '/encuentro': (_) => const _ConDatos(child: EncuentroCapturaScreen()),
        '/resultado': (_) => const _ConDatos(child: ResultadoCapturaScreen()),
        '/editor': (_) => const _ConDatos(child: EditorDibujoScreen()),
        '/intercambio': (_) => const _ConDatos(child: CompartirRecibirScreen()),
      },
    );
  }
}

class _ConDatos extends StatelessWidget {
  const _ConDatos({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    if (datos.usuario == null) return const InicioSesionScreen();
    if (datos.cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (datos.error != null && datos.catalogo.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(datos.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => datos.abrirSesion(datos.usuario),
                  child: const Text('Reintentar'),
                ),
                TextButton(
                  onPressed: datos.cerrarSesion,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
