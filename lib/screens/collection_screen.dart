import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado

import '../data/datos_app.dart'; //° provider con las capturas del usuario
import '../widgets/lista_criaturas.dart'; //° cuadricula reutilizable de criaturas

//! coleccion: solo las criaturas que el usuario ya capturo
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis capturas')),
    body: ListaCriaturas(
      //_ capturadas cruza el catalogo con usuarios/{uid}/capturas
      criaturas: context.watch<DatosApp>().capturadas,
      mensajeVacio: 'Todavía no tienes capturas. Explora el mapa para encontrar criaturas.',
    ),
  );
}
