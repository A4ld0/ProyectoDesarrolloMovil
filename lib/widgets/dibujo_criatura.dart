import 'package:flutter/material.dart'; //° CustomPainter y widgets

import '../models/criatura.dart'; //° modelo de criatura y trazo

//* muestra el dibujo de la criatura o su icono si no tiene dibujo
class DibujoCriatura extends StatelessWidget {
  const DibujoCriatura({required this.criatura, this.tamano = 120, super.key});

  final Criatura criatura;
  final double tamano;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamano,
    child: criatura.dibujo.isEmpty
        ? Icon(criatura.icono, size: tamano * 0.65)
        : CustomPaint(painter: PintorDibujo(criatura.dibujo)),
  );
}

//! pinta los trazos guardados; los puntos vienen de 0 a 1 y se
//! multiplican por el tamano para escalar el dibujo
class PintorDibujo extends CustomPainter {
  const PintorDibujo(this.trazos, {this.revision = 0});

  final List<TrazoDibujo> trazos;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final pincel = Paint()
      ..strokeWidth = size.shortestSide / 80
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final trazo in trazos) {
      if (trazo.puntos.isEmpty) continue;
      pincel.color = trazo.color;
      final inicio = trazo.puntos.first * size.width;
      if (trazo.puntos.length == 1) {
        canvas.drawCircle(
          inicio,
          pincel.strokeWidth / 2,
          Paint()..color = trazo.color,
        );
        continue;
      }
      final ruta = Path()..moveTo(inicio.dx, inicio.dy);
      for (final punto in trazo.puntos.skip(1)) {
        ruta.lineTo(punto.dx * size.width, punto.dy * size.height);
      }
      canvas.drawPath(ruta, pincel);
    }
  }

  //? revision cambia en cada trazo nuevo para forzar el repintado
  @override
  bool shouldRepaint(covariant PintorDibujo anterior) =>
      revision != anterior.revision || trazos != anterior.trazos;
}
