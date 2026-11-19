import 'package:flutter/material.dart'; //° widgets de material
import 'package:provider/provider.dart'; //° gestion de estado

import '../data/datos_app.dart'; //° provider con firestore

//! envuelve una lista con RefreshIndicator para recargar desde firestore
class RecargaFirebase extends StatelessWidget {
  const RecargaFirebase({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<DatosApp>();
    return Column(
      children: [
        if (datos.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(datos.error!, textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            //* al jalar hacia abajo vuelve a pedir los datos a firebase
            onRefresh: () async {
              try {
                await datos.refrescar();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo actualizar. Revisa tu conexión.',
                      ),
                    ),
                  );
                }
              }
            },
            child: child,
          ),
        ),
      ],
    );
  }
}
