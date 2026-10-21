import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokematch/main.dart';

void main() {
  testWidgets('mostra o card fixo', (tester) async {
    await tester.pumpWidget(const PokeMatchApp());
    await tester.pumpAndSettle();
    expect(find.text('PokéMatch'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#025'), findsOneWidget);
    // Sem rede no teste, a imagem cai no ícone do errorBuilder.
    expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
