import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:pokematch/pokemon.dart';

// Serviço: a única classe do app que conversa com a PokeAPI.
// As telas pedem os dados para ele e não sabem nada de URL ou JSON.
class PokeApiService {
  // Busca os 151 primeiros Pokémon.
  // async/await: "await" espera a resposta chegar sem travar a tela.
  Future<List<Pokemon>> fetchPokemons() async {
    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=151'),
    );
    if (response.statusCode != 200) {
      throw Exception('A PokeAPI respondeu ${response.statusCode}');
    }
    return pokemonsFromJson(response.body);
  }

  // Busca tipos, altura e peso de um Pokémon pelo id.
  Future<PokemonDetails> fetchPokemonDetails(int id) async {
    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('A PokeAPI respondeu ${response.statusCode}');
    }
    return PokemonDetails.fromJson(jsonDecode(response.body));
  }
}
