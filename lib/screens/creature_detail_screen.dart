import 'package:flutter/material.dart';

import '../models/creature.dart';

class CreatureDetailScreen extends StatelessWidget {
  // Recibe la criatura seleccionada en las pantallas anteriores.
  final Creature creature;

  const CreatureDetailScreen({super.key, required this.creature});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.tertiaryContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('mi pokemon'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //_ imagen grande centrada
            Image.network(creature.imageUrl, height: 250),

            //_ contenedor blanco con bordes redondeados para la info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        creature.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'nivel 12',
                          style: TextStyle(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  //? aqui mostramos los tipos que tiene el array con rectangulos de colores
                  Row(
                    children: creature.types
                        .map(
                          (type) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(type),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  //* fila de estadisticas hardcodeadas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        context,
                        'hp',
                        creature.hp.toString(),
                        Icons.favorite,
                        colors.error,
                      ),
                      _buildStatColumn(
                        context,
                        'ataque',
                        creature.attack.toString(),
                        Icons.colorize,
                        colors.onSurfaceVariant,
                      ),
                      _buildStatColumn(
                        context,
                        'defensa',
                        creature.defense.toString(),
                        Icons.shield,
                        colors.tertiary,
                      ),
                      _buildStatColumn(
                        context,
                        'velocidad',
                        creature.speed.toString(),
                        Icons.speed,
                        colors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'descripcion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    creature.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 30),
                  //* boton de compartir (simulacion de nfc/qr)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.tertiary,
                        foregroundColor: colors.onTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        //_ aqui a futuro ira la logica de generar el qr o mandar por nfc
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'preparando nfc/qr para compartir...',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text(
                        'compartir',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //* widget auxiliar para no repetir codigo al dibujar las 4 estadisticas
  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
