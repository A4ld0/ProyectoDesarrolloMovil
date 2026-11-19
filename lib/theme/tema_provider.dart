import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaProvider extends ChangeNotifier {
  TemaProvider({required bool modoOscuroInicial})
    : _modoOscuro = modoOscuroInicial;

  static const _claveModoOscuro = 'modoOscuro';
  bool _modoOscuro;
  Future<bool> _escrituraPendiente = Future.value(true);

  bool get modoOscuro => _modoOscuro;

  static Future<bool> leerModoOscuro() async {
    try {
      return await SharedPreferencesAsync().getBool(_claveModoOscuro) ?? false;
    } catch (_) {
      debugPrint('No se pudo leer el tema guardado.');
      return false;
    }
  }

  Future<bool> cambiarModoOscuro(bool valor) {
    if (_modoOscuro == valor) return _escrituraPendiente;
    _modoOscuro = valor;

    // Guarda los cambios en el mismo orden en que se mueve el interruptor.
    final escritura = _escrituraPendiente.then(
      (_) => _guardarModoOscuro(valor),
    );
    _escrituraPendiente = escritura;
    notifyListeners();
    return escritura;
  }

  Future<bool> _guardarModoOscuro(bool valor) async {
    try {
      await SharedPreferencesAsync().setBool(_claveModoOscuro, valor);
      return true;
    } catch (_) {
      return false;
    }
  }
}
