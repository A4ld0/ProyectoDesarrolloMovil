import 'package:flutter/material.dart';

import '../data/criaturas_demo.dart';

// El mismo icono fijo se usa en el mapa, el encuentro y el resultado.
class CriaturaAvatar extends StatelessWidget {
  final CriaturaDemo criatura;

  const CriaturaAvatar({super.key, required this.criatura});

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          criatura.icono,
          size: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}
