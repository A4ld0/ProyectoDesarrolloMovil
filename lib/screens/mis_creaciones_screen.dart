import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../models/criatura.dart';
import '../widgets/dibujo_criatura.dart';
import '../widgets/recarga_firebase.dart';

class MisCreacionesScreen extends StatefulWidget {
  const MisCreacionesScreen({super.key});
  @override
  State<MisCreacionesScreen> createState() => _MisCreacionesScreenState();
}

class _MisCreacionesScreenState extends State<MisCreacionesScreen> {
  String? _eliminando;

  Future<void> _eliminar(Criatura criatura) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar criatura?'),
        content: Text(
          'Se eliminará ${criatura.nombre} de tus creaciones y del mapa.',
        ),
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
    if (confirmar != true || !mounted) return;
    setState(() => _eliminando = criatura.id);
    try {
      await context.read<DatosApp>().eliminar(criatura);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar. Inténtalo de nuevo.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _eliminando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    final criaturas = datos.creaciones;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis creaciones')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: RecargaFirebase(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/editor'),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/intercambio'),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Crea tu criatura',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tus criaturas · ${criaturas.length} creaciones'),
                if (criaturas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Dibuja tu primera criatura para verla aquí y encontrarla en el mapa.',
                    ),
                  ),
                for (final criatura in criaturas)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: DibujoCriatura(criatura: criatura)),
                          const SizedBox(height: 8),
                          Text(
                            criatura.nombre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Tipo ${criatura.tipo}'),
                          Text(
                            datos.estaCapturada(criatura.id)
                                ? 'Capturada'
                                : 'Sin capturar',
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _eliminando != null
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        '/editor',
                                        arguments: criatura,
                                      ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar'),
                              ),
                              TextButton.icon(
                                onPressed: _eliminando != null
                                    ? null
                                    : () => _eliminar(criatura),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(
                                  _eliminando == criatura.id
                                      ? 'Eliminando…'
                                      : 'Eliminar',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _eliminando != null
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        '/intercambio',
                                        arguments: criatura,
                                      ),
                                icon: const Icon(Icons.nfc),
                                label: const Text('Compartir'),
                              ),
                            ],
                          ),
                        ],
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
