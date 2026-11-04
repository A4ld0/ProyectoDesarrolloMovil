import 'package:flutter/foundation.dart';

class TemaProvider extends ChangeNotifier {
  bool _modoOscuro = false;

  bool get modoOscuro => _modoOscuro;

  void cambiarModoOscuro(bool valor) {
    if (_modoOscuro == valor) return;
    _modoOscuro = valor;
    notifyListeners();
  }
}
