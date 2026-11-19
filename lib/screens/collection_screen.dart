import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/criaturas_nfc.dart';
import '../data/dummy_data.dart';
import 'creature_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    //* filtramos la lista para quedarnos solo con las que iscaptured es true
    final myCollection = dummyCreatures.where((c) => c.isCaptured).toList();
    final capturasNfc = context.watch<CriaturasNfc>().capturadas.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('mis capturas')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              2, //_ 2 columnas para que se vean mas grandes en mi coleccion
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: capturasNfc.length + myCollection.length,
        itemBuilder: (ctx, index) {
          if (index < capturasNfc.length) {
            final criatura = capturasNfc[index];
            return Card(
              color: colors.tertiaryContainer,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(
                      criatura.icono,
                      size: 36,
                      color: colors.onTertiaryContainer,
                    ),
                    Text(
                      criatura.nombre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('Tipo ${criatura.tipo}', textAlign: TextAlign.center),
                    const Text('Recibida por NFC', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          final creature = myCollection[index - capturasNfc.length];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => CreatureDetailScreen(creature: creature),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.tertiary, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.network(
                      creature.imageUrl,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Text(
                    creature.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
