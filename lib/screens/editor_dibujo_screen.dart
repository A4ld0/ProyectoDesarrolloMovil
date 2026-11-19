import 'package:flutter/gestures.dart'; //° DragStartBehavior para el lienzo
import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado
import 'package:shared_preferences/shared_preferences.dart'; //° guarda los colores propios en el telefono

import '../data/datos_app.dart'; //° provider con firestore
import '../models/criatura.dart'; //° modelo de criatura y trazo
import '../widgets/dibujo_criatura.dart'; //° pintor del dibujo

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

  //_ colores base que siempre aparecen
  final List<Color> _coloresBase = [Colors.red, Colors.yellow, Colors.blue];
  final List<String> _nombresBase = ['Rojo', 'Amarillo', 'Azul'];
  //_ colores que el usuario crea con el boton +
  final List<Color> _coloresPropios = [];

  @override
  void initState() {
    super.initState();
    _cargarColores();
  }

  //* lee los colores propios guardados en el telefono
  Future<void> _cargarColores() async {
    final prefs = SharedPreferencesAsync();
    final guardados = await prefs.getStringList('coloresPropios') ?? [];
    if (!mounted) return;
    setState(() {
      for (final valor in guardados) {
        _coloresPropios.add(Color(int.parse(valor)));
      }
    });
  }

  //* guarda la lista de colores propios como texto (el numero argb)
  Future<void> _guardarColores() async {
    final prefs = SharedPreferencesAsync();
    final valores = <String>[];
    for (final color in _coloresPropios) {
      valores.add(color.toARGB32().toString());
    }
    await prefs.setStringList('coloresPropios', valores);
  }

  //* abre un dialogo con 3 sliders (rojo, verde, azul) para crear un color
  Future<void> _crearColor() async {
    double rojo = 120;
    double verde = 60;
    double azul = 200;

    final nuevo = await showDialog<Color>(
      context: context,
      builder: (context) {
        //? StatefulBuilder deja usar setState solo dentro del dialogo
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final vistaPrevia = Color.fromARGB(
              255,
              rojo.round(),
              verde.round(),
              azul.round(),
            );
            return AlertDialog(
              title: const Text('Crea tu color'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: vistaPrevia,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _slider('Rojo', rojo, Colors.red, (valor) {
                    setDialogState(() => rojo = valor);
                  }),
                  _slider('Verde', verde, Colors.green, (valor) {
                    setDialogState(() => verde = valor);
                  }),
                  _slider('Azul', azul, Colors.blue, (valor) {
                    setDialogState(() => azul = valor);
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, vistaPrevia),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (nuevo == null) return;
    //! si el color ya existe solo se selecciona, no se repite
    final yaExiste =
        _coloresBase.contains(nuevo) || _coloresPropios.contains(nuevo);
    setState(() {
      if (!yaExiste) _coloresPropios.add(nuevo);
      _colorSeleccionado = nuevo;
    });
    if (!yaExiste) await _guardarColores();
  }

  //* renglon con el nombre del canal y su slider de 0 a 255
  Widget _slider(
    String nombre,
    double valor,
    Color color,
    ValueChanged<double> alCambiar,
  ) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(nombre)),
        Expanded(
          child: Slider(
            value: valor,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: alCambiar,
          ),
        ),
        SizedBox(width: 32, child: Text('${valor.round()}')),
      ],
    );
  }

  //* borra un color propio al dejarlo presionado
  Future<void> _borrarColor(Color color) async {
    setState(() {
      _coloresPropios.remove(color);
      if (_colorSeleccionado == color) _colorSeleccionado = Colors.red;
    });
    await _guardarColores();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Color eliminado de tu paleta')),
      );
    }
  }

  //* circulo de color que se puede tocar para elegirlo
  Widget _botonColor(Color color, String nombre, {VoidCallback? alBorrar}) {
    final colors = Theme.of(context).colorScheme;
    final seleccionado = _colorSeleccionado == color;
    return Semantics(
      label: nombre,
      button: true,
      selected: seleccionado,
      child: InkResponse(
        onTap: () => setState(() => _colorSeleccionado = color),
        onLongPress: alBorrar,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: seleccionado ? colors.onSurface : colors.outlineVariant,
                width: seleccionado ? 3 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  //* crea (add) o actualiza (update) la criatura en firestore
  //_ si llego una criatura por argumentos es modo editar, si no es crear
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

  //* empieza un trazo nuevo con el color elegido
  //? el punto se divide entre el lado para guardarlo de 0 a 1 y que el dibujo
  //? se vea igual en cualquier tamano de pantalla
  void _iniciarTrazo(Offset punto, double lado) {
    if (_guardando || _trazos.length >= 300) return;
    setState(() {
      _trazos.add(TrazoDibujo(_colorSeleccionado, [punto / lado]));
      _revision++;
    });
  }

  //* agrega puntos al ultimo trazo mientras se arrastra el dedo
  //! fold suma todos los puntos de todos los trazos; se limita a 5000
  //! para que el documento de firestore no pase su tamano maximo
  void _continuarTrazo(Offset punto, double lado) {
    if (_guardando ||
        _trazos.isEmpty ||
        _trazos.fold<int>(0, (total, trazo) => total + trazo.puntos.length) >=
            5000) {
      return;
    }
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
              //? wrap para que los colores bajen de linea cuando son muchos
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < _coloresBase.length; i++)
                    _botonColor(_coloresBase[i], _nombresBase[i]),
                  for (final color in _coloresPropios)
                    _botonColor(
                      color,
                      'Color propio',
                      alBorrar: () => _borrarColor(color),
                    ),
                  //* boton para crear un color nuevo
                  IconButton(
                    tooltip: 'Crear color',
                    onPressed: _guardando ? null : _crearColor,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text(
                'Toca + para crear tu color. Mantén presionado un color propio para quitarlo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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
