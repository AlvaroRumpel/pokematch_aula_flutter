import 'package:flutter_test/flutter_test.dart';

import 'package:pokematch/main.dart';

void main() {
  testWidgets('mostra título PokéMatch e saudação', (tester) async {
    await tester.pumpWidget(const PokeMatchApp());
    expect(find.text('PokéMatch'), findsOneWidget);
    expect(find.text('Bora capturar!'), findsOneWidget);
  });
}
