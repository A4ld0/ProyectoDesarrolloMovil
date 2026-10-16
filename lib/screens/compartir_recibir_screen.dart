import 'package:flutter/material.dart';

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

  Widget _panel(BuildContext context, String name, bool receiving) {
    final colors = Theme.of(context).colorScheme;
    return Center(
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
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Icon(
                    receiving ? Icons.water_drop_rounded : Icons.cloud_rounded,
                    size: 100,
                    color: colors.primary,
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
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!receiving)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline, color: colors.primary),
                title: const Text('Busca y captura'),
                subtitle: const Text(
                  'Al recibirla, podra aparecer en tu mapa. Capturala para tenerla en tu coleccion.',
                ),
              ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: colors.primaryContainer,
              child: ListTile(
                leading: Icon(Icons.nfc, color: colors.primary),
                title: const Text('Intercambio NFC'),
                subtitle: const Text(
                  'Demostración: el intercambio entre dos Android '
                  'está pendiente. No se activa NFC ni se transfieren datos.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.nfc),
              label: Text(receiving ? 'Probar recibir' : 'Probar compartir'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    receiving ? 'Recibir (prueba)' : 'Compartir (prueba)',
                  ),
                  content: Text(
                    receiving
                        ? 'Aquí se leerán por NFC los datos de una criatura '
                              'compartida por otro Android. Después podrá '
                              'aparecer en tu mapa para capturarla.\n\n'
                              'Funcionalidad pendiente: por ahora, no se activa '
                              'NFC, no se recibe ninguna criatura ni se guarda nada.'
                        : 'Aquí se preparará a $name para compartirla con '
                              'otro Android mediante NFC.\n\n'
                              'Funcionalidad pendiente: la emisión desde el '
                              'teléfono requiere una integración adicional. '
                              'Por ahora, no se activa NFC ni se envían datos.',
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
}
