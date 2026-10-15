import 'package:flutter/material.dart';

import '../data/criaturas_demo.dart';
import '../theme/app_colors.dart';
import '../widgets/criatura_avatar.dart';

class EncuentroCapturaScreen extends StatelessWidget {
  const EncuentroCapturaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibe la criatura que se tocó en el mapa.
    final criatura =
        ModalRoute.of(context)?.settings.arguments as CriaturaDemo? ??
        criaturasDemo[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Captura la criatura',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CriaturaAvatar(criatura: criatura),
              const SizedBox(height: 24),
              Text(
                criatura.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tipo ${criatura.tipo}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                // La captura siempre tiene éxito en esta demostración.
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/resultado',
                  arguments: criatura,
                ),
                icon: const Icon(Icons.catching_pokemon),
                label: const Text('Capturar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al mapa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
