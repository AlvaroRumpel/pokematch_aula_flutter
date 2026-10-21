import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokematch/match_page.dart';
import 'package:pokematch/my_pokedex_page.dart';
import 'package:pokematch/pokeapi_service.dart';
import 'package:pokematch/pokemon.dart';
import 'package:pokematch/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Serviço falso: devolve o que o teste mandar, sem internet.
class FakePokeApiService extends PokeApiService {
  FakePokeApiService(
    this.onFetchPokemons, {
    this.onFetchDetails,
    this.typeIds = const {},
  });

  final Future<List<Pokemon>> Function() onFetchPokemons;
  final Future<PokemonDetails> Function()? onFetchDetails;
  final Map<String, Set<int>> typeIds; // tipo -> números dos Pokémon

  @override
  Future<List<Pokemon>> fetchPokemons() => onFetchPokemons();

  @override
  Future<PokemonDetails> fetchPokemonDetails(int id) =>
      // Sem resposta definida, devolve um detalhe vazio na hora.
      onFetchDetails?.call() ??
      Future.value(const PokemonDetails(types: [], height: 0, weight: 0));

  @override
  Future<Set<int>> fetchTypeIds(String type) async => typeIds[type] ?? {};
}

Widget profile(Future<PokemonDetails> Function() details) => MaterialApp(
  home: ProfilePage(
    pokemon: bulbasaur,
    service: FakePokeApiService(() async => [], onFetchDetails: details),
  ),
);

Widget app(Future<List<Pokemon>> Function() fetch) =>
    MaterialApp(home: MatchPage(service: FakePokeApiService(fetch)));

const bulbasaur = Pokemon(id: 1, name: 'Bulbasaur');
const charmander = Pokemon(id: 4, name: 'Charmander');

void main() {
  // Cada teste começa sem nada salvo no aparelho.
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('tocar no card abre o perfil e não captura', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PokemonCard).last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('perfil mostra dados', (tester) async {
    await tester.pumpWidget(
      profile(
        () async => const PokemonDetails(
          types: ['grass', 'poison'],
          height: 0.7,
          weight: 6.9,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in [
      '#001',
      'grass',
      'poison',
      'Altura: 0.7 m',
      'Peso: 6.9 kg',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.textContaining('grass e poison'), findsOneWidget); // a bio
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil mostra carregando e erro', (tester) async {
    final details = Completer<PokemonDetails>();
    await tester.pumpWidget(profile(() => details.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    details.completeError(Exception('sem internet'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('contador abre a Minha Pokédex com o capturado', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🎒 1'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPokedexPage), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Minha Pokédex vazia', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MyPokedexPage(captured: [])),
    );
    expect(find.text('Ninguém capturado ainda.'), findsOneWidget);
  });

  testWidgets('capturar salva o número', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('captured'), ['1']);
  });

  testWidgets('abre com os capturados salvos', (tester) async {
    SharedPreferences.setMockInitialValues({
      'captured': ['4'],
    });
    await tester.pumpWidget(app(() async => [bulbasaur, charmander]));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    // Já capturado: fica fora do monte.
    expect(find.text('Charmander'), findsNothing);
  });

  testWidgets('todos capturados mostra monte vazio', (tester) async {
    SharedPreferences.setMockInitialValues({
      'captured': ['1'],
    });
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    expect(find.text('Acabaram os Pokémon!'), findsOneWidget);
  });

  testWidgets('desfazer traz o último card e tira da mochila', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('captured'), isEmpty);
  });

  testWidgets('filtrar por tipo mostra só aquele tipo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchPage(
          service: FakePokeApiService(
            () async => [bulbasaur, charmander],
            typeIds: {
              'fire': {4},
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bulbasaur'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fire'));
    await tester.pumpAndSettle();
    expect(find.text('PokéMatch: fire'), findsOneWidget);
    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('arrastar para cima dá super like e salva a estrela', (
    tester,
  ) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PokemonCard).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('captured'), ['1']);
    expect(prefs.getStringList('stars'), ['1']);

    await tester.tap(find.text('🎒 1'));
    await tester.pumpAndSettle();
    expect(find.text('⭐ Bulbasaur'), findsOneWidget);
  });

  testWidgets('botão ⭐ dá super like', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();
    expect(find.text('🎒 1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('stars'), ['1']);
  });

  testWidgets('desfazer também desfaz o super like', (tester) async {
    await tester.pumpWidget(app(() async => [bulbasaur]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(find.text('🎒 0'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('captured'), isEmpty);
    expect(prefs.getStringList('stars'), isEmpty);
  });
}
