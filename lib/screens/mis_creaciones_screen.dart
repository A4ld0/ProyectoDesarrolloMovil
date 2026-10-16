import 'package:flutter/material.dart';

class MisCreacionesScreen extends StatelessWidget {
  const MisCreacionesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis creaciones')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'Crear una criatura',
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/editor'),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Tooltip(
                      message: 'Compartir y recibir',
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/intercambio'),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Compartir'),
                      ),
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
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dibuja una criatura. Luego podras encontrarla y capturarla en el mapa.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              const Text(
                'Tus criaturas · 3 creaciones',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (final creature in const [
                ('Nubin', Icons.cloud_rounded),
                ('Burbujin', Icons.water_drop_rounded),
                ('Estelin', Icons.star_rounded),
              ])
                Card(
                  elevation: 0,
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            creature.$2,
                            size: 72,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          creature.$1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sin capturar',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/intercambio',
                            arguments: creature.$1,
                          ),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Compartir criatura'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
