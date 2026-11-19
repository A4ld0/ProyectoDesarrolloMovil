import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../models/criatura.dart';
import '../data/datos_app.dart';
import '../data/ubicacion_mapa.dart';
import 'mapa_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final _ubicacion = UbicacionMapa();
  final _mapaGeografico = GlobalKey<MapaGeograficoState>();
  late final AppLifecycleListener _cicloDeVida;
  Criatura? _criaturaDestacada;

  @override
  void initState() {
    super.initState();
    _cicloDeVida = AppLifecycleListener(
      onResume: _ubicacion.reanudar,
      onHide: _ubicacion.pausar,
      onDetach: _ubicacion.pausar,
    );
  }

  @override
  void dispose() {
    _cicloDeVida.dispose();
    _ubicacion.dispose();
    super.dispose();
  }

  Future<T?> _elegirEnPanel<T>(
    String titulo,
    List<Widget> Function(BuildContext) opciones,
  ) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) => SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _refrescar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...opciones(context),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _refrescar() async {
    try {
      await context.read<DatosApp>().refrescar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar. Revisa tu conexión.'),
          ),
        );
      }
    }
  }

  Future<void> _abrirMenu() async {
    final ruta = await _elegirEnPanel<String>(
      'Menú',
      (context) => [
        for (final (titulo, icono, ruta) in const [
          ('Guía', Icons.menu_book_outlined, '/guia'),
          ('Colección', Icons.inventory_2_outlined, '/coleccion'),
          ('Creaciones', Icons.brush_outlined, '/creaciones'),
          ('Amigos', Icons.people_outline, '/amigos'),
        ])
          ListTile(
            leading: Icon(icono),
            title: Text(titulo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, ruta),
          ),
      ],
    );
    if (ruta != null && mounted) Navigator.pushNamed(context, ruta);
  }

  Future<void> _abrirCercanas() async {
    final datos = context.read<DatosApp>();
    final criatura = await _elegirEnPanel<Criatura>(
      'Cerca de ti',
      (context) => [
        ListenableBuilder(
          listenable: Listenable.merge([_ubicacion, datos]),
          builder: (context, _) => Column(
            children: [
              for (final (criatura: criatura, metros: metros) in _cercanas(
                datos,
              ))
                ListTile(
                  leading: Icon(criatura.icono),
                  title: Text(criatura.nombre),
                  subtitle: Text(
                    metros == null
                        ? 'Tipo ${criatura.tipo}'
                        : 'Tipo ${criatura.tipo} · ≈ ${_mostrarDistancia(metros)}',
                  ),
                  selected: criatura.id == _criaturaDestacada?.id,
                  trailing: criatura.id == _criaturaDestacada?.id
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, criatura),
                ),
            ],
          ),
        ),
      ],
    );
    if (criatura != null && mounted) {
      setState(() => _criaturaDestacada = criatura);
      for (final aparicion in _apariciones(datos)) {
        if (aparicion.criatura.id == criatura.id) {
          _mapaGeografico.currentState?.centrarEn(aparicion.punto);
          break;
        }
      }
    }
  }

  String _mostrarDistancia(double metros) => metros < 1000
      ? '${metros.round()} m'
      : '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  List<AparicionCercana> _apariciones(DatosApp datos) => [
    for (final criatura in datos.catalogo)
      if (datos.puntos[criatura.id] != null &&
          !datos.estaCapturada(criatura.id))
        (criatura: criatura, punto: datos.puntos[criatura.id]!),
  ];

  List<({Criatura criatura, double? metros})> _cercanas(DatosApp datos) {
    final posicion = _ubicacion.posicion;
    final cercanas = [
      for (final criatura in datos.catalogo)
        if (!datos.estaCapturada(criatura.id))
          (
            criatura: criatura,
            metros: posicion != null && datos.puntos[criatura.id] != null
                ? const Distance()(posicion, datos.puntos[criatura.id]!)
                : null,
          ),
    ];
    cercanas.sort(
      (a, b) =>
          (a.metros ?? double.infinity).compareTo(b.metros ?? double.infinity),
    );
    return cercanas;
  }

  Future<void> _abrirAjustesDeUbicacion() async {
    if (!await _ubicacion.abrirAjustes() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre los ajustes de ubicación del dispositivo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _ubicacion,
    builder: (context, _) {
      final datos = context.watch<DatosApp>();
      final posicion = _ubicacion.posicion;
      if (posicion != null &&
          datos.catalogo.any(
            (criatura) => !datos.puntos.containsKey(criatura.id),
          )) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          try {
            await datos.colocarCerca(posicion);
          } catch (_) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se pudieron cargar las apariciones del mapa.',
                  ),
                ),
              );
          }
        });
      }
      final problema = _ubicacion.problema;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa'),
          actions: [
            if (posicion != null)
              IconButton(
                tooltip: 'Volver a mi ubicación',
                icon: const Icon(Icons.my_location),
                onPressed: () =>
                    _mapaGeografico.currentState?.centrarEn(posicion),
              )
            else if (_ubicacion.esperando)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Buscando tu ubicación',
                  ),
                ),
              )
            else if (UbicacionMapa.disponible)
              TextButton(
                onPressed: () => _ubicacion.activar(),
                child: const Text('Usar mi ubicación'),
              ),
          ],
        ),
        body: Column(
          children: [
            if (problema != null)
              _AvisoUbicacion(
                problema: problema,
                abrirAjustes: _abrirAjustesDeUbicacion,
              ),
            Expanded(
              child: MapaScreen(
                criaturaDestacada: _criaturaDestacada,
                mapaGeografico: posicion == null
                    ? null
                    : MapaGeografico(
                        key: _mapaGeografico,
                        posicion: posicion,
                        apariciones: _apariciones(datos),
                        criaturaDestacada: _criaturaDestacada,
                      ),
                controles: _controles(),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _controles() => Row(
    spacing: 8,
    children: [
      Expanded(
        child: _ControlMapa(
          titulo: 'Perfil',
          icono: Icons.person_outline,
          onPressed: () => Navigator.pushNamed(context, '/perfil'),
        ),
      ),
      Expanded(
        child: _ControlMapa(
          titulo: 'Menú',
          icono: Icons.grid_view_rounded,
          onPressed: _abrirMenu,
          principal: true,
        ),
      ),
      Expanded(
        child: _ControlMapa(
          titulo: 'Cerca de ti',
          icono: Icons.radar,
          onPressed: _abrirCercanas,
        ),
      ),
    ],
  );
}

class _AvisoUbicacion extends StatelessWidget {
  const _AvisoUbicacion({required this.problema, required this.abrirAjustes});

  final ProblemaUbicacion problema;
  final VoidCallback abrirAjustes;

  @override
  Widget build(BuildContext context) {
    final (mensaje, mostrarAjustes) = switch (problema) {
      ProblemaUbicacion.gpsApagado => (
        'Activa la ubicación del dispositivo.',
        true,
      ),
      ProblemaUbicacion.permisoDenegado => (
        'Permiso de ubicación denegado.',
        false,
      ),
      ProblemaUbicacion.permisoBloqueado => (
        'Permite la ubicación en los ajustes de la app.',
        true,
      ),
      ProblemaUbicacion.sinPosicion => (
        'No se pudo obtener tu ubicación. Inténtalo de nuevo.',
        false,
      ),
    };
    return ListTile(
      leading: const Icon(Icons.location_off_outlined),
      title: Text(mensaje),
      subtitle: const Text('Puedes consultar las criaturas desde el menú.'),
      trailing: mostrarAjustes
          ? TextButton(onPressed: abrirAjustes, child: const Text('Ajustes'))
          : null,
    );
  }
}

class _ControlMapa extends StatelessWidget {
  const _ControlMapa({
    required this.titulo,
    required this.icono,
    required this.onPressed,
    this.principal = false,
  });

  final String titulo;
  final IconData icono;
  final VoidCallback onPressed;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: principal ? colores.primary : colores.surface,
        foregroundColor: principal ? colores.onPrimary : colores.onSurface,
        minimumSize: const Size(0, 64),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(icono, size: 22),
          Text(titulo, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
