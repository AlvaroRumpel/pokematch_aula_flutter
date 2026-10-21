import 'package:flutter/material.dart';

import 'package:pokematch/match_page.dart';
import 'package:pokematch/pokeapi_service.dart';

void main() => runApp(const PokeMatchApp());

// Tudo no Flutter é widget: o app, a tela, o texto e até o espaçamento.
// Por isso o app inteiro começa com uma classe "widget" como esta.
class PokeMatchApp extends StatelessWidget {
  const PokeMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokéMatch',
      debugShowCheckedModeBanner: false,
      // Tema: define as cores e o estilo de todo o app de uma vez só.
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFCC0000),
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCC0000),
          foregroundColor: Colors.white,
        ),
      ),
      // A primeira tela do app. Ela recebe o serviço que busca os Pokémon.
      home: MatchPage(service: PokeApiService()),
    );
  }
}
