
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemonchafa/main.dart';

void main() {
  testWidgets('Navegacion de las tres vistas', (tester) async {
    await tester.pumpWidget(const MyApp());
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
    expect(find.text('Mis creaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

