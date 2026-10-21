import 'package:flutter/material.dart';

import 'package:pokematch/pokeapi_service.dart';
import 'package:pokematch/pokemon.dart';

// Perfil, como no app de namoro: foto, interesses (tipos), bio e medidas.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.pokemon, required this.service});

  final Pokemon pokemon; // veio do monte pelo Navigator.push
  final PokeApiService service; // o mesmo serviço do monte

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Guardado no State: se ficasse no build, cada redesenho buscaria de novo.
  late final Future<PokemonDetails> _future = widget.service
      .fetchPokemonDetails(widget.pokemon.id);

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    return Scaffold(
      // O Navigator põe a seta de voltar na AppBar sozinho.
      appBar: AppBar(title: Text(pokemon.name)),
      body: FutureBuilder<PokemonDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Não foi possível carregar'));
          }
          final details = snapshot.data!;
          // ListView: uma coluna que rola quando não cabe na tela.
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Image.network(
                pokemon.largeImageUrl,
                height: 240,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.catching_pokemon, size: 96),
              ),
              Text(pokemon.number),
              Text(
                pokemon.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Interesses: um Chip para cada tipo.
              Row(
                spacing: 8,
                children: [
                  for (final type in details.types) Chip(label: Text(type)),
                ],
              ),
              const SizedBox(height: 16),
              // A bio, montada no app com os dados da API.
              Text(
                'Oi! Sou do tipo ${details.types.join(' e ')}. Bora dar match?',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text('Altura: ${details.height} m'),
              Text('Peso: ${details.weight} kg'),
            ],
          );
        },
      ),
    );
  }
}
