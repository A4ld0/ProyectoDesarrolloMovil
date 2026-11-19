import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/data/criaturas_demo.dart';
import 'package:pokemonchafa/data/criaturas_nfc.dart';
import 'package:pokemonchafa/data/intercambio_nfc.dart';
import 'package:pokemonchafa/main.dart';
import 'package:pokemonchafa/screens/editor_dibujo_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'firebase_test_setup.dart';

Future<void> mostrar(WidgetTester tester, Finder elemento) async {
  await tester.scrollUntilVisible(
    elemento,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> abrirPermisos(WidgetTester tester) async {
  await tester.pumpWidget(await MyApp.cargar());
  await rellenarCorreo(tester);
  await mostrar(tester, find.text('Iniciar sesión'));
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

Future<void> rellenarCorreo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'prueba@example.com');
  await tester.enterText(find.byType(TextField).last, 'prueba123');
}

Future<void> abrirMapa(WidgetTester tester) async {
  await abrirPermisos(tester);
  await mostrar(tester, find.text('Comenzar a explorar'));
  await tester.tap(find.text('Comenzar a explorar'));
  await tester.pumpAndSettle();
}

Future<void> abrirDesdeMenu(WidgetTester tester, String seccion) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Menú'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, seccion));
  await tester.pumpAndSettle();
}

Future<void> abrirAjustes(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Perfil'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Ajustes'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararFirebaseDePruebas);
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final opcion in [
    ('Iniciar sesión', 'correo y contraseña'),
    ('Continuar con Google', 'Google'),
    ('Continuar con Apple', 'Apple'),
  ]) {
    testWidgets('Acceso con ${opcion.$2} en un teléfono pequeño', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(await MyApp.cargar());
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );

      if (opcion.$1 == 'Iniciar sesión') await rellenarCorreo(tester);
      await mostrar(tester, find.text(opcion.$1));
      await tester.tap(find.text(opcion.$1));
      await tester.pumpAndSettle();
      if (opcion.$2 == 'Apple') {
        expect(find.text('Funcionalidad pendiente'), findsOneWidget);
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.widgetWithText(AppBar, 'Permisos'), findsNothing);

        await tester.tap(find.text(opcion.$1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
      }
      expect(find.widgetWithText(AppBar, 'Permisos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('El menú abre las secciones sobre la misma ruta del mapa', (
    tester,
  ) async {
    await abrirMapa(tester);
    final mapa = find.widgetWithText(AppBar, 'Mapa');
    final instancia = tester.element(mapa);

    await tester.tap(find.widgetWithText(FilledButton, 'Menú'));
    await tester.pumpAndSettle();
    expect(mapa, findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    for (final (seccion, titulo) in [
      ('Guía', 'enciclopedia global'),
      ('Colección', 'mis capturas'),
      ('Creaciones', 'Mis creaciones'),
    ]) {
      await abrirDesdeMenu(tester, seccion);
      expect(find.widgetWithText(AppBar, titulo), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.element(mapa), same(instancia));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('Cerca de ti destaca el marcador y conserva la selección', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await abrirMapa(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerca de ti'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Nubin'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Estelin'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Burbujin'));
    await tester.pumpAndSettle();
    final marcador = find.ancestor(
      of: find.text('Burbujin'),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(marcador, findsOneWidget);

    await tester.tap(find.text('Burbujin'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Captura la criatura'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(marcador, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ajustes cambia el tema y conserva las otras simulaciones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await abrirMapa(tester);
    await abrirAjustes(tester);
    expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);
    final modoOscuro = find.widgetWithText(SwitchListTile, 'Modo oscuro');
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isFalse);
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(Theme.of(tester.element(modoOscuro)).brightness, Brightness.dark);

    await mostrar(tester, find.text('Sonidos'));
    await tester.tap(find.text('Sonidos'));
    await tester.pumpAndSettle();
    expect(find.text('Funcionalidad pendiente'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Sonidos'),
          )
          .value,
      isTrue,
    );

    await mostrar(tester, find.text('Permisos').first);
    await tester.tap(find.text('Permisos').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Permisos'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(AppBar))).brightness,
      Brightness.dark,
    );
    expect(
      find.textContaining('En el mapa, toca «Usar mi ubicación»'),
      findsOneWidget,
    );
    await tester.tap(find.text('Volver a ajustes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);

    await mostrar(tester, find.text('Acerca de'));
    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();
    expect(find.text('Acerca de pokemonchafa'), findsOneWidget);
    expect(find.textContaining('Versión 1.0.0'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(AppBar))).brightness,
      Brightness.dark,
    );
    await abrirAjustes(tester);
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isTrue);
    await mostrar(tester, find.text('Modo oscuro'));
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(modoOscuro)).brightness, Brightness.light);
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(await MyApp.cargar());
    expect(
      Theme.of(tester.element(find.text('Iniciar sesión'))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'Cerrar sesión pide confirmación y el tema persiste al reiniciar',
    (tester) async {
      await abrirMapa(tester);
      await abrirAjustes(tester);
      await tester.tap(find.text('Modo oscuro'));
      await tester.pumpAndSettle();
      await mostrar(tester, find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Iniciar sesión'))).brightness,
        Brightness.dark,
      );
      expect(
        Navigator.of(tester.element(find.text('Iniciar sesión'))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(await MyApp.cargar());
      expect(
        Theme.of(tester.element(find.text('Iniciar sesión'))).brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets('Navegacion de las tres vistas', (tester) async {
    await abrirMapa(tester);
    await abrirDesdeMenu(tester, 'Creaciones');
    await tester.tap(find.byTooltip('Crear una criatura'));
    await tester.pumpAndSettle();
    expect(find.text('Editor de dibujo'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compartir y recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Comparte tu criatura'), findsOneWidget);
    await tester.tap(find.text('Empezar a compartir'));
    await tester.pumpAndSettle();
    expect(find.text(IntercambioNfc.mensajeSinNfc), findsOneWidget);
    await tester.tap(find.text('Recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Recibe una criatura'), findsOneWidget);
    await tester.tap(find.text('Buscar criatura'));
    await tester.pumpAndSettle();
    expect(find.text(IntercambioNfc.mensajeSinNfc), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis creaciones'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Una criatura recibida se captura y queda en la colección', (
    tester,
  ) async {
    final almacen = CriaturasNfc({});
    addTearDown(almacen.dispose);
    final criatura = criaturasDemo[1];
    await almacen.recibir(criatura);
    await almacen.recibir(criatura);

    await abrirMapa(tester);
    expect(find.byIcon(Icons.nfc), findsOneWidget);
    await tester.tap(find.text(criatura.nombre));
    await tester.pumpAndSettle();
    expect(find.text('Recibida por NFC'), findsOneWidget);
    await tester.tap(find.text('Capturar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver colección'));
    await tester.pumpAndSettle();
    expect(find.text(criatura.nombre), findsOneWidget);
    expect(find.text('Recibida por NFC'), findsOneWidget);

    final estados = await CriaturasNfc.leer();
    expect(estados, {criatura.id: EstadoCriaturaNfc.capturada});
    final reiniciado = CriaturasNfc(estados);
    addTearDown(reiniciado.dispose);
    await reiniciado.recibir(criatura);
    expect(reiniciado.pendiente(criatura), isFalse);
    expect(reiniciado.capturadas, [criatura]);
  });

  testWidgets('Dibuja con colores primarios, deshace y limpia los trazos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: EditorDibujoScreen()));

    final lienzo = find.byType(AspectRatio);
    final sinTrazos = find.text('Dibuja aquí');
    final deshacer = find.text('Deshacer');
    final limpiar = find.text('Limpiar lienzo');
    expect(sinTrazos, findsOneWidget);

    await tester.drag(lienzo, const Offset(0, 64));
    await tester.pump();
    expect(sinTrazos, findsNothing);

    await tester.tap(find.bySemanticsLabel('Azul'));
    await tester.pump();
    await tester.drag(lienzo, const Offset(64, 0));
    await tester.pump();
    final pintura = find.descendant(
      of: lienzo,
      matching: find.byType(CustomPaint),
    );
    expect(
      pintura,
      paints
        ..path(color: Colors.red)
        ..path(color: Colors.blue),
    );

    await tester.tap(find.bySemanticsLabel('Amarillo'));
    await tester.pump();
    await tester.tap(lienzo);
    await tester.pump();
    expect(
      pintura,
      paints
        ..path(color: Colors.red)
        ..path(color: Colors.blue)
        ..circle(color: Colors.yellow),
    );
    await mostrar(tester, deshacer);
    await tester.tap(deshacer);
    await tester.pump();
    expect(sinTrazos, findsNothing);

    await tester.tap(limpiar);
    await tester.pump();
    expect(sinTrazos, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Permisos indica dónde activar el GPS y permite seguir al mapa', (
    tester,
  ) async {
    await abrirPermisos(tester);
    expect(
      find.textContaining('En el mapa, toca «Usar mi ubicación»'),
      findsOneWidget,
    );
    final boton = find.text('Simular permiso de Cámara');
    await mostrar(tester, boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.text('Cámara simulada'), findsOneWidget);
    await mostrar(tester, find.text('Comenzar a explorar'));
    await tester.tap(find.text('Comenzar a explorar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(find.text('Usar mi ubicación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cada criatura completa el flujo en un telefono pequeño', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await abrirMapa(tester);

    for (final nombre in ['Nubin', 'Burbujin', 'Estelin']) {
      final marcador = find.text(nombre);
      await mostrar(tester, marcador);
      await tester.tap(marcador);
      await tester.pumpAndSettle();
      expect(find.text('Captura la criatura'), findsOneWidget);
      expect(find.text(nombre), findsOneWidget);
      await mostrar(tester, find.text('Capturar'));
      await tester.tap(find.text('Capturar'));
      await tester.pumpAndSettle();
      expect(find.text('Captura exitosa'), findsOneWidget);
      expect(find.text(nombre), findsOneWidget);
      await mostrar(tester, find.text('Seguir explorando'));
      await tester.tap(find.text('Seguir explorando'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Cancelar, volver atras y navegar desde el resultado', (
    tester,
  ) async {
    await abrirMapa(tester);
    await mostrar(tester, find.text('Nubin'));
    await tester.tap(find.text('Nubin'));
    await tester.pumpAndSettle();
    await mostrar(tester, find.text('Volver al mapa'));
    await tester.tap(find.text('Volver al mapa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);

    await tester.tap(find.text('Nubin'));
    await tester.pumpAndSettle();
    await mostrar(tester, find.text('Capturar'));
    await tester.tap(find.text('Capturar'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);

    await tester.tap(find.text('Nubin'));
    await tester.pumpAndSettle();
    await mostrar(tester, find.text('Capturar'));
    await tester.tap(find.text('Capturar'));
    await tester.pumpAndSettle();
    await mostrar(tester, find.text('Ver colección'));
    await tester.tap(find.text('Ver colección'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'mis capturas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
