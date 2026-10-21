import 'package:flutter/material.dart';

import 'package:pokematch/pokeapi_service.dart';
import 'package:pokematch/pokemon.dart';

// Card grande de um Pokémon: imagem em cima, nome e número embaixo.
class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      // Column empilha os filhos de cima para baixo.
      child: Column(
        children: [
          // Expanded: a imagem ocupa todo o espaço que sobra no card.
          Expanded(
            child: Image.network(
              pokemon.largeImageUrl,
              // Se a imagem falhar (sem internet), mostra um ícone.
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.catching_pokemon, size: 96),
            ),
          ),
          Text(
            pokemon.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(pokemon.number),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Tela do monte: busca os Pokémon, embaralha e mostra um card por vez.
class MatchPage extends StatefulWidget {
  // O serviço vem de fora: nos testes dá para trocar por um falso.
  const MatchPage({super.key, required this.service});

  final PokeApiService service;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  List<Pokemon> _deck = []; // o monte: o primeiro é o card da frente
  final List<Pokemon> _captured = []; // os que foram para a mochila

  // Future = um valor que ainda vai chegar (a resposta da internet).
  // late: só é calculado no primeiro uso, quando já existe acesso a widget.
  late final Future<void> _future = _loadDeck();

  // async/await: espera a lista chegar e embaralha o monte.
  Future<void> _loadDeck() async {
    final pokemons = await widget.service.fetchPokemons();
    _deck = pokemons..shuffle();
  }

  // setState avisa o Flutter: "algo mudou, desenhe a tela de novo".
  void _swipe(bool capture) {
    setState(() {
      final pokemon = _deck.removeAt(0);
      if (capture) _captured.add(pokemon);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokéMatch'),
        actions: [
          // Contador da mochila: quantos Pokémon já foram capturados.
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '🎒 ${_captured.length}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      // FutureBuilder redesenha conforme o estado do Future:
      // carregando, erro ou pronto.
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Não foi possível carregar'));
          }
          if (_deck.isEmpty) {
            return const Center(child: Text('Acabaram os Pokémon!'));
          }
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      // Stack põe um widget em cima do outro: o monte.
                      // O último da lista fica na frente.
                      child: Stack(
                        children: [
                          if (_deck.length > 1) PokemonCard(pokemon: _deck[1]),
                          PokemonCard(pokemon: _deck.first),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Row coloca os botões lado a lado.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _swipe(false),
                    icon: const Icon(Icons.close, color: Colors.red, size: 48),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    onPressed: () => _swipe(true),
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
