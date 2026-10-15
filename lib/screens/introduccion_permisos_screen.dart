import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IntroduccionPermisosScreen extends StatefulWidget {
  const IntroduccionPermisosScreen({super.key});

  @override
  State<IntroduccionPermisosScreen> createState() =>
      _IntroduccionPermisosScreenState();
}

class _IntroduccionPermisosScreenState
    extends State<IntroduccionPermisosScreen> {
  // Solo cambian el texto de los botones. No solicitan permisos del teléfono.
  bool ubicacionSimulada = false;
  bool camaraSimulada = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Permisos')),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/mapa'),
          child: const Text('Comenzar a explorar'),
        ),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _permiso(
              icono: Icons.location_on_outlined,
              titulo: 'Ubicación',
              descripcion: 'Para encontrar criaturas cerca de ti.',
              activado: ubicacionSimulada,
              onPressed: () => setState(() => ubicacionSimulada = true),
            ),
            _permiso(
              icono: Icons.camera_alt_outlined,
              titulo: 'Cámara',
              descripcion: 'Para ver criaturas durante el encuentro.',
              activado: camaraSimulada,
              onPressed: () => setState(() => camaraSimulada = true),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _permiso({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required bool activado,
    required VoidCallback onPressed,
  }) => Card(
    elevation: 0,
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icono, color: AppColors.primary),
            title: Text(titulo),
            subtitle: Text(descripcion),
          ),
          OutlinedButton.icon(
            onPressed: activado ? null : onPressed,
            icon: Icon(activado ? Icons.check_circle_outline : Icons.touch_app),
            label: Text(
              activado ? '$titulo simulada' : 'Simular permiso de $titulo',
            ),
          ),
        ],
      ),
    ),
  );
}
