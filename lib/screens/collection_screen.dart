import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'creature_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //* filtramos la lista para quedarnos solo con las que iscaptured es true
    final myCollection = dummyCreatures.where((c) => c.isCaptured).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('mis capturas')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, //_ 2 columnas para que se vean mas grandes en mi coleccion
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: myCollection.length,
        itemBuilder: (ctx, index) {
          final creature = myCollection[index];
          
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Image.network(creature.imageUrl)),
                  Text(creature.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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