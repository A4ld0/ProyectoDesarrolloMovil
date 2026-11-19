import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../firebase_options.dart';

class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key});
  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _nombre = TextEditingController();
  bool _registrando = false;
  bool _ocupado = false;
  String? _mensaje;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      await accion();
    } on FirebaseAuthException catch (error) {
      if (mounted)
        setState(
          () => _mensaje = switch (error.code) {
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => 'Revisa tu correo y contraseña.',
            'email-already-in-use' =>
              'Este correo ya tiene una cuenta. Inicia sesión.',
            'weak-password' => 'Usa una contraseña de al menos 6 caracteres.',
            'too-many-requests' =>
              'Espera un momento antes de volver a intentar.',
            'network-request-failed' => 'Revisa tu conexión a internet.',
            'user-disabled' => 'Esta cuenta está deshabilitada.',
            _ => 'No se pudo completar el acceso. Inténtalo de nuevo.',
          },
        );
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _mensaje = 'No se pudo completar el acceso. Inténtalo de nuevo.',
        );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    final datos = context.read<DatosApp>();
    final correo = _correo.text.trim();
    final contrasena = _contrasena.text;
    final nombre = _nombre.text.trim();
    final registrando = _registrando;
    await _ejecutar(() async {
      if (registrando) {
        await datos.registrar(
          correo: correo,
          contrasena: contrasena,
          nombre: nombre,
        );
      } else {
        await datos.auth.signInWithEmailAndPassword(
          email: correo,
          password: contrasena,
        );
      }
    });
  }

  Future<void> _google() => _ejecutar(() async {
    final auth = context.read<DatosApp>().auth;
    if (kIsWeb) {
      await auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    final cuenta = await GoogleSignIn(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
    ).signIn();
    if (cuenta == null) return;
    final tokens = await cuenta.authentication;
    await auth.signInWithCredential(
      GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      ),
    );
  });

  Future<void> _recuperar() async {
    final auth = context.read<DatosApp>().auth;
    final correo = _correo.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_correo.text.trim())) {
      setState(
        () =>
            _mensaje = 'Escribe un correo válido para recuperar tu contraseña.',
      );
      return;
    }
    await _ejecutar(() async {
      await auth.sendPasswordResetEmail(email: correo);
      if (mounted)
        setState(() => _mensaje = 'Revisa tu correo para recuperar el acceso.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formulario,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colores.primaryContainer,
                    child: Icon(
                      Icons.pets_rounded,
                      size: 40,
                      color: colores.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'pokemonchafa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colores.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_registrando) ...[
                    TextFormField(
                      controller: _nombre,
                      maxLength: 60,
                      enabled: !_ocupado,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) =>
                          valor!.trim().isEmpty ? 'Escribe tu nombre.' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _correo,
                    enabled: !_ocupado,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(valor!.trim())
                        ? null
                        : 'Escribe un correo válido.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contrasena,
                    enabled: !_ocupado,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => valor!.length < 6
                        ? 'Escribe al menos 6 caracteres.'
                        : null,
                    onFieldSubmitted: (_) => _entrar(),
                  ),
                  const SizedBox(height: 20),
                  if (_mensaje != null) ...[
                    Text(_mensaje!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _ocupado ? null : _entrar,
                    child: _ocupado
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _registrando ? 'Crear cuenta' : 'Iniciar sesión',
                          ),
                  ),
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => setState(() {
                            _registrando = !_registrando;
                            _mensaje = null;
                            _formulario.currentState?.reset();
                          }),
                    child: Text(
                      _registrando ? 'Ya tengo una cuenta' : 'Registrarme',
                    ),
                  ),
                  if (!_registrando)
                    TextButton(
                      onPressed: _ocupado ? null : _recuperar,
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  const SizedBox(height: 12),
                  if (kIsWeb ||
                      defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
                    OutlinedButton.icon(
                      onPressed: _ocupado ? null : _google,
                      icon: const Text(
                        'G',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      label: const Text('Continuar con Google'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
