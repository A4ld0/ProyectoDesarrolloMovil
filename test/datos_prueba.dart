import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:pokemonchafa/data/datos_app.dart';
import 'package:pokemonchafa/models/criatura.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const criaturasPrueba = [
  Criatura(
    id: 'nubin',
    nombre: 'Nubin',
    tipo: 'Aire',
    descripcion: 'Nube',
    creadorId: 'catalogo',
    simbolo: 'nube',
  ),
  Criatura(
    id: 'burbujin',
    nombre: 'Burbujin',
    tipo: 'Agua',
    descripcion: 'Burbujas',
    creadorId: 'catalogo',
    simbolo: 'agua',
  ),
  Criatura(
    id: 'estelin',
    nombre: 'Estelin',
    tipo: 'Estrella',
    descripcion: 'Estrella',
    creadorId: 'catalogo',
    simbolo: 'estrella',
  ),
];

Future<DatosApp> datosDePrueba({String uid = 'usuario-uno'}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final base = FakeFirebaseFirestore();
  final user = MockUser(uid: uid, email: '$uid@example.com', displayName: uid);
  final auth = MockFirebaseAuth(signedIn: true, mockUser: user);
  for (final criatura in criaturasPrueba) {
    await base.collection('criaturas').doc(criatura.id).set({
      ...criatura.toMap(),
      'creadorId': uid,
    });
  }
  final datos = DatosApp(auth: auth, base: base, registrarDispositivo: false);
  await datos.abrirSesion(user);
  return datos;
}
