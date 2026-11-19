import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'criaturas_demo.dart';

class ErrorIntercambioNfc implements Exception {
  const ErrorIntercambioNfc(this.mensaje);

  final String mensaje;
}

class ProtocoloCriaturaNfc {
  static const _seleccionar = [
    0x00,
    0xA4,
    0x04,
    0x00,
    0x06,
    0xF0,
    0x50,
    0x4B,
    0x43,
    0x48,
    0x01,
    0x00,
  ];
  static const _confirmar = [0x80, 0x20, 0x00, 0x00, 0x00];
  static const _version = 1;

  static Uint8List codificar(CriaturaDemo criatura) =>
      Uint8List.fromList([_version, ...criatura.id.codeUnits]);

  static CriaturaDemo? _decodificar(Uint8List respuesta) {
    if (respuesta.length < 4 || respuesta.length > 34) return null;
    final fin = respuesta.length - 2;
    if (respuesta[fin] != 0x90 ||
        respuesta[fin + 1] != 0 ||
        respuesta[0] != _version) {
      return null;
    }
    return criaturaDemoPorId(String.fromCharCodes(respuesta, 1, fin));
  }

  static Future<CriaturaDemo?> leer({
    required Future<Uint8List> Function(Uint8List) transceive,
    required Future<void> Function(CriaturaDemo) guardar,
    required bool Function() activo,
  }) async {
    final respuesta = await _transmitir(transceive, _seleccionar);
    final criatura = respuesta == null ? null : _decodificar(respuesta);
    if (criatura == null || !activo()) return null;

    await guardar(criatura);
    if (activo()) {
      // Si se pierde el contacto aquí, la criatura ya quedó guardada.
      await _transmitir(transceive, _confirmar);
    }
    return criatura;
  }

  static Future<Uint8List?> _transmitir(
    Future<Uint8List> Function(Uint8List) transceive,
    List<int> comando,
  ) async {
    try {
      return await transceive(Uint8List.fromList(comando));
    } on PlatformException {
      // Puede ser otra tarjeta o haberse interrumpido el contacto NFC.
      return null;
    }
  }
}

class IntercambioNfc {
  static const _canal = MethodChannel('pokemonchafa/nfc');
  static const _tiempoDeRecepcion = Duration(seconds: 30);
  static const _tiempoDelAdaptador = Duration(seconds: 5);
  static const mensajeSinNfc = 'El intercambio requiere un Android con NFC.';

  Completer<CriaturaDemo?>? _recepcion;
  bool _envioCancelado = false;
  bool _enviandoPorCanal = false;

  Future<void> _comprobarNfc() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ErrorIntercambioNfc(mensajeSinNfc);
    }

    final NfcAvailability disponibilidad;
    try {
      disponibilidad = await NfcManager.instance.checkAvailability().timeout(
        _tiempoDelAdaptador,
        onTimeout: () => NfcAvailability.unsupported,
      );
    } on MissingPluginException {
      throw const ErrorIntercambioNfc(mensajeSinNfc);
    }
    switch (disponibilidad) {
      case NfcAvailability.enabled:
        return;
      case NfcAvailability.disabled:
        throw const ErrorIntercambioNfc(
          'Activa el NFC en los ajustes del teléfono e inténtalo de nuevo.',
        );
      case NfcAvailability.unsupported:
        throw const ErrorIntercambioNfc(mensajeSinNfc);
    }
  }

  Future<bool> compartir(CriaturaDemo criatura) async {
    _envioCancelado = false;
    await _comprobarNfc();
    if (_envioCancelado) return false;

    _enviandoPorCanal = true;
    try {
      final estado = await _canal.invokeMethod<String>(
        'compartir',
        ProtocoloCriaturaNfc.codificar(criatura),
      );
      return switch (estado) {
        'enviado' => true,
        'vencido' => throw const ErrorIntercambioNfc(
          'No llegó la confirmación. Acerca los teléfonos e inténtalo de nuevo.',
        ),
        _ => false,
      };
    } on PlatformException catch (error) {
      throw ErrorIntercambioNfc(switch (error.code) {
        'hce_no_disponible' => 'Este teléfono no admite la emulación de tarjeta necesaria para enviar.',
        'nfc_apagado' => 'Activa el NFC en los ajustes del teléfono.',
        _ => 'No se pudo iniciar el envío por NFC.',
      });
    } finally {
      _enviandoPorCanal = false;
    }
  }

  Future<CriaturaDemo?> recibir(
    Future<void> Function(CriaturaDemo) guardar,
  ) async {
    final recepcion = Completer<CriaturaDemo?>();
    _recepcion = recepcion;
    var activarLector = false;
    try {
      await _comprobarNfc();
      if (recepcion.isCompleted) return null;

      var leyendo = false;
      activarLector = true;
      final inicio = NfcManagerAndroid.instance.enableReaderMode(
        flags: {
          NfcReaderFlagAndroid.nfcA,
          NfcReaderFlagAndroid.nfcB,
          NfcReaderFlagAndroid.skipNdefCheck,
          NfcReaderFlagAndroid.noPlatformSounds,
        },
        onTagDiscovered: (tag) async {
          if (leyendo || recepcion.isCompleted) return;
          final isoDep = IsoDepAndroid.from(tag);
          if (isoDep == null) return;
          leyendo = true;
          try {
            final criatura = await ProtocoloCriaturaNfc.leer(
              transceive: isoDep.transceive,
              guardar: guardar,
              activo: () => !recepcion.isCompleted,
            );
            if (criatura != null && !recepcion.isCompleted) {
              recepcion.complete(criatura);
            }
          } catch (error, stack) {
            if (!recepcion.isCompleted) {
              recepcion.completeError(
                const ErrorIntercambioNfc('No se pudo guardar la criatura.'),
                stack,
              );
            }
          } finally {
            leyendo = false;
          }
        },
      );
      final resultados = await Future.wait<Object?>([
        inicio,
        recepcion.future.timeout(_tiempoDeRecepcion),
      ], eagerError: true);
      return resultados[1] as CriaturaDemo?;
    } on TimeoutException {
      throw const ErrorIntercambioNfc(
        'No se detectó otro teléfono compartiendo. Inténtalo de nuevo.',
      );
    } finally {
      if (!recepcion.isCompleted) recepcion.complete(null);
      _recepcion = null;
      if (activarLector) {
        try {
          await NfcManagerAndroid.instance.disableReaderMode().timeout(
            _tiempoDelAdaptador,
          );
        } catch (_) {
          // El adaptador puede haberse apagado o la actividad puede haber salido.
        }
      }
    }
  }

  Future<void> cancelar() async {
    _envioCancelado = true;
    final recepcion = _recepcion;
    if (recepcion != null && !recepcion.isCompleted) recepcion.complete(null);
    if (_enviandoPorCanal) {
      try {
        await _canal.invokeMethod<void>('cancelarEnvio');
      } catch (_) {
        // Android cancela el envío también al salir de la actividad.
      }
    }
  }
}
