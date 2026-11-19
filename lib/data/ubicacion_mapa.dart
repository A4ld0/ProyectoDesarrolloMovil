import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'criaturas_demo.dart';

typedef AparicionCercana = ({CriaturaDemo criatura, LatLng punto});

enum ProblemaUbicacion {
  gpsApagado,
  permisoDenegado,
  permisoBloqueado,
  sinPosicion,
}

class UbicacionMapa extends ChangeNotifier {
  static bool get disponible =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _distancia = Distance(calculator: Haversine());
  static const _ajustes = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
  static final _ajustesAndroid = AndroidSettings(
    forceLocationManager: true,
    accuracy: _ajustes.accuracy,
    distanceFilter: _ajustes.distanceFilter,
  );

  StreamSubscription<Position>? _seguimiento;
  StreamSubscription<ServiceStatus>? _estadoServicio;
  Timer? _esperaInicial;
  bool _activando = false;
  bool _visible = true;
  bool _revisarAlVolver = false;
  bool _cerrado = false;
  LatLng? _posicion;
  List<AparicionCercana> _apariciones = const [];
  ProblemaUbicacion? _problema;

  LatLng? get posicion => _posicion;
  List<AparicionCercana> get apariciones => _apariciones;
  ProblemaUbicacion? get problema => _problema;
  bool get esperando => _activando || _esperaInicial != null;

  List<({CriaturaDemo criatura, double? metros})> get cercanas {
    final posicion = _posicion;
    if (posicion == null) {
      return [
        for (final criatura in criaturasDemo)
          (criatura: criatura, metros: null),
      ];
    }
    return <({CriaturaDemo criatura, double metros})>[
      for (final aparicion in _apariciones)
        (
          criatura: aparicion.criatura,
          metros: _distancia(posicion, aparicion.punto),
        ),
    ]..sort((a, b) => a.metros.compareTo(b.metros));
  }

  Future<void> activar({bool solicitarPermiso = true}) async {
    if (_cerrado || !_visible || _activando || _seguimiento != null) return;

    final yaBloqueado = _problema == ProblemaUbicacion.permisoBloqueado;
    _activando = true;
    _problema = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fallar(ProblemaUbicacion.gpsApagado);
        return;
      }
      if (_cerrado || !_visible) return;

      var permiso = await Geolocator.checkPermission();
      if (_cerrado || !_visible) return;
      if (permiso == LocationPermission.denied && solicitarPermiso) {
        permiso = await Geolocator.requestPermission();
      }
      if (_cerrado) return;

      switch (permiso) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          _revisarAlVolver = true;
          if (_visible) _iniciarSeguimiento();
        case LocationPermission.deniedForever:
          _fallar(ProblemaUbicacion.permisoBloqueado);
        default:
          _fallar(
            yaBloqueado && !solicitarPermiso
                ? ProblemaUbicacion.permisoBloqueado
                : ProblemaUbicacion.permisoDenegado,
          );
      }
    } catch (error) {
      _errorDeLectura(error);
    } finally {
      _activando = false;
      if (!_cerrado) notifyListeners();
    }
  }

  void _iniciarSeguimiento() {
    _esperaInicial = Timer(
      const Duration(seconds: 20),
      () => _fallar(ProblemaUbicacion.sinPosicion),
    );
    final ajustes = defaultTargetPlatform == TargetPlatform.android
        ? _ajustesAndroid
        : _ajustes;
    _seguimiento = Geolocator.getPositionStream(locationSettings: ajustes)
        .listen(
          _actualizarPosicion,
          onError: _errorDeLectura,
          onDone: () => _fallar(ProblemaUbicacion.sinPosicion),
        );
    _estadoServicio = Geolocator.getServiceStatusStream().listen((estado) {
      if (estado == ServiceStatus.disabled) {
        _fallar(ProblemaUbicacion.gpsApagado);
      }
    }, onError: _errorDeLectura);
  }

  void _actualizarPosicion(Position lectura) {
    if (_cerrado || !_visible) return;
    _esperaInicial?.cancel();
    _esperaInicial = null;
    final punto = LatLng(lectura.latitude, lectura.longitude);
    _posicion = punto;
    if (_apariciones.isEmpty) {
      _apariciones = List.unmodifiable([
        for (final (indice, metros, rumbo) in const [
          (0, 80.0, -45.0),
          (1, 115.0, 70.0),
          (2, 145.0, -165.0),
        ])
          (
            criatura: criaturasDemo[indice],
            punto: _desplazar(punto, metros, rumbo),
          ),
      ]);
    }
    notifyListeners();
  }

  LatLng _desplazar(LatLng origen, double metros, double rumbo) {
    final punto = _distancia.offset(origen, metros, rumbo);
    return LatLng(punto.latitude, (punto.longitude + 180) % 360 - 180);
  }

  void _errorDeLectura(Object error) => _fallar(switch (error) {
    LocationServiceDisabledException() => ProblemaUbicacion.gpsApagado,
    PermissionDeniedException() => ProblemaUbicacion.permisoDenegado,
    _ => ProblemaUbicacion.sinPosicion,
  });

  void _fallar(ProblemaUbicacion problema) {
    if (_cerrado) return;
    _detenerSeguimiento();
    _posicion = null;
    _problema = problema;
    notifyListeners();
  }

  Future<bool> abrirAjustes() async {
    _revisarAlVolver = true;
    try {
      return _problema == ProblemaUbicacion.gpsApagado
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  void pausar() {
    _visible = false;
    _detenerSeguimiento();
  }

  void reanudar() {
    _visible = true;
    if (_revisarAlVolver) unawaited(activar(solicitarPermiso: false));
  }

  void _detenerSeguimiento() {
    _esperaInicial?.cancel();
    _esperaInicial = null;
    unawaited(_seguimiento?.cancel());
    _seguimiento = null;
    unawaited(_estadoServicio?.cancel());
    _estadoServicio = null;
  }

  @override
  void dispose() {
    _cerrado = true;
    _detenerSeguimiento();
    super.dispose();
  }
}
