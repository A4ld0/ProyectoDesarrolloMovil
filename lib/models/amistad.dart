class Amistad {
  const Amistad({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.estado,
  });

  final String id;
  final String emisorId;
  final String receptorId;
  final String estado;

  bool get aceptada => estado == 'aceptada';

  String otroUsuario(String uid) => emisorId == uid ? receptorId : emisorId;

  factory Amistad.fromMap(String id, Map<String, dynamic> datos) => Amistad(
    id: id,
    emisorId: datos['emisorId'] as String,
    receptorId: datos['receptorId'] as String,
    estado: datos['estado'] as String,
  );
}
