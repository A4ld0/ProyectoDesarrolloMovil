import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pokemonchafa/data/foto_perfil_local.dart';

class _DirectorioDePruebas extends PathProviderPlatform {
  _DirectorioDePruebas(this.ruta);

  final String ruta;

  @override
  Future<String?> getApplicationSupportPath() async => ruta;
}

class _GaleriaDePruebas extends ImagePickerPlatform {
  XFile? foto;
  ImageSource? origen;
  LostDataResponse recuperacion = LostDataResponse.empty();

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    origen = source;
    return foto;
  }

  @override
  Future<LostDataResponse> getLostData() async => recuperacion;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directorio;
  late _GaleriaDePruebas galeria;
  late File imagen;
  late PathProviderPlatform directoriosOriginales;
  late ImagePickerPlatform galeriaOriginal;

  setUp(() async {
    directoriosOriginales = PathProviderPlatform.instance;
    galeriaOriginal = ImagePickerPlatform.instance;
    directorio = await Directory.systemTemp.createTemp('foto-perfil-test-');
    PathProviderPlatform.instance = _DirectorioDePruebas(directorio.path);
    galeria = _GaleriaDePruebas();
    ImagePickerPlatform.instance = galeria;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    imagen = File.fromUri(directorio.uri.resolve('galeria.png'));
    final grabador = ui.PictureRecorder();
    ui.Canvas(grabador).drawColor(const ui.Color(0xFF118855), ui.BlendMode.src);
    final dibujo = grabador.endRecording();
    final bitmap = await dibujo.toImage(16, 16);
    final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    await imagen.writeAsBytes(png!.buffer.asUint8List());
    bitmap.dispose();
    dibujo.dispose();
  });

  tearDown(() async {
    PathProviderPlatform.instance = directoriosOriginales;
    ImagePickerPlatform.instance = galeriaOriginal;
    debugDefaultTargetPlatformOverride = null;
    await directorio.delete(recursive: true);
  });

  test(
    'La foto persiste por usuario después de perder el archivo de galería',
    () async {
      const almacen = FotoPerfilLocal('usuario-uno');
      galeria.foto = XFile(imagen.path);
      final original = await imagen.readAsBytes();

      expect(await almacen.leer(), isNull);
      expect(await almacen.elegirDeGaleria(), original);
      expect(galeria.origen, ImageSource.gallery);
      await imagen.delete();

      expect(await const FotoPerfilLocal('usuario-uno').leer(), original);
      expect(await const FotoPerfilLocal('usuario-dos').leer(), isNull);
    },
  );

  test(
    'Reemplazar y cancelar la selección conservan una foto válida',
    () async {
      const almacen = FotoPerfilLocal('usuario');
      galeria.foto = XFile(imagen.path);
      final original = await almacen.elegirDeGaleria();
      expect(await almacen.elegirDeGaleria(), original);

      galeria.foto = null;
      expect(await almacen.elegirDeGaleria(), isNull);
      expect(await almacen.leer(), original);
      expect(
        await File.fromUri(directorio.uri.resolve('seleccion-foto-perfil'))
            .exists(),
        isFalse,
      );
    },
  );

  test('Un archivo inválido conserva la foto anterior', () async {
    const almacen = FotoPerfilLocal('usuario');
    galeria.foto = XFile(imagen.path);
    final original = await almacen.elegirDeGaleria();
    await imagen.writeAsString('archivo inválido');

    await expectLater(almacen.elegirDeGaleria(), throwsA(isA<Exception>()));
    expect(await almacen.leer(), original);
  });

  test(
    'Recupera una selección interrumpida en Android para su usuario',
    () async {
      final pendiente = File.fromUri(
        directorio.uri.resolve('seleccion-foto-perfil'),
      );
      await pendiente.writeAsString('usuario-original');
      galeria.recuperacion = LostDataResponse(files: [XFile(imagen.path)]);

      await FotoPerfilLocal.recuperarSeleccionPendiente();

      expect(
        await const FotoPerfilLocal('usuario-original').leer(),
        await imagen.readAsBytes(),
      );
      expect(await const FotoPerfilLocal('otro-usuario').leer(), isNull);
      expect(await pendiente.exists(), isFalse);
    },
  );
}
