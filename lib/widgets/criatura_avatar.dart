import 'package:flutter/material.dart';

import '../models/criatura.dart';
import 'dibujo_criatura.dart';

class CriaturaAvatar extends StatelessWidget {
  const CriaturaAvatar({required this.criatura, super.key});
  final Criatura criatura;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DibujoCriatura(criatura: criatura, tamano: 180),
    ),
  );
}
