import 'package:flutter/material.dart';

class TrazoDibujo {
  TrazoDibujo(this.color, List<Offset> puntos) : puntos = List.of(puntos);

  final Color color;
  final List<Offset> puntos;

  Map<String, dynamic> toMap() => {
    'color': color.toARGB32(),
    'puntos': [
      for (final punto in puntos) ...[punto.dx, punto.dy],
    ],
  };

  factory TrazoDibujo.fromMap(Map<String, dynamic> datos) {
    final puntos = (datos['puntos'] as List).cast<num>();
    if (puntos.isEmpty || puntos.length.isOdd) {
      throw const FormatException('El trazo está incompleto.');
    }
    return TrazoDibujo(Color(datos['color'] as int), [
      for (var i = 0; i < puntos.length; i += 2)
        Offset(puntos[i].toDouble(), puntos[i + 1].toDouble()),
    ]);
  }
}

class Criatura {
  const Criatura({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.creadorId,
    this.dibujo = const [],
    this.simbolo = 'mascota',
    this.version = 1,
  });

  final String id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final String creadorId;
  final List<TrazoDibujo> dibujo;
  final String simbolo;
  final int version;

  IconData get icono => switch (simbolo) {
    'nube' => Icons.cloud_rounded,
    'agua' => Icons.water_drop_rounded,
    'estrella' => Icons.star_rounded,
    _ => Icons.pets_rounded,
  };

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'tipo': tipo,
    'descripcion': descripcion,
    'creadorId': creadorId,
    'dibujo': dibujo.map((trazo) => trazo.toMap()).toList(),
    'simbolo': simbolo,
    'version': version,
  };

  factory Criatura.fromMap(String id, Map<String, dynamic> datos) => Criatura(
    id: id,
    nombre: datos['nombre'] as String,
    tipo: datos['tipo'] as String,
    descripcion: datos['descripcion'] as String? ?? '',
    creadorId: datos['creadorId'] as String,
    simbolo: datos['simbolo'] as String? ?? 'mascota',
    version: datos['version'] as int? ?? 1,
    dibujo: [
      for (final trazo in datos['dibujo'] as List? ?? [])
        TrazoDibujo.fromMap(Map<String, dynamic>.from(trazo as Map)),
    ],
  );
}
