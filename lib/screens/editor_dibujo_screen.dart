import 'package:flutter/material.dart';

class EditorDibujoScreen extends StatelessWidget {
  const EditorDibujoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de dibujo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Dibuja tu criatura',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Nombre de la criatura',
                  hintText: 'Mi nueva criatura',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: colors.surface,
                    child: Center(
                      child: Text(
                        'Dibuja aqui',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Listo'),
                    content: const Text(
                      'Tu criatura podra aparecer en el mapa. Capturala para tenerla en tu coleccion.\n\nPor ahora, el dibujo no se guarda.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Seguir dibujando'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        child: const Text('Volver a mis creaciones'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Guardar · demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
