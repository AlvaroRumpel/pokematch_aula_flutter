import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokematch/match_page.dart';
import 'package:pokematch/pokeapi_service.dart';
import 'package:pokematch/pokemon.dart';

// Serviço falso: devolve o que o teste mandar, sem internet.
class FakePokeApiService extends PokeApiService {
  FakePokeApiService(this.onFetchPokemons);

  final Future<List<Pokemon>> Function() onFetchPokemons;

  @override
  Future<List<Pokemon>> fetchPokemons() => onFetchPokemons();
}

Widget app(Future<List<Pokemon>> Function() fetch) =>
    MaterialApp(home: MatchPage(service: FakePokeApiService(fetch)));

const bulbasaur = Pokemon(id: 1, name: 'Bulbasaur');

void main() {
  testWidgets('mostra carregando', (tester) async {
    await tester.pumpWidget(app(() => Completer<List<Pokemon>>().future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra o card', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('🎒 0'), findsOneWidget);
    // Sem rede no teste, a imagem cai no ícone do errorBuilder.
    expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra erro', (tester) async {
    await tester.pumpWidget(
      app(() => Future<List<Pokemon>>.error(Exception('sem internet'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('❤ captura e conta', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    expect(find.text('Acabaram os Pokémon!'), findsOneWidget);
  });

  testWidgets('✕ rejeita sem contar', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    expect(find.text('Acabaram os Pokémon!'), findsOneWidget);
  });

  testWidgets('arrastar para a direita captura', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PokemonCard).last, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    expect(find.text('Acabaram os Pokémon!'), findsOneWidget);
  });

  testWidgets('arrastar para a esquerda rejeita', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PokemonCard).last, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    expect(find.text('Acabaram os Pokémon!'), findsOneWidget);
  });

  testWidgets('arraste curto volta o card', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PokemonCard).last, const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('agarrar o card voando não captura de novo', (tester) async {
    await tester.pumpWidget(
      app(
        () async => [
          bulbasaur,
          const Pokemon(id: 4, name: 'Charmander'),
          const Pokemon(id: 7, name: 'Squirtle'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byType(SwipeCard);
    await tester.drag(card, const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 16)); // ainda voando
    final gesture = await tester.startGesture(tester.getCenter(card));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('🎒 1'), findsOneWidget);
  });
}
