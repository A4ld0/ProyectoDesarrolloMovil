import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IntroduccionPermisosScreen extends StatefulWidget {
  const IntroduccionPermisosScreen({super.key, this.desdeAjustes = false});
  final bool desdeAjustes;
  @override
  State<IntroduccionPermisosScreen> createState() =>
      _IntroduccionPermisosScreenState();
}

class _IntroduccionPermisosScreenState extends State<IntroduccionPermisosScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _ubicacion;
  PermissionStatus? _notificaciones;
  bool _ocupado = false;
  bool get _movil =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _leer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _leer();
  }

  Future<void> _leer() async {
    if (!_movil) return;
    try {
      final ubicacion = await Permission.locationWhenInUse.status;
      final notificaciones = await Permission.notification.status;
      if (mounted)
        setState(() {
          _ubicacion = ubicacion;
          _notificaciones = notificaciones;
        });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron consultar los permisos.'),
          ),
        );
    }
  }

  Future<void> _solicitar(Permission permiso, PermissionStatus? estado) async {
    setState(() => _ocupado = true);
    try {
      if (estado?.isPermanentlyDenied == true) {
        await openAppSettings();
      } else {
        await permiso.request();
      }
      await _leer();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cambiar el permiso. Revisa los ajustes del teléfono.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _permiso(
    String titulo,
    String descripcion,
    IconData icono,
    Permission permiso,
    PermissionStatus? estado,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icono),
            title: Text(titulo),
            subtitle: Text(descripcion),
          ),
          if (_movil)
            OutlinedButton(
              onPressed: _ocupado || estado == null || estado.isGranted
                  ? null
                  : () => _solicitar(permiso, estado),
              child: Text(
                estado?.isGranted == true
                    ? 'Permitido'
                    : estado?.isPermanentlyDenied == true
                    ? 'Abrir ajustes'
                    : 'Permitir',
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Permisos')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _permiso(
          'Ubicación',
          'Permite mostrar tu posición y encontrar criaturas en el mapa.',
          Icons.location_on_outlined,
          Permission.locationWhenInUse,
          _ubicacion,
        ),
        _permiso(
          'Notificaciones',
          'Permite registrar este dispositivo para recibir avisos.',
          Icons.notifications_outlined,
          Permission.notification,
          _notificaciones,
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.photo_library_outlined),
            title: Text('Foto de perfil'),
            subtitle: Text(
              'Selecciona una imagen desde la galería en tu perfil.',
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          onPressed: () => widget.desdeAjustes
              ? Navigator.pop(context)
              : Navigator.pushReplacementNamed(context, '/mapa'),
          child: Text(
            widget.desdeAjustes ? 'Volver a ajustes' : 'Comenzar a explorar',
          ),
        ),
      ),
    ),
  );
}
