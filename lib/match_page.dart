import 'package:flutter/material.dart';

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

// Tela do monte: por enquanto, um card só, com dado fixo.
class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PokéMatch')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          // AspectRatio: o card mantém o formato 3 por 4 em qualquer tela.
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: PokemonCard(pokemon: Pokemon(id: 25, name: 'Pikachu')),
          ),
        ),
      ),
    );
  }
}
