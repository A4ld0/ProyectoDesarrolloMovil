import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokemonchafa/data/ubicacion_mapa.dart';
import 'package:pokemonchafa/screens/main_navigation.dart';

class _GpsDePruebas extends GeolocatorPlatform {
  final posiciones = StreamController<Position>.broadcast();
  final estados = StreamController<ServiceStatus>.broadcast();
  var permiso = LocationPermission.whileInUse;
  var permisoSolicitado = LocationPermission.denied;
  var activo = true;
  var solicitudes = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => activo;

  @override
  Future<LocationPermission> checkPermission() async => permiso;

  @override
  Future<LocationPermission> requestPermission() async {
    solicitudes++;
    return permiso = permisoSolicitado;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      posiciones.stream;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => estados.stream;

  void moverA(LatLng punto) => posiciones.add(
    Position(
      longitude: punto.longitude,
      latitude: punto.latitude,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
  );
}

void main() {
  late _GpsDePruebas gps;
  late GeolocatorPlatform gpsOriginal;

  setUp(() {
    gpsOriginal = GeolocatorPlatform.instance;
    gps = _GpsDePruebas();
    GeolocatorPlatform.instance = gps;
  });

  tearDown(() async {
    GeolocatorPlatform.instance = gpsOriginal;
    await gps.posiciones.close();
    await gps.estados.close();
  });

  testWidgets('Al caminar cambian las distancias con las criaturas fijas', (
    tester,
  ) async {
    final mapa = UbicacionMapa();
    addTearDown(mapa.dispose);
    await mapa.activar();
    const inicio = LatLng(19.4326, -99.1332);
    gps.moverA(inicio);
    await tester.pump();

    expect(mapa.posicion, inicio);
    final ubicacionesOriginales = mapa.apariciones;
    expect(ubicacionesOriginales, hasLength(3));
    final cercanas = mapa.cercanas;
    expect(cercanas.map((ejemplar) => ejemplar.metros), [80, 115, 145]);

    gps.moverA(ubicacionesOriginales.last.punto);
    await tester.pump();
    expect(mapa.apariciones, same(ubicacionesOriginales));
    expect(mapa.cercanas.first.criatura.nombre, 'Estelin');
    expect(mapa.cercanas.first.metros, 0);
  });

  testWidgets('El seguimiento se pausa y al volver conserva las coordenadas', (
    tester,
  ) async {
    final mapa = UbicacionMapa();
    addTearDown(mapa.dispose);
    await mapa.activar();
    const inicio = LatLng(19.4326, -99.1332);
    gps.moverA(inicio);
    await tester.pump();
    final apariciones = mapa.apariciones;

    mapa.pausar();
    expect(gps.posiciones.hasListener, isFalse);
    expect(gps.estados.hasListener, isFalse);
    mapa.reanudar();
    await tester.pump();
    expect(gps.posiciones.hasListener, isTrue);
    expect(gps.solicitudes, 0);
    gps.moverA(const LatLng(19.4330, -99.1332));
    await tester.pump();
    expect(mapa.apariciones, same(apariciones));

    gps.estados.add(ServiceStatus.disabled);
    await tester.pump();
    expect(mapa.posicion, isNull);
    expect(mapa.problema, ProblemaUbicacion.gpsApagado);
    expect(gps.posiciones.hasListener, isFalse);
  });

  testWidgets('El mapa de demostración funciona si se deniega el permiso', (
    tester,
  ) async {
    gps.permiso = LocationPermission.denied;
    await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
    expect(gps.solicitudes, 0);

    await tester.tap(find.text('Usar mi ubicación'));
    await tester.pumpAndSettle();
    expect(gps.solicitudes, 1);
    expect(find.text('Permiso de ubicación denegado.'), findsOneWidget);
    expect(find.text('Nubin'), findsOneWidget);
    expect(gps.posiciones.hasListener, isFalse);
  });

  testWidgets('Se puede reintentar tras no recibir la primera posición', (
    tester,
  ) async {
    final mapa = UbicacionMapa();
    addTearDown(mapa.dispose);
    await mapa.activar();
    expect(mapa.esperando, isTrue);
    await tester.pump(const Duration(seconds: 20));
    expect(mapa.problema, ProblemaUbicacion.sinPosicion);
    expect(mapa.esperando, isFalse);
    await mapa.activar();
    gps.moverA(const LatLng(19.4326, -99.1332));
    await tester.pump();
    expect(mapa.posicion, isNotNull);
    expect(mapa.problema, isNull);
  });
}
