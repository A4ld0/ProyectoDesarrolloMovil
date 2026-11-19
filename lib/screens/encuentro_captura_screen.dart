import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/criaturas_demo.dart';
import '../data/criaturas_nfc.dart';
import '../widgets/criatura_avatar.dart';

class EncuentroCapturaScreen extends StatefulWidget {
  const EncuentroCapturaScreen({super.key});

  @override
  State<EncuentroCapturaScreen> createState() => _EncuentroCapturaScreenState();
}

class _EncuentroCapturaScreenState extends State<EncuentroCapturaScreen> {
  bool _guardando = false;

  Future<void> _capturar(CriaturaDemo criatura, CriaturasNfc almacen) async {
    if (_guardando) return;
    if (almacen.pendiente(criatura)) {
      setState(() => _guardando = true);
      try {
        await almacen.capturar(criatura);
      } catch (_) {
        if (mounted) {
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar la captura.')),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/resultado',
        arguments: criatura,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final almacen = context.watch<CriaturasNfc>();
    // Recibe la criatura que se tocó en el mapa.
    final criatura =
        ModalRoute.of(context)?.settings.arguments as CriaturaDemo? ??
        criaturasDemo[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Captura la criatura',
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
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (almacen.pendiente(criatura))
                const Text('Recibida por NFC', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _guardando
                    ? null
                    : () => _capturar(criatura, almacen),
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
