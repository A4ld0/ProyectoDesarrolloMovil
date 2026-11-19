import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado

import '../data/datos_app.dart'; //° provider con el catalogo de firestore
import '../widgets/lista_criaturas.dart'; //° cuadricula reutilizable de criaturas

//! enciclopedia: muestra todo el catalogo guardado en firestore
class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Enciclopedia global')),
    body: ListaCriaturas(
      //_ watch reconstruye la pantalla cuando cambia el catalogo
      criaturas: context.watch<DatosApp>().catalogo,
      mensajeVacio:
          'Todavía no hay criaturas. Crea la primera desde Mis creaciones.',
    ),
  );
}
