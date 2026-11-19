import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../models/amistad.dart';
import '../widgets/recarga_firebase.dart';

class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  final _codigo = TextEditingController();
  String? _ocupado;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _accion(
    String clave,
    Future<void> Function() accion, {
    String? mensaje,
  }) async {
    if (_ocupado != null) return;
    setState(() => _ocupado = clave);
    try {
      await accion();
      if (mounted && mensaje != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'No se pudo completar la acción. Revisa tu conexión.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  Future<void> _agregar() async {
    final datos = context.read<DatosApp>();
    final codigo = _codigo.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el código de tu amigo.')),
      );
      return;
    }
    await _accion('agregar', () async {
      await datos.solicitarAmistad(codigo);
      if (mounted) _codigo.clear();
    }, mensaje: 'Solicitud enviada.');
  }

  Future<void> _eliminar(Amistad amistad) async {
    final datos = context.read<DatosApp>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar amigo?'),
        content: const Text('Dejarán de aparecer en sus listas de amigos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await _accion(amistad.id, () => datos.eliminarAmistad(amistad));
    }
  }

  String _nombre(DatosApp datos, Amistad amistad) {
    final uid = amistad.otroUsuario(datos.usuario!.uid);
    return datos.nombresAmigos[uid] ?? uid;
  }

  Widget _solicitud(
    DatosApp datos,
    Amistad amistad, {
    required bool recibida,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nombre(datos, amistad),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (recibida) ...[
                FilledButton(
                  onPressed: _ocupado != null
                      ? null
                      : () => _accion(
                          amistad.id,
                          () => datos.responderAmistad(amistad, aceptar: true),
                        ),
                  child: const Text('Aceptar'),
                ),
                TextButton(
                  onPressed: _ocupado != null
                      ? null
                      : () => _accion(
                          amistad.id,
                          () => datos.responderAmistad(amistad, aceptar: false),
                        ),
                  child: const Text('Rechazar'),
                ),
              ] else
                TextButton(
                  onPressed: _ocupado != null
                      ? null
                      : () => _accion(
                          amistad.id,
                          () => datos.eliminarAmistad(amistad),
                        ),
                  child: const Text('Cancelar solicitud'),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    final uid = datos.usuario!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RecargaFirebase(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu código de amigo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(uid),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _ocupado != null
                              ? null
                              : () => _accion(
                                  'copiar',
                                  () => Clipboard.setData(
                                    ClipboardData(text: uid),
                                  ),
                                  mensaje: 'Código copiado.',
                                ),
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Copiar código'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigo,
                  enabled: _ocupado == null,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 128,
                  decoration: const InputDecoration(
                    labelText: 'Código de tu amigo',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _agregar(),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _ocupado != null ? null : _agregar,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(
                    _ocupado == 'agregar' ? 'Enviando…' : 'Agregar amigo',
                  ),
                ),
                if (_ocupado != null) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (datos.solicitudesRecibidas.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Solicitudes recibidas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final solicitud in datos.solicitudesRecibidas)
                    _solicitud(datos, solicitud, recibida: true),
                ],
                if (datos.solicitudesEnviadas.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Solicitudes enviadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final solicitud in datos.solicitudesEnviadas)
                    _solicitud(datos, solicitud, recibida: false),
                ],
                const SizedBox(height: 24),
                Text(
                  'Mis amigos · ${datos.amigos.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (datos.amigos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Todavía no tienes amigos. Comparte tu código para agregar a alguien.',
                    ),
                  ),
                for (final amistad in datos.amigos)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        _nombre(datos, amistad),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Eliminar amigo',
                        onPressed: _ocupado != null
                            ? null
                            : () => _eliminar(amistad),
                        icon: const Icon(Icons.person_remove_outlined),
                      ),
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
