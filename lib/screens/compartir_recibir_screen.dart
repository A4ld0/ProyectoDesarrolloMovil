import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CompartirRecibirScreen extends StatelessWidget {
  const CompartirRecibirScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final name =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Nubin';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compartir y recibir'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Compartir', icon: Icon(Icons.ios_share)),
              Tab(text: 'Recibir', icon: Icon(Icons.move_to_inbox_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _panel(context, name, false),
            _panel(context, 'Burbujin', true),
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, String name, bool receiving) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            receiving ? 'Recibe una criatura' : 'Comparte tu criatura',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Icon(
                  receiving ? Icons.water_drop_rounded : Icons.cloud_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  receiving
                      ? 'Creada por Luna · Ejemplo'
                      : 'Creada por ti · Ejemplo',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!receiving)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('Busca y captura'),
              subtitle: Text(
                'Al recibirla, podra aparecer en tu mapa. Capturala para tenerla en tu coleccion.',
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: Icon(receiving ? Icons.add : Icons.ios_share),
            label: Text(receiving ? 'Probar recibir' : 'Probar compartir'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(
                  receiving ? 'Recibir (prueba)' : 'Compartir (prueba)',
                ),
                content: receiving
                    ? null
                    : Text(
                        receiving
                            ? '$name se agregaria a tu enciclopedia y podria aparecer en el mapa.\n\nPor ahora, no se guarda nada.'
                            : 'La otra persona podria encontrar a $name en su mapa y capturarla.\n\nAun falta elegir como compartir.',
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver a mis creaciones'),
          ),
        ],
      ),
    ),
  );
}
