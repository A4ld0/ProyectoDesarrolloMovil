import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/models/criatura.dart';

import 'datos_prueba.dart';

import 'package:pokemonchafa/data/intercambio_nfc.dart';

void main() {
  test('Confirma por NFC después de guardar la criatura', () async {
    final criatura = criaturasPrueba[1];
    final guardando = Completer<Criatura>();
    final guardado = Completer<void>();
    final comandos = <Uint8List>[];

    final lectura = ProtocoloCriaturaNfc.leer(
      transceive: (comando) async {
        comandos.add(comando);
        return comandos.length == 1
            ? Uint8List.fromList([
                ...ProtocoloCriaturaNfc.codificar(criatura),
                0x90,
                0,
              ])
            : Uint8List.fromList([0x90, 0]);
      },
      guardar: (recibida) {
        guardando.complete(recibida);
        return guardado.future;
      },
      buscar: (id) async =>
          criaturasPrueba.where((c) => c.id == id).firstOrNull,
      activo: () => true,
    );

    expect(await guardando.future, same(criatura));
    expect(comandos, [
      [0, 0xA4, 0x04, 0, 6, 0xF0, 0x50, 0x4B, 0x43, 0x48, 1, 0],
    ]);
    guardado.complete();
    expect(await lectura, same(criatura));
    expect(comandos.last, [0x80, 0x20, 0, 0, 0]);
  });

  test('Ignora tarjetas ajenas y mensajes desconocidos', () async {
    for (final mensaje in [
      [0x6A, 0x82],
      [2, ...'nubin'.codeUnits, 0x90, 0],
      [1, ...'desconocida'.codeUnits, 0x90, 0],
      [1, ...'nubin'.codeUnits, 0x69, 0x85],
    ]) {
      var consultas = 0;
      final recibida = await ProtocoloCriaturaNfc.leer(
        transceive: (_) async {
          consultas++;
          return Uint8List.fromList(mensaje);
        },
        guardar: (_) async => fail('No se debe guardar un mensaje inválido.'),
        buscar: (id) async =>
            criaturasPrueba.where((c) => c.id == id).firstOrNull,
        activo: () => true,
      );
      expect(recibida, isNull);
      expect(consultas, 1);
    }
  });

  test('Conserva la recepción si se pierde el enlace al confirmar', () async {
    final criatura = criaturasPrueba[2];
    var guardada = false;
    final recibida = await ProtocoloCriaturaNfc.leer(
      transceive: (_) async {
        if (guardada) throw PlatformException(code: 'contacto_perdido');
        return Uint8List.fromList([
          ...ProtocoloCriaturaNfc.codificar(criatura),
          0x90,
          0,
        ]);
      },
      guardar: (_) async => guardada = true,
      buscar: (id) async =>
          criaturasPrueba.where((c) => c.id == id).firstOrNull,
      activo: () => true,
    );
    expect(recibida, same(criatura));
    expect(guardada, isTrue);
  });
}
