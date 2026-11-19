import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/foto_perfil_local.dart';
import '../widgets/foto_perfil_tile.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (usuario != null && FotoPerfilLocal.disponible) ...[
                Card(
                  child: FotoPerfilTile(
                    key: ValueKey(usuario.uid),
                    uid: usuario.uid,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    usuario?.displayName ?? usuario?.email ?? 'Explorador',
                  ),
                  subtitle: usuario == null
                      ? const Text('Modo de demostración')
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Ajustes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/ajustes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
