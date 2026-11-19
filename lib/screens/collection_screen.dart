import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../widgets/lista_criaturas.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis capturas')),
    body: ListaCriaturas(
      criaturas: context.watch<DatosApp>().capturadas,
      mensajeVacio: 'Todavía no tienes capturas. Explora el mapa para encontrar criaturas.',
    ),
  );
}
