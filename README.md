# pokemonchafa

A new Flutter project.

## Apariencia

En **Ajustes → Modo oscuro** se puede cambiar entre los temas claro y oscuro.
La selección se guarda en el dispositivo y se aplica desde la primera pantalla
al volver a abrir la app, incluso si cerraste sesión. La primera vez se usa el
modo claro.

## Ubicación y mapa

En Android o iOS, desde **Mapa → Usar mi ubicación**, concede el permiso de
ubicación mientras usas la app. El botón de mira centra el mapa en tu posición.
**Cerca de ti** muestra distancias aproximadas y centra el marcador elegido. Las
criaturas se colocan alrededor de la primera posición de la sesión y siguen en
esas coordenadas al moverte. Si falta el permiso, la ubicación está desactivada
o no llega una posición, queda disponible el mapa de demostración.

El mapa real carga teselas de OpenStreetMap con conexión, de acuerdo con su
[política de uso](https://operations.osmfoundation.org/policies/tiles/).
En Windows, si Flutter pide habilitar los enlaces simbólicos de escritorio al
ejecutar la app en Android, usa `$env:FLUTTER_WINDOWS = 'false'` en PowerShell
y ejecuta `flutter run -d <dispositivo>` en esa misma terminal.

Para compilar en iOS con Swift Package Manager y usar solo el permiso al usar la
app, ejecuta `BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios` (o
`BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter run`).

## Intercambio NFC

Se necesitan dos Android con NFC activado, la app abierta y los teléfonos
desbloqueados. El teléfono que envía también debe admitir
[emulación de tarjeta (HCE)](https://developer.android.com/develop/connectivity/nfc/hce).

1. En el teléfono que envía, abre **Mis creaciones**, toca **Compartir criatura**
   en la tarjeta deseada y pulsa **Empezar a compartir**.
2. En el otro teléfono, abre **Mis creaciones → Compartir → Recibir** y pulsa
   **Buscar criatura**.
3. Acerca la parte trasera de ambos teléfonos y espera la confirmación.

El receptor guarda la criatura en el dispositivo, la distingue con el icono NFC
en el mapa y puede capturarla para agregarla a **Colección**. Recibir la misma
criatura otra vez conserva su estado. El intercambio consulta la criatura en Firestore y guarda la recepción en la cuenta del usuario. Ambos teléfonos necesitan conexión. Los dibujos se guardan en Firestore y se pueden compartir.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
