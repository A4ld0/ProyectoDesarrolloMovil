import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../theme/tema_provider.dart';
import '../widgets/recarga_firebase.dart';
import 'introduccion_permisos_screen.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});
  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _ocupado = false;

  Future<void> _cambiarSonidos(bool valor) async {
    setState(() => _ocupado = true);
    try {
      await context.read<DatosApp>().cambiarSonidos(valor);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el ajuste.')),
        );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final datos = context.read<DatosApp>();
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Volverás a la pantalla de inicio de sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (salir != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await datos.cerrarSesion();
    } catch (_) {
      if (mounted) {
        setState(() => _ocupado = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión. Inténtalo de nuevo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    final datos = context.watch<DatosApp>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: RecargaFirebase(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Modo oscuro'),
                        value: tema.modoOscuro,
                        onChanged: (valor) async {
                          final guardado = await tema.cambiarModoOscuro(valor);
                          if (!context.mounted || guardado) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo guardar el tema.'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: const Text('Sonidos de captura'),
                        value: datos.perfil['sonidos'] == true,
                        onChanged: _ocupado ? null : _cambiarSonidos,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.security_outlined),
                        title: const Text('Permisos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IntroduccionPermisosScreen(
                              desdeAjustes: true,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Acerca de'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'pokemonchafa',
                          children: [
                            const Text(
                              'Explora el mapa, captura criaturas, dibuja las tuyas y compártelas por NFC.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _ocupado ? null : _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
