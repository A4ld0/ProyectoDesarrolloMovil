import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado

import '../data/datos_app.dart'; //° provider con firestore
import '../models/criatura.dart'; //° modelo de criatura
import '../screens/creature_detail_screen.dart'; //° ficha de la criatura
import 'dibujo_criatura.dart'; //° dibujo de la criatura
import 'recarga_firebase.dart'; //° swipe down para recargar

//* cuadricula que comparten la enciclopedia y la coleccion
class ListaCriaturas extends StatelessWidget {
  const ListaCriaturas({
    required this.criaturas,
    required this.mensajeVacio,
    super.key,
  });
  final List<Criatura> criaturas;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    final colores = Theme.of(context).colorScheme;
    return RecargaFirebase(
      //? aunque este vacia se usa un ListView para que el swipe down funcione
      child: criaturas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [Text(mensajeVacio)],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 205,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: criaturas.length,
              itemBuilder: (context, indice) {
                final criatura = criaturas[indice];
                return Card(
                  color: colores.surfaceContainerHighest,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    //* abre la ficha de la criatura tocada
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreatureDetailScreen(creature: criatura),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: DibujoCriatura(criatura: criatura),
                            ),
                          ),
                          Text(
                            criatura.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            criatura.tipo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (datos.estaCapturada(criatura.id))
                            const Icon(Icons.check_circle_outline, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
