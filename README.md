# pokemonchafa

A new Flutter project.

## Apariencia

En **Ajustes → Modo oscuro** se puede cambiar entre los temas claro y oscuro.
La selección se conserva al navegar y al salir de la demostración, mientras la
aplicación siga abierta. Al cerrar y abrir la app, se inicia en modo claro;
todavía no se almacena la preferencia. Los demás controles simulados conservan
sus avisos de funcionalidad pendiente.

## NFC (Entrega 1)

Se agregó [nfc_manager](https://pub.dev/packages/nfc_manager) 4.2.1 como
dependencia para la futura lectura NFC en Android. Su espacio en la interfaz
está en **Mis creaciones → Compartir → Compartir y recibir**, con el panel
**Intercambio NFC** y botones que muestran alertas de funcionalidad pendiente.

Por ahora todo es un mockup: no se consulta el hardware, no se solicitan
permisos ni se inician sesiones NFC. El paquete está instalado, pero su API
todavía no se utiliza. No se ha validado una transferencia real.

Para el intercambio entre dos Android, nfc_manager cubriría la parte lectora.
La emisión requiere integrar emulación de tarjeta (HCE) por separado; no se
agregó ningún paquete de HCE en esta entrega.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
