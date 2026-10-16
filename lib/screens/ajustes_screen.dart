import 'package:flutter/material.dart';

import '../theme/app_theme_scope.dart';
import 'introduccion_permisos_screen.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  // El audio sigue siendo una simulación local.
  bool _sonidos = false;

  void _mostrarPendiente(String mensaje) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Funcionalidad pendiente'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarAcercaDe() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Acerca de pokemonchafa'),
        content: const Text(
          'Versión 1.0.0\n\n'
          'Explora el mapa, descubre criaturas, crea las tuyas y compártelas.\n\n'
          'Prototipo de interfaz: las funciones reales están pendientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Volverás a la pantalla de inicio de sesión.\n\n'
          'El cierre de sesión real está pendiente. '
          'Por ahora, solo saldrás de la demostración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir de la demo'),
          ),
        ],
      ),
    );

    if (salir == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/inicio', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = AppThemeScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Personaliza tu experiencia',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El tema se mantiene mientras la app está abierta. '
                'Los demás ajustes son de prueba.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: colors.surface,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.dark_mode_outlined,
                        color: colors.primary,
                      ),
                      title: const Text('Modo oscuro'),
                      subtitle: Text(
                        tema.modoOscuro ? 'Activado' : 'Desactivado',
                      ),
                      value: tema.modoOscuro,
                      onChanged: tema.cambiarModoOscuro,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.volume_up_outlined,
                        color: colors.primary,
                      ),
                      title: const Text('Sonidos'),
                      subtitle: Text(
                        _sonidos
                            ? 'Activados · Simulado'
                            : 'Desactivados · Simulado',
                      ),
                      value: _sonidos,
                      onChanged: (valor) {
                        setState(() => _sonidos = valor);
                        _mostrarPendiente(
                          'Aquí se activarán o silenciarán los sonidos de '
                          'encuentros y capturas.\n\n'
                          'Funcionalidad pendiente: todavía no se reproduce audio.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colors.surface,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.security_outlined,
                        color: colors.primary,
                      ),
                      title: const Text('Permisos'),
                      subtitle: const Text('Ubicación y cámara · Simulados'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push<void>(
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
                      leading: Icon(Icons.info_outline, color: colors.primary),
                      title: const Text('Acerca de'),
                      subtitle: const Text('Conoce la aplicación'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _mostrarAcercaDe,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
