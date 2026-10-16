import 'package:flutter/material.dart';

import '../data/criaturas_demo.dart';
import '../widgets/criatura_avatar.dart';

class ResultadoCapturaScreen extends StatelessWidget {
  const ResultadoCapturaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final criatura =
        ModalRoute.of(context)?.settings.arguments as CriaturaDemo? ??
        criaturasDemo[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Captura exitosa',
          style: TextStyle(
            color: colors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CriaturaAvatar(criatura: criatura),
              const SizedBox(height: 20),
              Text(
                criatura.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tipo ${criatura.tipo}',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                // El encuentro fue reemplazado por este resultado: debajo está el mapa.
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Seguir explorando'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/creaciones',
                  (route) => false,
                ),
                icon: const Icon(Icons.brush_outlined),
                label: const Text('Ver mis creaciones'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
