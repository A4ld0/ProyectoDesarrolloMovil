import 'package:flutter/material.dart';

class InicioSesionScreen extends StatelessWidget {
  const InicioSesionScreen({super.key});

  Future<void> _mostrarAcceso(BuildContext context, String metodo) async {
    FocusScope.of(context).unfocus();
    final continuar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Funcionalidad pendiente'),
        content: Text(
          metodo == 'correo y contraseña'
              ? 'Aquí se verificará tu correo y contraseña para iniciar sesión. '
                    'La autenticación está pendiente.\n\n'
                    'Por ahora, puedes continuar a la demostración. '
                    'No se verifica ni se guarda ninguna credencial.'
              : 'Aquí iniciarás sesión con tu cuenta de $metodo. '
                    'La conexión con $metodo está pendiente.\n\n'
                    'Por ahora, puedes continuar a la demostración '
                    'sin conectar una cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar demo'),
          ),
        ],
      ),
    );

    if (continuar == true && context.mounted) {
      Navigator.pushReplacementNamed(context, '/permisos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'pokemonchafa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para comenzar a explorar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'nombre@ejemplo.com',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      _mostrarAcceso(context, 'correo y contraseña'),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'O continúa con',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _mostrarAcceso(context, 'Google'),
                  icon: const Text(
                    'G',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  label: const Text('Continuar con Google'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _mostrarAcceso(context, 'Apple'),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continuar con Apple'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Demostración · El inicio de sesión aún no está disponible. '
                  'No necesitas introducir datos reales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
