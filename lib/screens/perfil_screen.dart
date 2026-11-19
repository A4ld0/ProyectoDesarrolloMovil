import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../data/foto_perfil_local.dart';
import '../widgets/foto_perfil_tile.dart';
import '../widgets/recarga_firebase.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _ocupado = false;

  Future<void> _editarNombre() async {
    final datos = context.read<DatosApp>();
    var nombre = datos.perfil['nombre'] as String? ?? '';
    final valor = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextFormField(
          initialValue: nombre,
          onChanged: (valor) => nombre = valor,
          maxLength: 60,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nombre.trim().isNotEmpty)
                Navigator.pop(context, nombre.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (valor == null || !mounted) return;
    await _guardar(() => datos.guardarPerfil(nombre: valor));
  }

  Future<void> _guardar(Future<void> Function() accion) async {
    setState(() => _ocupado = true);
    try {
      await accion();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Revisa tu conexión.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _importar() async {
    final datos = context.read<DatosApp>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar capturas locales'),
        content: Text(
          'Las capturas de la versión anterior se agregarán a la cuenta ${datos.perfil['correo']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted)
      await _guardar(datos.importarCapturasLocales);
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    final usuario = datos.usuario;
    final nombre = datos.perfil['nombre'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RecargaFirebase(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                if (usuario != null && FotoPerfilLocal.disponible) ...[
                  Card(
                    child: FotoPerfilTile(
                      key: ValueKey(usuario.uid),
                      uid: usuario.uid,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      nombre.isEmpty
                          ? datos.perfil['correo'] as String? ?? ''
                          : nombre,
                    ),
                    subtitle: Text(datos.perfil['correo'] as String? ?? ''),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _ocupado ? null : _editarNombre,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.collections_outlined),
                    title: Text(
                      '${datos.capturadas.length} capturas · ${datos.creaciones.length} creaciones',
                    ),
                  ),
                ),
                if (datos.avisoToken != null)
                  ListTile(
                    title: Text(datos.avisoToken!),
                    trailing: IconButton(
                      tooltip: 'Registrar dispositivo',
                      icon: const Icon(Icons.refresh),
                      onPressed: _ocupado
                          ? null
                          : () => _guardar(datos.actualizarToken),
                    ),
                  ),
                if (datos.hayCapturasLocales &&
                    datos.perfil['capturasLocalesImportadas'] != true)
                  TextButton.icon(
                    onPressed: _ocupado ? null : _importar,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Importar capturas locales'),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Ajustes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/ajustes'),
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
