import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class EditorDibujoScreen extends StatefulWidget {
  const EditorDibujoScreen({super.key});

  @override
  State<EditorDibujoScreen> createState() => _EditorDibujoScreenState();
}

class _EditorDibujoScreenState extends State<EditorDibujoScreen> {
  final _trazos = <_Trazo>[];
  Color _colorSeleccionado = Colors.red;
  int _revision = 0;

  void _iniciarTrazo(Offset punto, double lado) {
    setState(() {
      _trazos.add(_Trazo(_colorSeleccionado, punto / lado));
      _revision++;
    });
  }

  void _continuarTrazo(Offset punto, double lado) {
    if (_trazos.isEmpty) return;
    setState(() {
      _trazos.last.puntos.add(punto / lado);
      _revision++;
    });
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final opcion in const [
                    (nombre: 'Rojo', color: Colors.red),
                    (nombre: 'Amarillo', color: Colors.yellow),
                    (nombre: 'Azul', color: Colors.blue),
                  ])
                    Semantics(
                      label: opcion.nombre,
                      button: true,
                      selected: _colorSeleccionado == opcion.color,
                      child: InkResponse(
                        onTap: () => setState(() {
                          _colorSeleccionado = opcion.color;
                        }),
                        radius: 24,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opcion.color,
                              border: Border.all(
                                color: _colorSeleccionado == opcion.color
                                    ? colors.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lado = constraints.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        dragStartBehavior: DragStartBehavior.down,
                        onTapUp: (toque) =>
                            _iniciarTrazo(toque.localPosition, lado),
                        onHorizontalDragStart: (inicio) =>
                            _iniciarTrazo(inicio.localPosition, lado),
                        onHorizontalDragUpdate: (movimiento) =>
                            _continuarTrazo(movimiento.localPosition, lado),
                        onVerticalDragStart: (inicio) =>
                            _iniciarTrazo(inicio.localPosition, lado),
                        onVerticalDragUpdate: (movimiento) =>
                            _continuarTrazo(movimiento.localPosition, lado),
                        child: ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: CustomPaint(
                            painter: _PintorDeTrazos(_trazos, _revision),
                            child: Center(
                              child: _trazos.isEmpty
                                  ? Text(
                                      'Dibuja aquí',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _trazos.isEmpty
                        ? null
                        : () => setState(() {
                            _trazos.removeLast();
                            _revision++;
                          }),
                    icon: const Icon(Icons.undo),
                    label: const Text('Deshacer'),
                  ),
                  TextButton.icon(
                    onPressed: _trazos.isEmpty
                        ? null
                        : () => setState(() {
                            _trazos.clear();
                            _revision++;
                          }),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpiar lienzo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar criatura'),
              ),
              const SizedBox(height: 8),
              Text(
                'El guardado de criaturas en Firebase está pendiente.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Trazo {
  _Trazo(this.color, Offset inicio) : puntos = [inicio];

  final Color color;
  final List<Offset> puntos;
}

class _PintorDeTrazos extends CustomPainter {
  const _PintorDeTrazos(this.trazos, this.revision);

  final List<_Trazo> trazos;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final relleno = Paint();

    for (final trazo in trazos) {
      pincel.color = trazo.color;
      relleno.color = trazo.color;
      final inicio = trazo.puntos.first * size.width;
      if (trazo.puntos.length == 1) {
        canvas.drawCircle(inicio, pincel.strokeWidth / 2, relleno);
        continue;
      }

      final ruta = Path()..moveTo(inicio.dx, inicio.dy);
      for (var indice = 1; indice < trazo.puntos.length; indice++) {
        final punto = trazo.puntos[indice] * size.width;
        ruta.lineTo(punto.dx, punto.dy);
      }
      canvas.drawPath(ruta, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorDeTrazos anterior) =>
      revision != anterior.revision;
}
