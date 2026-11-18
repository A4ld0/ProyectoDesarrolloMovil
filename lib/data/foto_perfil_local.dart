import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FotoPerfilLocal {
  const FotoPerfilLocal(this.uid);

  final String uid;

  static bool get disponible =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<File> _archivo() async {
    final directorio = await getApplicationSupportDirectory();
    final identificador = base64UrlEncode(utf8.encode(uid));
    return File.fromUri(directorio.uri.resolve('perfil-$identificador.img'));
  }

  static Future<File> _seleccionPendiente() async {
    final directorio = await getApplicationSupportDirectory();
    return File.fromUri(directorio.uri.resolve('seleccion-foto-perfil'));
  }

  Future<Uint8List?> leer() async {
    final archivo = await _archivo();
    return await archivo.exists() ? archivo.readAsBytes() : null;
  }

  Future<Uint8List?> elegirDeGaleria() async {
    final pendiente = defaultTargetPlatform == TargetPlatform.android
        ? await _seleccionPendiente()
        : null;
    await pendiente?.writeAsString(uid, flush: true);

    try {
      final foto = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return foto == null ? null : await _guardar(foto);
    } finally {
      await pendiente?.delete();
    }
  }

  static Future<void> recuperarSeleccionPendiente() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final pendiente = await _seleccionPendiente();
      if (!await pendiente.exists()) return;

      try {
        final uid = await pendiente.readAsString();
        final respuesta = await ImagePicker().retrieveLostData();
        final fotos = respuesta.files;
        if (uid.isNotEmpty && fotos != null && fotos.isNotEmpty) {
          await FotoPerfilLocal(uid)._guardar(fotos.first);
        }
      } finally {
        await pendiente.delete();
      }
    } catch (_) {
      debugPrint('No se pudo recuperar la foto de perfil pendiente.');
    }
  }

  Future<Uint8List> _guardar(XFile foto) async {
    final bytes = await foto.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }

    final destino = await _archivo();
    final directorioTemporal = await destino.parent.createTemp('perfil-');
    final temporal = File.fromUri(directorioTemporal.uri.resolve('foto'));
    try {
      await temporal.writeAsBytes(bytes, flush: true);
      await temporal.rename(destino.path);
    } finally {
      if (await temporal.exists()) await temporal.delete();
      await directorioTemporal.delete();
    }
    return bytes;
  }
}
