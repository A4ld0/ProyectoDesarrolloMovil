import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado

import '../data/datos_app.dart'; //° provider con firestore
import '../models/criatura.dart'; //° modelo de criatura
import '../widgets/dibujo_criatura.dart'; //° dibujo hecho en el editor
import '../widgets/recarga_firebase.dart'; //° swipe down para recargar

//! ficha de la criatura, se abre desde enciclopedia o coleccion
class CreatureDetailScreen extends StatelessWidget {
  const CreatureDetailScreen({super.key, required this.creature});
  final Criatura creature;

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    //? se busca otra vez en el provider para mostrar la version mas nueva
    //? si alguien la edito; si ya no existe se usa la que llego
    final criatura = datos.porId(creature.id) ?? creature;
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(criatura.nombre)),
      body: RecargaFirebase(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: DibujoCriatura(criatura: criatura, tamano: 240)),
            const SizedBox(height: 24),
            Text(
              criatura.nombre,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colores.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Tipo ${criatura.tipo}'),
            const SizedBox(height: 16),
            if (criatura.descripcion.isNotEmpty) Text(criatura.descripcion),
            const SizedBox(height: 16),
            Text(
              datos.estaCapturada(criatura.id)
                  ? 'En tu colección'
                  : 'Sin capturar',
            ),
            const SizedBox(height: 24),
            //* manda la criatura a la pantalla de intercambio nfc
            if (datos.porId(criatura.id) != null)
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/intercambio',
                  arguments: criatura,
                ),
                icon: const Icon(Icons.nfc),
                label: const Text('Compartir por NFC'),
              ),
          ],
        ),
      ),
    );
  }
}
