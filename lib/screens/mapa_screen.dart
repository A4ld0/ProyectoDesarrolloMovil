import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/criaturas_demo.dart';
import '../data/criaturas_nfc.dart';
import '../data/ubicacion_mapa.dart';

class MapaScreen extends StatelessWidget {
  const MapaScreen({
    required this.controles,
    this.criaturaDestacada,
    this.mapaGeografico,
    super.key,
  });

  final Widget controles;
  final CriaturaDemo? criaturaDestacada;
  final MapaGeografico? mapaGeografico;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minimo = mapaGeografico == null ? 350.0 : 235.0;
            final necesitaScroll = constraints.maxHeight < minimo;
            final mapa = SizedBox(
              width: constraints.maxWidth,
              height: necesitaScroll ? minimo : constraints.maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mapaGeografico == null)
                      Image.asset(
                        'assets/images/mapa_demo.png',
                        fit: BoxFit.cover,
                      )
                    else
                      ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    Column(
                      children: [
                        Expanded(child: mapaGeografico ?? _marcadores(context)),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            mapaGeografico == null ? 0 : 8,
                            12,
                            12,
                          ),
                          child: controles,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            return necesitaScroll || mapaGeografico == null
                ? SingleChildScrollView(child: mapa)
                : mapa;
          },
        ),
      ),
    ),
  );

  Widget _marcadores(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Stack(
      children: [
        for (final (indice, alineacion) in const [
          (0, Alignment(-0.6, -0.5)),
          (1, Alignment(0.6, -0.05)),
          (2, Alignment(-0.35, 0.65)),
        ])
          Align(
            alignment: alineacion,
            child: _MarcadorCriatura(
              criatura: criaturasDemo[indice],
              destacada: criaturasDemo[indice] == criaturaDestacada,
            ),
          ),
        Align(
          alignment: const Alignment(0.15, 0.3),
          child: CircleAvatar(
            backgroundColor: colores.secondary,
            child: Icon(Icons.person, color: colores.onSecondary),
          ),
        ),
      ],
    );
  }
}

class MapaGeografico extends StatefulWidget {
  const MapaGeografico({
    required this.posicion,
    required this.apariciones,
    this.criaturaDestacada,
    super.key,
  });

  final LatLng posicion;
  final List<AparicionCercana> apariciones;
  final CriaturaDemo? criaturaDestacada;

  @override
  State<MapaGeografico> createState() => MapaGeograficoState();
}

class MapaGeograficoState extends State<MapaGeografico> {
  final _camara = MapController();
  bool _lista = false;

  void centrarEn(LatLng punto) {
    if (_lista) _camara.move(punto, 17);
  }

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return FlutterMap(
      mapController: _camara,
      options: MapOptions(
        initialCenter: widget.posicion,
        initialZoom: 17,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: colores.surfaceContainerHighest,
        onMapReady: () => _lista = true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pokemonchafa',
          maxNativeZoom: 19,
          panBuffer: 0,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.posicion,
              width: 38,
              height: 38,
              child: Tooltip(
                message: 'Tu ubicación',
                child: CircleAvatar(
                  backgroundColor: colores.secondary,
                  foregroundColor: colores.onSecondary,
                  child: const Icon(Icons.person, size: 20),
                ),
              ),
            ),
            for (final aparicion in widget.apariciones)
              Marker(
                point: aparicion.punto,
                width: 120,
                height: 80,
                child: Center(
                  child: _MarcadorCriatura(
                    criatura: aparicion.criatura,
                    destacada: aparicion.criatura == widget.criaturaDestacada,
                    compacto: true,
                  ),
                ),
              ),
          ],
        ),
        SimpleAttributionWidget(
          source: const Text('OpenStreetMap contributors'),
          onTap: () =>
              launchUrl(Uri.https('www.openstreetmap.org', '/copyright')),
        ),
      ],
    );
  }
}

class _MarcadorCriatura extends StatelessWidget {
  const _MarcadorCriatura({
    required this.criatura,
    required this.destacada,
    this.compacto = false,
  });

  final CriaturaDemo criatura;
  final bool destacada;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final borde = BorderRadius.circular(20);
    final recibida =
        context.watch<CriaturasNfc?>()?.pendiente(criatura) ?? false;
    return Semantics(
      button: true,
      selected: destacada,
      child: Material(
        elevation: destacada ? 4 : 1,
        color: destacada ? colores.primary : colores.surface,
        borderRadius: borde,
        child: InkWell(
          borderRadius: borde,
          onTap: () =>
              Navigator.pushNamed(context, '/encuentro', arguments: criatura),
          child: Padding(
            padding: EdgeInsets.all(compacto ? 6 : 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: recibida,
                  backgroundColor: colores.tertiary,
                  label: Semantics(
                    label: 'Recibida por NFC',
                    child: Icon(Icons.nfc, size: 12, color: colores.onTertiary),
                  ),
                  child: Icon(
                    criatura.icono,
                    size: compacto ? 24 : 36,
                    color: destacada ? colores.onPrimary : colores.primary,
                  ),
                ),
                Text(
                  criatura.nombre,
                  style: TextStyle(
                    color: destacada ? colores.onPrimary : colores.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
