import 'dart:convert';

import 'package:flutter/material.dart' show Color;

// Modelo de dados: descreve um Pokémon com só o que o card precisa.
class Pokemon {
  final int id;
  final String name;

  const Pokemon({required this.id, required this.name});

  // Cria um Pokémon a partir do JSON da lista: {"name": "...", "url": ".../pokemon/25/"}
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    // A url termina com o id e uma barra: o id é o penúltimo pedaço.
    final parts = (json['url'] as String).split('/');
    return Pokemon(
      id: int.parse(parts[parts.length - 2]),
      name: name[0].toUpperCase() + name.substring(1), // 1ª letra maiúscula
    );
  }

  // Número com 3 dígitos: 1 vira '#001'.
  String get number => '#${id.toString().padLeft(3, '0')}';

  static const _base =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

  // Imagem pequena (sprite), usada na grade da Minha Pokédex.
  String get imageUrl => '$_base/$id.png';

  // Imagem grande (artwork oficial), usada no card e no perfil.
  String get largeImageUrl => '$_base/other/official-artwork/$id.png';
}

// Transforma o texto JSON da resposta numa lista de Pokémon.
List<Pokemon> pokemonsFromJson(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final results = data['results'] as List;
  return results
      .map((item) => Pokemon.fromJson(item as Map<String, dynamic>))
      .toList();
}

// Detalhes de um Pokémon para o perfil: tipos, altura e peso.
class PokemonDetails {
  final List<String> types;
  final double height; // em metros
  final double weight; // em quilos

  const PokemonDetails({
    required this.types,
    required this.height,
    required this.weight,
  });

  // Lê o JSON de /pokemon/{id}. Os tipos ficam em types[].type.name.
  // A API manda altura em decímetros e peso em hectogramas: dividimos por 10.
  factory PokemonDetails.fromJson(Map<String, dynamic> json) {
    return PokemonDetails(
      types: [for (final t in json['types']) t['type']['name'] as String],
      height: json['height'] / 10,
      weight: json['weight'] / 10,
    );
  }
}

// Cor de cada tipo (todas têm bom contraste com texto branco).
// As chaves também servem de lista com todos os tipos.
const typeColors = {
  'grass': Color(0xFF3F7F2F),
  'poison': Color(0xFF8A3F9E),
  'fire': Color(0xFFC8501E),
  'water': Color(0xFF2A6DD7),
  'bug': Color(0xFF6B7F1A),
  'normal': Color(0xFF6E6E5A),
  'electric': Color(0xFF9A7B00),
  'ground': Color(0xFF8A6A2F),
  'fairy': Color(0xFFB0477F),
  'fighting': Color(0xFFA0302A),
  'psychic': Color(0xFFC23B6E),
  'rock': Color(0xFF7F6F2A),
  'ghost': Color(0xFF5A4A8A),
  'ice': Color(0xFF3E8C8C),
  'dragon': Color(0xFF5530C8),
  'flying': Color(0xFF6A5ACD),
  'steel': Color(0xFF6A6A80),
};

// Tipo que não veio (ou desconhecido): cinza.
Color typeColor(String? type) => typeColors[type] ?? const Color(0xFF5F5F5F);
