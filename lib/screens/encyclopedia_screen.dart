import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_app.dart';
import '../widgets/lista_criaturas.dart';

class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Enciclopedia global')),
    body: ListaCriaturas(
      criaturas: context.watch<DatosApp>().catalogo,
      mensajeVacio:
          'Todavía no hay criaturas. Crea la primera desde Mis creaciones.',
    ),
  );
}
