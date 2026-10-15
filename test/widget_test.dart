import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/main.dart';

Future<void> mostrar(WidgetTester tester, Finder elemento) async {
  await tester.scrollUntilVisible(elemento, 160);
  await tester.pumpAndSettle();
}

Future<void> abrirMapa(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await mostrar(tester, find.text('Comenzar a explorar'));
  await tester.tap(find.text('Comenzar a explorar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('La navegacion compartida conserva las cuatro secciones', (
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
    await tester.tap(find.text('Recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Recibe una criatura'), findsOneWidget);
    await tester.drag(find.text('Recibe una criatura'), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar recibir'));
    await tester.pumpAndSettle();
    expect(find.text('Recibir (prueba)'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis creaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Los permisos solo cambian su estado visual', (tester) async {
    await tester.pumpWidget(const MyApp());
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
