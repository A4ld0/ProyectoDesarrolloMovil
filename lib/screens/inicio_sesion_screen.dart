import 'package:flutter/material.dart';
// firebase_auth: lo usamos para iniciar sesión, registrar usuarios y entrar con Google
import 'package:firebase_auth/firebase_auth.dart';

// Pasa a Stateful para poder leer lo que se escribe en los TextField
class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key});

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  // Controladores para leer el correo y la contraseña
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _mostrarAcceso(BuildContext context, String metodo) async {
    FocusScope.of(context).unfocus();
    final continuar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Funcionalidad pendiente'),
        content: Text('El acceso con $metodo está pendiente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (continuar == true && context.mounted) {
      Navigator.pushReplacementNamed(context, '/permisos');
    }
  }

  // Función para mostrar un error en una alerta simple
  void _mostrarError(String mensaje) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No se pudo entrar'),
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

  // Función para iniciar sesión con correo y contraseña en Firebase
  Future<void> _iniciarConCorreo() async {
    FocusScope.of(context).unfocus();
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text;

    if (correo.isEmpty || contrasena.isEmpty) {
      _mostrarError('Escribe tu correo y tu contraseña.');
      return;
    }

    try {
      // Mandamos a llamar Firebase para iniciar sesión
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/permisos');
    } on FirebaseAuthException catch (e) {
      // Firebase responde con un "code" que nos dice qué falló
      if (e.code == 'invalid-credential' || e.code == 'user-not-found') {
        // Puede que el usuario no exista: ofrecemos crear la cuenta
        await _ofrecerRegistro(correo, contrasena);
      } else {
        _mostrarError(e.message ?? 'Ocurrió un error (${e.code}).');
      }
    }
  }

  // Función para registrar un usuario nuevo si el usuario acepta
  Future<void> _ofrecerRegistro(String correo, String contrasena) async {
    final crear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Crear cuenta?'),
        content: Text(
          'No encontramos una cuenta con esos datos.\n\n'
          '¿Quieres crear una cuenta nueva con $correo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    );
    if (crear != true) return;

    try {
      // Mandamos a llamar Firebase para crear el usuario (queda con sesión iniciada)
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/permisos');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // El correo sí existe, entonces lo que falló fue la contraseña
        _mostrarError('La contraseña es incorrecta.');
      } else if (e.code == 'weak-password') {
        _mostrarError('La contraseña debe tener al menos 6 caracteres.');
      } else {
        _mostrarError(e.message ?? 'Ocurrió un error (${e.code}).');
      }
    }
  }

  // Función para iniciar sesión con la cuenta de Google
  Future<void> _iniciarConGoogle() async {
    try {
      // signInWithProvider abre la ventana de Google y regresa con la sesión
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
      if (mounted) Navigator.pushReplacementNamed(context, '/permisos');
    } on FirebaseAuthException catch (e) {
      // Si el usuario cierra la ventana no mostramos nada
      if (e.code != 'canceled' && e.code != 'web-context-canceled') {
        _mostrarError(e.message ?? 'Ocurrió un error (${e.code}).');
      }
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
                const SizedBox(height: 24),
                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'nombre@ejemplo.com',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contrasenaController,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _iniciarConCorreo,
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
                  onPressed: _iniciarConGoogle,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
