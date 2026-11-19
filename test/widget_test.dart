import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/main.dart';
import 'package:pokemonchafa/screens/editor_dibujo_screen.dart';

import 'datos_prueba.dart';

Future<void> mostrar(WidgetTester tester, Finder elemento) async {
  await tester.scrollUntilVisible(
    elemento,
    140,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> abrirMenu(WidgetTester tester, String seccion) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Menú'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, seccion));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('El menú conserva el mapa al abrir las secciones', (
    tester,
  ) async {
    final datos = await datosDePrueba();
    await tester.pumpWidget(MyApp(modoOscuroInicial: false, datos: datos));
    await tester.pumpAndSettle();
    for (final seccion in ['Guía', 'Colección', 'Creaciones']) {
      await abrirMenu(tester, seccion);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mapa'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Una captura normal aparece en la colección', (tester) async {
    final datos = await datosDePrueba();
    await tester.pumpWidget(MyApp(modoOscuroInicial: false, datos: datos));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nubin'));
    await tester.pumpAndSettle();
    await mostrar(tester, find.text('Capturar'));
    await tester.tap(find.text('Capturar'));
    await tester.pumpAndSettle();
    expect(find.text('Captura exitosa'), findsOneWidget);
    await mostrar(tester, find.text('Ver colección'));
    await tester.tap(find.text('Ver colección'));
    await tester.pumpAndSettle();
    expect(find.text('Nubin'), findsOneWidget);
    expect(datos.estaCapturada('nubin'), isTrue);
  });

  testWidgets('El editor conserva los colores de cada trazo', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: EditorDibujoScreen()));
    final lienzo = find.byType(AspectRatio);
    await mostrar(tester, lienzo);
    await tester.drag(lienzo, const Offset(64, 0));
    await tester.pump();
    await mostrar(tester, find.bySemanticsLabel('Azul'));
    await tester.tap(find.bySemanticsLabel('Azul'));
    await mostrar(tester, lienzo);
    await tester.drag(lienzo, const Offset(0, 64));
    await tester.pump();
    expect(
      find.descendant(of: lienzo, matching: find.byType(CustomPaint)),
      paints
        ..path(color: Colors.red)
        ..path(color: Colors.blue),
    );
    await mostrar(tester, find.text('Limpiar lienzo'));
    await tester.tap(find.text('Limpiar lienzo'));
    await tester.pump();
    expect(find.text('Dibuja aquí'), findsOneWidget);
  });

  testWidgets('Deslizar para actualizar vuelve a consultar el catálogo', (
    tester,
  ) async {
    final datos = await datosDePrueba();
    await tester.pumpWidget(MyApp(modoOscuroInicial: false, datos: datos));
    await tester.pumpAndSettle();
    await abrirMenu(tester, 'Guía');
    await datos.base.collection('criaturas').doc('nubin').update({
      'nombre': 'Actualizada',
    });
    await tester.drag(find.byType(GridView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Actualizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
