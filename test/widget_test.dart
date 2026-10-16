import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/main.dart';

Future<void> mostrar(WidgetTester tester, Finder elemento) async {
  await tester.scrollUntilVisible(
    elemento,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> abrirPermisos(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await mostrar(tester, find.text('Iniciar sesión'));
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar demo'));
  await tester.pumpAndSettle();
}

Future<void> abrirMapa(WidgetTester tester) async {
  await abrirPermisos(tester);
  await mostrar(tester, find.text('Comenzar a explorar'));
  await tester.tap(find.text('Comenzar a explorar'));
  await tester.pumpAndSettle();
}

void main() {
  for (final opcion in [
    ('Iniciar sesión', 'correo y contraseña'),
    ('Continuar con Google', 'Google'),
    ('Continuar con Apple', 'Apple'),
  ]) {
    testWidgets('Acceso simulado con ${opcion.$2} en un teléfono pequeño', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );

      await mostrar(tester, find.text(opcion.$1));
      await tester.tap(find.text(opcion.$1));
      await tester.pumpAndSettle();
      expect(find.text('Funcionalidad pendiente'), findsOneWidget);
      expect(find.textContaining(opcion.$2), findsWidgets);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.widgetWithText(AppBar, 'Permisos'), findsNothing);

      await tester.tap(find.text(opcion.$1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar demo'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Permisos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('La navegacion compartida incluye las cinco secciones', (
    tester,
  ) async {
    await abrirMapa(tester);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final barra = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(barra.items.map((item) => item.label).toList(), [
      'Mapa',
      'Enciclopedia',
      'Mis creaciones',
      'Colección',
      'Ajustes',
    ]);

    await tester.tap(find.text('Mis creaciones'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis creaciones'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
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
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
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
    await mostrar(tester, find.text('Simular permiso de Ubicación'));
    await tester.tap(find.text('Simular permiso de Ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación simulada'), findsOneWidget);
    await tester.tap(find.text('Volver a ajustes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await mostrar(tester, find.text('Acerca de'));
    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();
    expect(find.text('Acerca de pokemonchafa'), findsOneWidget);
    expect(find.textContaining('Versión 1.0.0'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(AppBar))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isTrue);
    await mostrar(tester, find.text('Modo oscuro'));
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(modoOscuro)).brightness, Brightness.light);
    expect(tester.widget<SwitchListTile>(modoOscuro).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salir de la demo pide confirmación y vuelve al inicio', (
    tester,
  ) async {
    await abrirMapa(tester);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('Salir de la demo'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Iniciar sesión'))).brightness,
      Brightness.dark,
    );
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(
      Navigator.of(tester.element(find.text('Iniciar sesión'))).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Iniciar sesión'))).brightness,
      Brightness.light,
    );
  });

  testWidgets('Navegacion de las tres vistas', (tester) async {
    await abrirMapa(tester);
    await tester.tap(find.text('Mis creaciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Crear una criatura'));
    await tester.pumpAndSettle();
    expect(find.text('Editor de dibujo'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compartir y recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Comparte tu criatura'), findsOneWidget);
    await tester.drag(find.text('Comparte tu criatura'), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar compartir'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir (prueba)'), findsOneWidget);
    expect(
      find.textContaining('no se activa NFC ni se envían datos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Recibe una criatura'), findsOneWidget);
    await tester.drag(find.text('Recibe una criatura'), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Recibir (prueba)'), findsOneWidget);
    expect(
      find.textContaining('no se recibe ninguna criatura'),
      findsOneWidget,
    );
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis creaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Los permisos solo cambian su estado visual', (tester) async {
    await abrirPermisos(tester);
    for (final permiso in ['Ubicación', 'Cámara']) {
      final boton = find.text('Simular permiso de $permiso');
      await mostrar(tester, boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.text('$permiso simulada'), findsOneWidget);
    }
    await mostrar(tester, find.text('Comenzar a explorar'));
    await tester.tap(find.text('Comenzar a explorar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
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
    await mostrar(tester, find.text('Ver mis creaciones'));
    await tester.tap(find.text('Ver mis creaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu criatura'), findsOneWidget);
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
