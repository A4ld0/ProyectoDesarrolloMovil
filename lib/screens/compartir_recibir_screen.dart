import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/criatura.dart';
import '../data/datos_app.dart';
import '../data/intercambio_nfc.dart';
import '../widgets/dibujo_criatura.dart';
import '../widgets/recarga_firebase.dart';

enum _Modo { compartir, recibir }

class CompartirRecibirScreen extends StatefulWidget {
  const CompartirRecibirScreen({super.key});

  @override
  State<CompartirRecibirScreen> createState() => _CompartirRecibirScreenState();
}

class _CompartirRecibirScreenState extends State<CompartirRecibirScreen>
    with SingleTickerProviderStateMixin {
  final _intercambio = IntercambioNfc();
  late final TabController _pestanas;
  late final AppLifecycleListener _cicloDeVida;
  _Modo? _activo;
  _Modo? _modoDelMensaje;
  String? _mensaje;
  Criatura? _recibida;
  String? _seleccionId;

  @override
  void initState() {
    super.initState();
    _pestanas = TabController(length: _Modo.values.length, vsync: this)
      ..addListener(_alCambiarPestana);
    _cicloDeVida = AppLifecycleListener(onHide: _cancelar, onDetach: _cancelar);
  }

  void _alCambiarPestana() {
    final activo = _activo;
    if (activo != null && activo.index != _pestanas.index) _cancelar();
  }

  void _cancelar() => unawaited(_intercambio.cancelar());

  @override
  void dispose() {
    _cicloDeVida.dispose();
    _pestanas.dispose();
    _cancelar();
    super.dispose();
  }

  Future<void> _iniciar(_Modo modo, Criatura? seleccion) async {
    if (_activo != null) return;
    final almacen = context.read<DatosApp>();
    setState(() {
      _activo = modo;
      _mensaje = null;
      if (modo == _Modo.recibir) _recibida = null;
    });

    String? mensaje;
    Criatura? recibida;
    try {
      if (modo == _Modo.compartir) {
        if (seleccion == null) return;
        if (await _intercambio.compartir(seleccion)) {
          mensaje = '${seleccion.nombre} se envió correctamente.';
        }
      } else {
        recibida = await _intercambio.recibir(almacen.recibir, almacen.buscar);
        if (recibida != null) {
          mensaje = almacen.pendiente(recibida.id)
              ? '${recibida.nombre} llegó a tu mapa. Puedes capturarla allí.'
              : '${recibida.nombre} ya está en tu colección.';
        }
      }
    } on ErrorIntercambioNfc catch (error) {
      mensaje = error.mensaje;
    } on MissingPluginException {
      mensaje = IntercambioNfc.mensajeSinNfc;
    } on PlatformException {
      mensaje =
          'No se pudo iniciar el intercambio por NFC. Inténtalo de nuevo.';
    } catch (_) {
      mensaje = 'No se pudo consultar la criatura. Revisa tu conexión.';
    } finally {
      if (mounted) {
        setState(() {
          _activo = null;
          _modoDelMensaje = modo;
          _mensaje = mensaje;
          if (modo == _Modo.recibir) _recibida = recibida;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)?.settings.arguments;
    final datos = context.watch<DatosApp>();
    final id = _seleccionId ?? (argumento is Criatura ? argumento.id : null);
    final criatura = id == null
        ? (datos.catalogo.isEmpty ? null : datos.catalogo.first)
        : datos.porId(id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir y recibir'),
        bottom: TabBar(
          controller: _pestanas,
          tabs: const [
            Tab(text: 'Compartir', icon: Icon(Icons.ios_share)),
            Tab(text: 'Recibir', icon: Icon(Icons.move_to_inbox_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _pestanas,
        children: [
          _panel(_Modo.compartir, criatura),
          _panel(_Modo.recibir, criatura),
        ],
      ),
    );
  }

  Widget _panel(_Modo modo, Criatura? seleccion) {
    final comparte = modo == _Modo.compartir;
    final criatura = comparte ? seleccion : _recibida;
    final sigueEnMapa = criatura == null || comparte
        ? false
        : context.watch<DatosApp>().pendiente(criatura.id);
    final colores = Theme.of(context).colorScheme;
    final esperando = _activo == modo;
    final mensaje = _modoDelMensaje == modo ? _mensaje : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: RecargaFirebase(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                comparte ? 'Comparte tu criatura' : 'Recibe una criatura',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (comparte &&
                  context.watch<DatosApp>().catalogo.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey(seleccion?.id),
                  initialValue: seleccion?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Criatura',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final opcion in context.watch<DatosApp>().catalogo)
                      DropdownMenuItem(
                        value: opcion.id,
                        child: Text(
                          opcion.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _activo != null
                      ? null
                      : (id) => setState(() => _seleccionId = id),
                ),
                const SizedBox(height: 12),
              ],
              if (criatura != null)
                Card(
                  color: colores.primaryContainer,
                  child: ListTile(
                    leading: DibujoCriatura(criatura: criatura, tamano: 40),
                    title: Text(criatura.nombre),
                    subtitle: Text('Tipo ${criatura.tipo}'),
                  ),
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.nfc),
                title: const Text('Intercambio NFC'),
                subtitle: Text(
                  comparte
                      ? 'En el otro Android, abre Recibir y toca Buscar criatura.'
                      : 'En el otro Android, abre Compartir y toca Empezar a compartir.',
                ),
              ),
              const Text(
                'Ambos teléfonos necesitan conexión para cargar y guardar la criatura.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.nfc),
                label: Text(
                  comparte ? 'Empezar a compartir' : 'Buscar criatura',
                ),
                onPressed: _activo == null && (!comparte || seleccion != null)
                    ? () => _iniciar(modo, seleccion)
                    : null,
              ),
              if (esperando) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Mantén ambos teléfonos desbloqueados y acerca la parte trasera.',
                  style: TextStyle(color: colores.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: _cancelar,
                  child: const Text('Cancelar intercambio'),
                ),
              ],
              if (mensaje != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(mensaje)),
                ),
              if (!comparte && criatura != null && mensaje != null)
                OutlinedButton.icon(
                  icon: Icon(
                    sigueEnMapa
                        ? Icons.map_outlined
                        : Icons.inventory_2_outlined,
                  ),
                  label: Text(sigueEnMapa ? 'Volver al mapa' : 'Ver colección'),
                  onPressed: () {
                    final navegador = Navigator.of(context);
                    navegador.popUntil(
                      (route) =>
                          route.settings.name == '/mapa' || route.isFirst,
                    );
                    if (!sigueEnMapa) navegador.pushNamed('/coleccion');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
