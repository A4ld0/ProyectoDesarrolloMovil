import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokemonchafa/models/criatura.dart';

import 'datos_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CRUD conserva el dibujo y rechaza ediciones de versiones anteriores',
    () async {
      final datos = await datosDePrueba();
      addTearDown(datos.dispose);
      final criatura = Criatura(
        id: 'nueva',
        nombre: 'Mi dibujo',
        tipo: 'Agua',
        descripcion: 'Original',
        creadorId: datos.usuario!.uid,
        dibujo: [
          TrazoDibujo(Colors.red, [const Offset(.1, .2), const Offset(.3, .4)]),
        ],
      );
      await datos.guardar(criatura, nueva: true);
      final guardada = await datos.buscar('nueva');
      expect(guardada!.dibujo.single.puntos.last, const Offset(.3, .4));
      final edicion = Criatura.fromMap('nueva', {
        ...guardada.toMap(),
        'nombre': 'Editada',
      });
      await datos.guardar(edicion);
      expect((await datos.buscar('nueva'))!.nombre, 'Editada');
      await expectLater(datos.guardar(edicion), throwsStateError);
      await datos.eliminar((await datos.buscar('nueva'))!);
      expect(await datos.buscar('nueva'), isNull);
    },
  );

  test(
    'Las capturas del mapa y NFC persisten y se separan por cuenta',
    () async {
      final datos = await datosDePrueba();
      addTearDown(datos.dispose);
      final usuario = datos.usuario!;
      await datos.capturar(criaturasPrueba.first);
      await datos.recibir(criaturasPrueba[1]);
      await datos.capturar(criaturasPrueba[1]);
      await datos.recibir(criaturasPrueba[1]);
      expect(datos.capturadas, hasLength(2));
      expect(datos.pendiente('burbujin'), isFalse);
      expect(datos.recibida('burbujin'), isTrue);
      await datos.abrirSesion(
        MockUser(uid: 'usuario-dos', email: 'dos@example.com'),
      );
      expect(datos.capturadas, isEmpty);
      await datos.abrirSesion(usuario);
      expect(datos.capturadas, hasLength(2));
    },
  );

  test('Una captura conserva su dibujo al eliminar la creación', () async {
    final datos = await datosDePrueba();
    addTearDown(datos.dispose);
    final criatura = Criatura(
      id: 'propia',
      nombre: 'Propia',
      tipo: 'Aire',
      descripcion: '',
      creadorId: datos.usuario!.uid,
      dibujo: [
        TrazoDibujo(Colors.blue, [const Offset(.5, .5)]),
      ],
    );
    await datos.guardar(criatura, nueva: true);
    await datos.capturar(criatura);
    await datos.eliminar(criatura);
    expect(datos.capturadas.single.nombre, 'Propia');
    expect(
      datos.capturadas.single.dibujo.single.color.toARGB32(),
      Colors.blue.toARGB32(),
    );
  });

  test(
    'Los avistamientos se guardan y conservan sus coordenadas al moverse',
    () async {
      final datos = await datosDePrueba();
      addTearDown(datos.dispose);
      await datos.colocarCerca(const LatLng(19.4, -99.1));
      final originales = Map.of(datos.puntos);
      await datos.colocarCerca(const LatLng(20.1, -100.2));
      expect(datos.puntos, originales);
      await datos.abrirSesion(datos.usuario);
      expect(datos.puntos, originales);
    },
  );

  test(
    'Registrar guarda el perfil y refrescar obtiene cambios de la base',
    () async {
      final datos = await datosDePrueba();
      addTearDown(datos.dispose);
      await datos.registrar(
        correo: 'nuevo@example.com',
        contrasena: 'prueba123',
        nombre: 'Nuevo',
      );
      final uid = datos.auth.currentUser!.uid;
      final perfil = await datos.base.collection('usuarios').doc(uid).get();
      expect(perfil.data()!['nombre'], 'Nuevo');
      expect(perfil.data()!['correo'], 'nuevo@example.com');
      await datos.base.collection('criaturas').doc('nubin').update({
        'nombre': 'Desde Firebase',
      });
      await datos.refrescar();
      expect(datos.porId('nubin')!.nombre, 'Desde Firebase');
    },
  );
}
