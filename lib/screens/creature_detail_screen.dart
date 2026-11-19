import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../models/criatura.dart';
import '../widgets/dibujo_criatura.dart';
import '../widgets/recarga_firebase.dart';

class CreatureDetailScreen extends StatelessWidget {
  const CreatureDetailScreen({super.key, required this.creature});
  final Criatura creature;

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    final criatura = datos.porId(creature.id) ?? creature;
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(criatura.nombre)),
      body: RecargaFirebase(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: DibujoCriatura(criatura: criatura, tamano: 240)),
            const SizedBox(height: 24),
            Text(
              criatura.nombre,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colores.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Tipo ${criatura.tipo}'),
            const SizedBox(height: 16),
            if (criatura.descripcion.isNotEmpty) Text(criatura.descripcion),
            const SizedBox(height: 16),
            Text(
              datos.estaCapturada(criatura.id)
                  ? 'En tu colección'
                  : 'Sin capturar',
            ),
            const SizedBox(height: 24),
            if (datos.porId(criatura.id) != null)
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/intercambio',
                  arguments: criatura,
                ),
                icon: const Icon(Icons.nfc),
                label: const Text('Compartir por NFC'),
              ),
          ],
        ),
      ),
    );
  }
}
