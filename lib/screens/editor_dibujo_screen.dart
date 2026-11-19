import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../models/criatura.dart';
import '../widgets/dibujo_criatura.dart';

class EditorDibujoScreen extends StatefulWidget {
  const EditorDibujoScreen({super.key});

  @override
  State<EditorDibujoScreen> createState() => _EditorDibujoScreenState();
}

class _EditorDibujoScreenState extends State<EditorDibujoScreen> {
  final _trazos = <TrazoDibujo>[];
  final _nombre = TextEditingController();
  final _tipo = TextEditingController();
  final _descripcion = TextEditingController();
  Criatura? _original;
  String? _idNuevo;
  bool _inicializado = false;
  bool _guardando = false;
  Color _colorSeleccionado = Colors.red;
  int _revision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Criatura) {
      _original = argumento;
      _nombre.text = argumento.nombre;
      _tipo.text = argumento.tipo;
      _descripcion.text = argumento.descripcion;
      _trazos.addAll(
        argumento.dibujo.map((trazo) => TrazoDibujo(trazo.color, trazo.puntos)),
      );
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _tipo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (_nombre.text.trim().isEmpty ||
        _tipo.text.trim().isEmpty ||
        _trazos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe el nombre, el tipo y dibuja tu criatura.'),
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    final datos = context.read<DatosApp>();
    _idNuevo ??= datos.criaturas.doc().id;
    try {
      await datos.guardar(
        Criatura(
          id: _original?.id ?? _idNuevo!,
          nombre: _nombre.text.trim(),
          tipo: _tipo.text.trim(),
          descripcion: _descripcion.text.trim(),
          creadorId: datos.usuario!.uid,
          dibujo: _trazos
              .map((trazo) => TrazoDibujo(trazo.color, trazo.puntos))
              .toList(),
          version: _original?.version ?? 1,
        ),
        nueva: _original == null,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError ? error.message.toString() : 'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.',
            ),
          ),
        );
      }
    }
  }

  void _iniciarTrazo(Offset punto, double lado) {
    if (_guardando || _trazos.length >= 300) return;
    setState(() {
      _trazos.add(TrazoDibujo(_colorSeleccionado, [punto / lado]));
      _revision++;
    });
  }

  void _continuarTrazo(Offset punto, double lado) {
    if (_guardando ||
        _trazos.isEmpty ||
        _trazos.fold<int>(0, (total, trazo) => total + trazo.puntos.length) >=
            5000)
      return;
    final normalizado = Offset(
      (punto.dx / lado).clamp(0, 1),
      (punto.dy / lado).clamp(0, 1),
    );
    setState(() {
      _trazos.last.puntos.add(normalizado);
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
              TextField(
                controller: _nombre,
                enabled: !_guardando,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la criatura',
                  hintText: 'Mi nueva criatura',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tipo,
                enabled: !_guardando,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  hintText: 'Agua, aire…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descripcion,
                enabled: !_guardando,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
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
                            painter: PintorDibujo(_trazos, revision: _revision),
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
                    onPressed: _guardando || _trazos.isEmpty
                        ? null
                        : () => setState(() {
                            _trazos.removeLast();
                            _revision++;
                          }),
                    icon: const Icon(Icons.undo),
                    label: const Text('Deshacer'),
                  ),
                  TextButton.icon(
                    onPressed: _guardando || _trazos.isEmpty
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
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Guardando…' : 'Guardar criatura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
