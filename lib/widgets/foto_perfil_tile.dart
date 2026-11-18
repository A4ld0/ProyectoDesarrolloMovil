import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/foto_perfil_local.dart';

class FotoPerfilTile extends StatefulWidget {
  const FotoPerfilTile({required this.uid, super.key});

  final String uid;

  @override
  State<FotoPerfilTile> createState() => _FotoPerfilTileState();
}

class _FotoPerfilTileState extends State<FotoPerfilTile> {
  late final _almacen = FotoPerfilLocal(widget.uid);
  late Future<Uint8List?> _foto = _almacen.leer();
  bool _seleccionando = false;

  Future<void> _elegirFoto() async {
    setState(() => _seleccionando = true);

    try {
      final foto = await _almacen.elegirDeGaleria();
      if (mounted && foto != null) {
        setState(() => _foto = Future.value(foto));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la foto de perfil.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _seleccionando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _foto,
    builder: (context, snapshot) {
      final foto = snapshot.data;
      final cargando = snapshot.connectionState == ConnectionState.waiting;
      return ListTile(
        leading: CircleAvatar(
          child: foto == null
              ? const Icon(Icons.person_outline)
              : ClipOval(
                  child: Image.memory(
                    foto,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    cacheWidth: 128,
                    errorBuilder: (_, _, _) => const Icon(Icons.person_outline),
                  ),
                ),
        ),
        title: const Text('Foto de perfil'),
        subtitle: Text(
          cargando
              ? 'Cargando…'
              : snapshot.hasError
              ? 'No se pudo leer la foto. Selecciona otra.'
              : foto == null
              ? 'Seleccionar de la galería'
              : 'Cambiar foto',
        ),
        trailing: _seleccionando
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.photo_library_outlined),
        onTap: cargando || _seleccionando ? null : _elegirFoto,
      );
    },
  );
}
