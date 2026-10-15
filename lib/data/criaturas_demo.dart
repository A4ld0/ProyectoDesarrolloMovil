import 'package:flutter/material.dart';

// Datos fijos para mostrar el recorrido. No hay base de datos ni capturas guardadas.
class CriaturaDemo {
  final String nombre;
  final String tipo;
  final IconData icono;

  const CriaturaDemo(this.nombre, this.tipo, this.icono);
}

const criaturasDemo = [
  CriaturaDemo('Nubin', 'Aire', Icons.cloud_rounded),
  CriaturaDemo('Burbujin', 'Agua', Icons.water_drop_rounded),
  CriaturaDemo('Estelin', 'Estrella', Icons.star_rounded),
];
