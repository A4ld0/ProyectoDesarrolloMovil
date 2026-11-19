import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'criaturas_demo.dart';

enum EstadoCriaturaNfc { recibida, capturada }

class CriaturasNfc extends ChangeNotifier {
  CriaturasNfc(Map<String, EstadoCriaturaNfc> estadosIniciales)
    : _estados = Map.of(estadosIniciales);

  static const _clave = 'criaturasNfc';
  Map<String, EstadoCriaturaNfc> _estados;
  Future<void> _pendiente = Future.value();

  bool pendiente(CriaturaDemo criatura) =>
      _estados[criatura.id] == EstadoCriaturaNfc.recibida;

  Iterable<CriaturaDemo> get capturadas => criaturasDemo.where(
    (criatura) => _estados[criatura.id] == EstadoCriaturaNfc.capturada,
  );

  static Future<Map<String, EstadoCriaturaNfc>> leer() async {
    try {
      final datos = await SharedPreferencesAsync().getString(_clave);
      if (datos == null) return {};
      final estados = jsonDecode(datos);
      if (estados is! Map<String, dynamic>) return {};
      return {
        for (final criatura in criaturasDemo)
          if (estados[criatura.id] == EstadoCriaturaNfc.recibida.name)
            criatura.id: EstadoCriaturaNfc.recibida
          else if (estados[criatura.id] == EstadoCriaturaNfc.capturada.name)
            criatura.id: EstadoCriaturaNfc.capturada,
      };
    } catch (_) {
      debugPrint('No se pudieron leer las criaturas recibidas por NFC.');
      return {};
    }
  }

  Future<void> recibir(CriaturaDemo criatura) =>
      _guardar(criatura, EstadoCriaturaNfc.recibida);

  Future<void> capturar(CriaturaDemo criatura) =>
      _guardar(criatura, EstadoCriaturaNfc.capturada);

  Future<void> _guardar(CriaturaDemo criatura, EstadoCriaturaNfc estado) {
    final guardado = _pendiente.then((_) async {
      final anterior = _estados[criatura.id];
      // Una segunda recepción no duplica la criatura ni deshace su captura.
      if (anterior == estado || anterior == EstadoCriaturaNfc.capturada) return;
      final estados = {..._estados, criatura.id: estado};
      await SharedPreferencesAsync().setString(
        _clave,
        jsonEncode(estados.map((id, estado) => MapEntry(id, estado.name))),
      );
      _estados = estados;
      notifyListeners();
    });
    _pendiente = guardado.then<void>((_) {}, onError: (Object _) {});
    return guardado;
  }
}
