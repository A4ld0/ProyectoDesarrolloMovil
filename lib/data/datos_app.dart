import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/criatura.dart';
import '../models/amistad.dart';

class DatosApp extends ChangeNotifier {
  DatosApp({
    FirebaseAuth? auth,
    FirebaseFirestore? base,
    this.registrarDispositivo = true,
  }) : auth = auth ?? FirebaseAuth.instance,
       base = base ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore base;
  final bool registrarDispositivo;
  User? usuario;
  bool cargando = false;
  String? error;
  String? avisoToken;
  bool hayCapturasLocales = false;
  Map<String, dynamic> perfil = {};
  List<Criatura> _propias = [];
  List<Amistad> amistades = [];
  Map<String, String> nombresAmigos = {};

  List<Criatura> get catalogo {
    final visibles = <String, Criatura>{
      for (final captura in _capturas.entries)
        captura.key: Criatura.fromMap(
          captura.key,
          Map<String, dynamic>.from(captura.value['criatura'] as Map),
        ),
      for (final criatura in _propias) criatura.id: criatura,
    };
    return visibles.values.toList()..sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
  }

  List<Amistad> get amigos =>
      amistades.where((amistad) => amistad.aceptada).toList();
  List<Amistad> get solicitudesRecibidas => amistades
      .where(
        (amistad) => !amistad.aceptada && amistad.receptorId == usuario?.uid,
      )
      .toList();
  List<Amistad> get solicitudesEnviadas => amistades
      .where((amistad) => !amistad.aceptada && amistad.emisorId == usuario?.uid)
      .toList();
  Map<String, Map<String, dynamic>> _capturas = {};
  Map<String, LatLng> puntos = {};
  StreamSubscription<User?>? _sesion;
  StreamSubscription<String>? _token;
  final List<StreamSubscription<dynamic>> _escuchas = [];
  int _generacion = 0;
  bool _cerrado = false;
  bool _colocando = false;
  String? _tokenActual;
  String? _duenoToken;

  CollectionReference<Map<String, dynamic>> get criaturas =>
      base.collection('criaturas');
  DocumentReference<Map<String, dynamic>> _cuenta(String uid) =>
      base.collection('usuarios').doc(uid);
  String get _uid =>
      usuario?.uid ?? (throw StateError('Inicia sesión para continuar.'));
  List<Criatura> get creaciones => List.unmodifiable(_propias);
  List<Criatura> get capturadas => [
    for (final entrada in _capturas.entries)
      if (entrada.value['estado'] == 'capturada')
        porId(entrada.key) ??
            Criatura.fromMap(
              entrada.key,
              Map<String, dynamic>.from(entrada.value['criatura'] as Map),
            ),
  ];
  bool estaCapturada(String id) => _capturas[id]?['estado'] == 'capturada';
  bool recibida(String id) => _capturas[id]?['origen'] == 'nfc';
  bool pendiente(String id) => recibida(id) && !estaCapturada(id);
  Criatura? porId(String id) {
    for (final criatura in catalogo) {
      if (criatura.id == id) return criatura;
    }
    return null;
  }

  void iniciar() {
    usuario = auth.currentUser;
    cargando = usuario != null;
    _sesion = auth.authStateChanges().listen(
      (user) => unawaited(abrirSesion(user)),
    );
  }

  Future<void> abrirSesion(User? user) async {
    final generacion = ++_generacion;
    for (final escucha in _escuchas) {
      unawaited(escucha.cancel());
    }
    _escuchas.clear();
    unawaited(_token?.cancel());
    usuario = user;
    _propias = [];
    amistades = [];
    nombresAmigos = {};
    _capturas = {};
    puntos = {};
    perfil = {};
    error = null;
    avisoToken = null;
    cargando = user != null;
    _avisar();
    if (user == null) return;
    try {
      hayCapturasLocales =
          await SharedPreferencesAsync().getString('criaturasNfc') != null;
      final cuenta = _cuenta(user.uid);
      await base.runTransaction((transaccion) async {
        final actual = await transaccion.get(cuenta);
        transaccion.set(cuenta, {
          'uid': user.uid,
          'correo': user.email ?? '',
          if (!actual.exists) ...{
            'nombre': user.displayName ?? '',
            'creadoEn': FieldValue.serverTimestamp(),
            'sonidos': true,
          },
          'ultimoAcceso': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (generacion != _generacion || _cerrado) return;
      await refrescar();
      if (generacion != _generacion || _cerrado) return;
      await base.runTransaction((transaccion) async {
        final ficha = await transaccion.get(cuenta);
        transaccion.set(base.collection('perfilesPublicos').doc(user.uid), {
          'uid': user.uid,
          'nombre': ficha.data()?['nombre'] as String? ?? '',
        });
      });
      if (generacion != _generacion || _cerrado) return;
      void escuchar<T>(Stream<T> flujo, void Function(T) aplicar) {
        _escuchas.add(
          flujo.listen(
            (datos) {
              if (generacion != _generacion || _cerrado) return;
              aplicar(datos);
              _avisar();
            },
            onError: (Object _) {
              if (generacion == _generacion && !_cerrado) {
                error =
                    'No se pudieron actualizar los datos. Revisa tu conexión.';
                _avisar();
              }
            },
          ),
        );
      }

      escuchar(
        criaturas.where('creadorId', isEqualTo: user.uid).snapshots(),
        _leerCatalogo,
      );
      escuchar(cuenta.snapshots(), (datos) => perfil = datos.data() ?? {});
      escuchar(cuenta.collection('capturas').snapshots(), _leerCapturas);
      escuchar(cuenta.collection('apariciones').snapshots(), _leerPuntos);
      escuchar(_relaciones(user.uid).snapshots(), (datos) {
        _leerAmistades(datos);
        unawaited(
          _cargarNombresAmigos(user.uid, generacion).catchError((Object _) {
            if (generacion == _generacion && !_cerrado) {
              error = 'No se pudieron actualizar los nombres de tus amigos. Desliza para reintentar.';
              _avisar();
            }
          }),
        );
      });
      cargando = false;
      _avisar();
      unawaited(actualizarToken());
    } catch (_) {
      if (generacion == _generacion && !_cerrado) {
        cargando = false;
        error = 'No se pudieron cargar tus datos. Revisa tu conexión y vuelve a intentar.';
        _avisar();
      }
    }
  }

  void _leerCatalogo(QuerySnapshot<Map<String, dynamic>> datos) {
    _propias =
        datos.docs.map((doc) => Criatura.fromMap(doc.id, doc.data())).toList()
          ..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
  }

  void _leerCapturas(QuerySnapshot<Map<String, dynamic>> datos) {
    _capturas = {for (final doc in datos.docs) doc.id: doc.data()};
  }

  void _leerPuntos(QuerySnapshot<Map<String, dynamic>> datos) {
    puntos = {
      for (final doc in datos.docs)
        doc.id: LatLng(
          (doc.data()['latitud'] as num).toDouble(),
          (doc.data()['longitud'] as num).toDouble(),
        ),
    };
  }

  Future<void> refrescar() async {
    final uid = _uid;
    final generacion = _generacion;
    final cuenta = _cuenta(uid);
    const servidor = GetOptions(source: Source.server);
    final resultados = await Future.wait([
      criaturas.where('creadorId', isEqualTo: uid).get(servidor),
      cuenta.collection('capturas').get(servidor),
      cuenta.collection('apariciones').get(servidor),
      _relaciones(uid).get(servidor),
    ]);
    final ficha = await cuenta.get(servidor);
    if (_cerrado || generacion != _generacion) return;
    _leerCatalogo(resultados[0]);
    _leerCapturas(resultados[1]);
    _leerPuntos(resultados[2]);
    _leerAmistades(resultados[3]);
    await _cargarNombresAmigos(uid, generacion);
    if (_cerrado || generacion != _generacion) return;
    perfil = ficha.data() ?? {};
    error = null;
    _avisar();
  }

  Future<Criatura?> buscar(String id) async {
    final doc = await criaturas
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? Criatura.fromMap(doc.id, doc.data()!) : null;
  }

  Future<void> guardar(Criatura criatura, {bool nueva = false}) async {
    final uid = _uid;
    final referencia = criaturas.doc(criatura.id);
    await base.runTransaction((transaccion) async {
      final existente = await transaccion.get(referencia);
      if (nueva &&
          existente.exists &&
          existente.data()!['creadorId'] == uid &&
          jsonEncode(
                Criatura.fromMap(criatura.id, existente.data()!).toMap(),
              ) ==
              jsonEncode(criatura.toMap())) {
        return;
      }
      if (nueva && existente.exists || !nueva && !existente.exists) {
        throw StateError('La criatura cambió. Actualiza la lista.');
      }
      if (existente.exists &&
          (existente.data()!['creadorId'] != uid ||
              existente.data()!['version'] != criatura.version)) {
        throw StateError(
          'La criatura cambió en otro dispositivo. Ábrela de nuevo.',
        );
      }
      transaccion.set(referencia, {
        ...criatura.toMap(),
        'creadorId': uid,
        'version': nueva ? 1 : criatura.version + 1,
        if (nueva) 'creadaEn': FieldValue.serverTimestamp(),
        'actualizadaEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await _refrescarTrasEscritura(uid);
  }

  Future<void> eliminar(Criatura criatura) async {
    final uid = _uid;
    final referencia = criaturas.doc(criatura.id);
    await base.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);
      if (!actual.exists) return;
      if (actual.data()!['creadorId'] != uid)
        throw StateError('Solo puedes eliminar tus criaturas.');
      transaccion.delete(referencia);
    });
    await _refrescarTrasEscritura(uid);
  }

  Future<void> recibir(Criatura criatura) =>
      _guardarCaptura(criatura, capturar: false);
  Future<void> capturar(Criatura criatura) =>
      _guardarCaptura(criatura, capturar: true);

  Future<void> _guardarCaptura(
    Criatura criatura, {
    required bool capturar,
  }) async {
    final uid = _uid;
    final referencia = _cuenta(uid).collection('capturas').doc(criatura.id);
    await base.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);
      if (actual.data()?['estado'] == 'capturada') return;
      transaccion.set(referencia, {
        'estado': capturar ? 'capturada' : 'recibida',
        'origen': actual.data()?['origen'] ?? (capturar ? 'mapa' : 'nfc'),
        'criatura': criatura.toMap(),
        'actualizadaEn': FieldValue.serverTimestamp(),
      });
    });
    await _refrescarTrasEscritura(uid);
    if (capturar && perfil['sonidos'] == true)
      unawaited(SystemSound.play(SystemSoundType.click));
  }

  Future<void> colocarCerca(LatLng posicion) async {
    if (_colocando || usuario == null) return;
    final faltantes = catalogo.where((c) => !puntos.containsKey(c.id)).toList();
    if (faltantes.isEmpty) return;
    final uid = _uid;
    _colocando = true;
    try {
      const distancia = Distance();
      // El mapa genera avistamientos del juego y conserva sus coordenadas en Firebase.
      for (final criatura in faltantes) {
        final semilla = criatura.id.codeUnits.fold(
          0,
          (suma, letra) => suma + letra,
        );
        final punto = distancia.offset(
          posicion,
          60.0 + semilla % 120,
          (semilla % 360).toDouble(),
        );
        final doc = _cuenta(uid).collection('apariciones').doc(criatura.id);
        await base.runTransaction((transaccion) async {
          if (!(await transaccion.get(doc)).exists) {
            transaccion.set(doc, {
              'latitud': punto.latitude,
              'longitud': punto.longitude,
            });
          }
        });
      }
      if (usuario?.uid == uid) await refrescar();
    } finally {
      _colocando = false;
    }
  }

  Future<void> guardarPerfil({required String nombre}) async {
    final uid = _uid;
    final lote = base.batch();
    lote.update(_cuenta(uid), {'nombre': nombre.trim()});
    lote.set(base.collection('perfilesPublicos').doc(uid), {
      'uid': uid,
      'nombre': nombre.trim(),
    });
    await lote.commit();
    await _refrescarTrasEscritura(uid);
  }

  Future<void> registrar({
    required String correo,
    required String contrasena,
    required String nombre,
  }) async {
    final credencial = await auth.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    final user = credencial.user!;
    await user.updateDisplayName(nombre);
    final lote = base.batch();
    lote.set(_cuenta(user.uid), {
      'uid': user.uid,
      'correo': correo,
      'nombre': nombre,
      'sonidos': true,
      'creadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    lote.set(base.collection('perfilesPublicos').doc(user.uid), {
      'uid': user.uid,
      'nombre': nombre,
    });
    await lote.commit();
  }

  Future<void> cambiarSonidos(bool valor) async {
    final uid = _uid;
    await _cuenta(uid).update({'sonidos': valor});
    await _refrescarTrasEscritura(uid);
    if (valor) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> _refrescarTrasEscritura(String uid) async {
    if (usuario?.uid != uid) return;
    try {
      await refrescar();
    } catch (_) {
      if (usuario?.uid == uid) {
        error = 'El cambio se guardó. Desliza hacia abajo para actualizar la vista.';
        _avisar();
      }
    }
  }

  Future<void> actualizarToken() async {
    if (!registrarDispositivo) return;
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS))
      return;
    final uid = usuario?.uid;
    if (uid == null) return;
    try {
      await _token?.cancel();
      // La base conserva el token FCM exigido por el registro de dispositivos.
      // ignore: deprecated_member_use
      final valor = await FirebaseMessaging.instance.getToken();
      if (_cerrado || usuario?.uid != uid) return;
      if (valor != null && usuario?.uid == uid) await _guardarToken(uid, valor);
      // ignore: deprecated_member_use
      _token = FirebaseMessaging.instance.onTokenRefresh.listen(
        (valor) {
          if (usuario?.uid == uid) {
            unawaited(
              _guardarToken(uid, valor).catchError((Object _) {
                avisoToken =
                    'No se pudo actualizar el registro del dispositivo.';
                _avisar();
              }),
            );
          }
        },
        onError: (Object _) {
          if (usuario?.uid == uid) {
            avisoToken = 'No se pudo actualizar el registro del dispositivo.';
            _avisar();
          }
        },
      );
      avisoToken = valor == null
          ? 'El dispositivo todavía no tiene token de notificaciones.'
          : null;
    } catch (_) {
      avisoToken = 'No se pudo registrar este dispositivo. Puedes reintentarlo desde tu perfil.';
    }
    _avisar();
  }

  Future<void> _guardarToken(String uid, String token) async {
    final dispositivos = _cuenta(uid).collection('dispositivos');
    final lote = base.batch();
    if (_duenoToken == uid && _tokenActual != null && _tokenActual != token) {
      lote.delete(dispositivos.doc(_tokenActual));
    }
    lote.set(dispositivos.doc(token), {
      'token': token,
      'plataforma': defaultTargetPlatform.name,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    await lote.commit();
    if (usuario?.uid == uid) {
      _duenoToken = uid;
      _tokenActual = token;
    }
  }

  Future<void> cerrarSesion() async {
    final uid = _uid;
    await _token?.cancel();
    if (_duenoToken == uid && _tokenActual != null) {
      try {
        await _cuenta(uid)
            .collection('dispositivos')
            .doc(_tokenActual)
            .delete();
      } catch (_) {
        debugPrint('No se pudo desvincular el token del dispositivo.');
      }
    }
    _tokenActual = null;
    _duenoToken = null;
    await auth.signOut();
  }

  Future<void> importarCapturasLocales() async {
    final uid = _uid;
    final datos = await SharedPreferencesAsync().getString('criaturasNfc');
    if (datos == null) return;
    final estados = Map<String, dynamic>.from(jsonDecode(datos) as Map);
    for (final entrada in estados.entries) {
      final criatura = await buscar(entrada.key);
      if (usuario?.uid != uid) return;
      if (criatura == null) continue;
      if (entrada.value == 'capturada') {
        await capturar(criatura);
      } else if (entrada.value == 'recibida') {
        await recibir(criatura);
      }
    }
    await _cuenta(uid).update({'capturasLocalesImportadas': true});
    await _refrescarTrasEscritura(uid);
  }

  Query<Map<String, dynamic>> _relaciones(String uid) =>
      base.collection('amistades').where('miembros', arrayContains: uid);

  void _leerAmistades(QuerySnapshot<Map<String, dynamic>> datos) {
    amistades = datos.docs
        .map((doc) => Amistad.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> _cargarNombresAmigos(String uid, int generacion) async {
    final ids = amistades.map((amistad) => amistad.otroUsuario(uid)).toSet();
    final nombres = await Future.wait(
      ids.map((id) async {
        final doc = await base
            .collection('perfilesPublicos')
            .doc(id)
            .get(const GetOptions(source: Source.server));
        final nombre = doc.data()?['nombre'] as String? ?? '';
        return MapEntry(id, nombre.isEmpty ? id : nombre);
      }),
    );
    if (_cerrado || generacion != _generacion) return;
    nombresAmigos = Map.fromEntries(nombres);
    _avisar();
  }

  Future<void> solicitarAmistad(String codigo) async {
    final uid = _uid;
    final destino = codigo.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(destino)) {
      throw StateError('Revisa el código de tu amigo.');
    }
    if (destino == uid) throw StateError('Ese es tu propio código.');
    final usuarioDestino = await base
        .collection('perfilesPublicos')
        .doc(destino)
        .get(const GetOptions(source: Source.server));
    if (!usuarioDestino.exists)
      throw StateError(
        'No encontramos un usuario con ese código. Tu amigo debe abrir la app al menos una vez.',
      );
    if (usuario?.uid != uid) return;
    final miembros = [uid, destino]..sort();
    final id = base64UrlEncode(utf8.encode(jsonEncode(miembros)));
    final referencia = base.collection('amistades').doc(id);
    await base.runTransaction((transaccion) async {
      final existente = await transaccion.get(referencia);
      if (existente.exists) {
        throw StateError(
          existente.data()!['estado'] == 'aceptada'
              ? 'Este usuario ya está en tus amigos.'
              : 'Ya tienen una solicitud pendiente. Revisa tus solicitudes.',
        );
      }
      transaccion.set(referencia, {
        'miembros': miembros,
        'emisorId': uid,
        'receptorId': destino,
        'estado': 'pendiente',
        'creadaEn': FieldValue.serverTimestamp(),
      });
    });
    await _refrescarTrasEscritura(uid);
  }

  Future<void> responderAmistad(
    Amistad amistad, {
    required bool aceptar,
  }) async {
    final uid = _uid;
    final referencia = base.collection('amistades').doc(amistad.id);
    await base.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);
      if (!actual.exists) return;
      if (actual.data()!['receptorId'] != uid ||
          actual.data()!['estado'] != 'pendiente') {
        throw StateError('La solicitud ya cambió. Actualiza la lista.');
      }
      if (aceptar) {
        transaccion.update(referencia, {'estado': 'aceptada'});
      } else {
        transaccion.delete(referencia);
      }
    });
    await _refrescarTrasEscritura(uid);
  }

  Future<void> eliminarAmistad(Amistad amistad) async {
    final uid = _uid;
    if (amistad.emisorId != uid && amistad.receptorId != uid) {
      throw StateError('La amistad pertenece a otra cuenta.');
    }
    await base.collection('amistades').doc(amistad.id).delete();
    await _refrescarTrasEscritura(uid);
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    unawaited(_sesion?.cancel());
    unawaited(_token?.cancel());
    for (final escucha in _escuchas) {
      unawaited(escucha.cancel());
    }
    super.dispose();
  }
}
