import 'package:flutter/material.dart';

import '../data/criaturas_demo.dart';
import '../theme/app_colors.dart';

class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mapa')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen local fija: no utiliza GPS, internet ni mapas reales.
                  Image.asset('assets/images/mapa_demo.png', fit: BoxFit.cover),
                  _marcador(
                    context,
                    criaturasDemo[0],
                    const Alignment(-0.6, -0.5),
                  ),
                  _marcador(
                    context,
                    criaturasDemo[1],
                    const Alignment(0.6, -0.05),
                  ),
                  _marcador(
                    context,
                    criaturasDemo[2],
                    const Alignment(-0.35, 0.65),
                  ),
                  const Align(
                    alignment: Alignment(0.15, 0.3),
                    child: CircleAvatar(
                      backgroundColor: AppColors.navy,
                      child: Icon(Icons.person, color: AppColors.surface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _marcador(
    BuildContext context,
    CriaturaDemo criatura,
    Alignment posicion,
  ) => Align(
    alignment: posicion,
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            Navigator.pushNamed(context, '/encuentro', arguments: criatura),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(criatura.icono, size: 40, color: AppColors.primary),
              Text(
                criatura.nombre,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
