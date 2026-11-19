import 'package:flutter/material.dart';

// Catálogo compartido por el mapa y los intercambios NFC.
class CriaturaDemo {
  final String id;
  final String nombre;
  final String tipo;
  final IconData icono;

  const CriaturaDemo(this.id, this.nombre, this.tipo, this.icono);
}

const criaturasDemo = [
  CriaturaDemo('nubin', 'Nubin', 'Aire', Icons.cloud_rounded),
  CriaturaDemo('burbujin', 'Burbujin', 'Agua', Icons.water_drop_rounded),
  CriaturaDemo('estelin', 'Estelin', 'Estrella', Icons.star_rounded),
];

CriaturaDemo? criaturaDemoPorId(String id) {
  for (final criatura in criaturasDemo) {
    if (criatura.id == id) return criatura;
  }
  return null;
}
