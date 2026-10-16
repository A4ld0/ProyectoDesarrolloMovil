import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import 'creature_detail_screen.dart';

class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('enciclopedia global')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, //_ 3 columnas para ver muchas criaturas a la vez
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: dummyCreatures.length,
        itemBuilder: (ctx, index) {
          final creature = dummyCreatures[index];

          return GestureDetector(
            onTap: () {
              //* si tocamos una criatura, abrimos su ficha detallada
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => CreatureDetailScreen(creature: creature),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              //? usamos colorfiltered para hacer grises a las que no estan capturadas
              child: ColorFiltered(
                colorFilter: creature.isCaptured
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ) //! sin filtro si ya se capturo
                    : const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]), //! matriz que convierte a escala de grises
                child: Image.network(creature.imageUrl),
              ),
            ),
          );
        },
      ),
    );
  }
}
