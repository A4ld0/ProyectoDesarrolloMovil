import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

Future<void> prepararFirebaseDePruebas() async {
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();
  FirebaseAuthPlatform.instance = _AuthDePruebas();
}

// Permite probar los recorridos sin usar una cuenta ni conectarse a Firebase.
class _AuthDePruebas extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async => _CredencialDePruebas(auth: this);

  @override
  Future<UserCredentialPlatform> signInWithProvider(
    AuthProvider provider,
  ) async => _CredencialDePruebas(auth: this);

  @override
  Future<void> signOut() async {}
}

class _CredencialDePruebas extends UserCredentialPlatform {
  _CredencialDePruebas({required super.auth});
}
