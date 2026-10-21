import 'package:flutter/material.dart';

import 'package:pokematch/pokemon.dart';

// Minha Pokédex: a grade com os Pokémon capturados.
class MyPokedexPage extends StatelessWidget {
  const MyPokedexPage({
    super.key,
    required this.captured,
    this.stars = const {},
  });

  final List<Pokemon> captured; // a lista veio do monte
  final Set<int> stars; // números de quem ganhou super like

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Pokédex')),
      body: captured.isEmpty
          ? const Center(child: Text('Ninguém capturado ainda.'))
          // GridView.count: uma grade com 3 por linha.
          : GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(12),
              children: [
                for (final pokemon in captured)
                  Card(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            pokemon.imageUrl,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.catching_pokemon, size: 48),
                          ),
                        ),
                        // Super like ganha uma estrela antes do nome.
                        Text(
                          stars.contains(pokemon.id)
                              ? '⭐ ${pokemon.name}'
                              : pokemon.name,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
