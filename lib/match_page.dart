import 'package:flutter/material.dart';

import 'package:pokematch/my_pokedex_page.dart';
import 'package:pokematch/pokeapi_service.dart';
import 'package:pokematch/pokemon.dart';
import 'package:pokematch/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Card que dá para arrastar: segue o dedo, inclina e voa para fora.
class SwipeCard extends StatefulWidget {
  const SwipeCard({super.key, required this.child, required this.onSwipe});

  final Widget child;
  // capture: direita ou cima. star: cima, o super like.
  final void Function(bool capture, {bool star}) onSwipe;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  Offset _offset = Offset.zero; // quanto o card já foi arrastado
  bool _dragging = false;
  bool _flying = false;
  bool _star = false; // voou para cima: super like

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _dragging = false;
      if (-_offset.dy > 100 && -_offset.dy > _offset.dx.abs()) {
        // Mais para cima do que para o lado: voa para cima.
        _flying = true;
        _star = true;
        _offset = Offset(_offset.dx, -1000);
      } else if (_offset.dx.abs() > 100) {
        // Passou do limite: voa para o lado em que estava, bem para fora.
        _flying = true;
        _offset = Offset(_offset.dx.sign * 1000, _offset.dy);
      } else {
        _offset = Offset.zero; // não passou: volta ao centro
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: enquanto o card voa, ninguém consegue agarrar ele.
    return IgnorePointer(
      ignoring: _flying,
      // GestureDetector percebe os gestos: aqui, arrastar (pan).
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) => setState(() => _offset += details.delta),
        onPanEnd: _onPanEnd,
        // AnimatedContainer anima sozinho quando o transform muda.
        // Arrastando: duração zero, o card cola no dedo. Soltou: anima.
        child: AnimatedContainer(
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          transformAlignment: Alignment.center,
          // Move o card e inclina um pouco conforme vai para o lado.
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0)
            ..rotateZ(_offset.dx / 600),
          // Terminou de voar: avisa a tela do monte.
          onEnd: () {
            if (_flying) widget.onSwipe(_star || _offset.dx > 0, star: _star);
          },
          child: widget.child,
        ),
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
  final List<Pokemon> _history = []; // os que saíram do monte, em ordem
  String _type = ''; // tipo escolhido no filtro; vazio = todos
  final Set<int> _stars = {}; // números de quem ganhou super like

  // Future = um valor que ainda vai chegar (a resposta da internet).
  // late: só é calculado no primeiro uso, quando já existe acesso a widget.
  late Future<void> _future = _loadDeck();

  // async/await: espera a lista chegar e embaralha o monte.
  Future<void> _loadDeck() async {
    final pokemons = await widget.service.fetchPokemons();
    // Com filtro, pergunta à API quem é daquele tipo (mais 1 requisição).
    final typeIds = _type.isEmpty
        ? null
        : await widget.service.fetchTypeIds(_type);
    // SharedPreferences guarda dados simples no aparelho (no Chrome, no
    // navegador). Aqui ele devolve os números que já foram capturados.
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('captured') ?? [];
    // setState: o contador fica fora do FutureBuilder, então avisamos.
    setState(() {
      _captured
        ..clear()
        ..addAll(pokemons.where((p) => savedIds.contains('${p.id}')));
      _stars
        ..clear()
        ..addAll((prefs.getStringList('stars') ?? []).map(int.parse));
      // O monte fica só com quem ainda não foi capturado e é do tipo.
      _deck =
          pokemons
              .where((p) => !_captured.contains(p))
              .where((p) => typeIds == null || typeIds.contains(p.id))
              .toList()
            ..shuffle();
      _history.clear(); // monte novo: não há o que desfazer
    });
  }

  // Grava no aparelho os números dos capturados, como texto.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('captured', [
      for (final pokemon in _captured) '${pokemon.id}',
    ]);
    // Super like: os números com estrela ficam numa lista à parte.
    await prefs.setStringList('stars', [for (final id in _stars) '$id']);
  }

  // setState avisa o Flutter: "algo mudou, desenhe a tela de novo".
  // star: super like, captura e ganha estrela.
  void _swipe(bool capture, {bool star = false}) {
    setState(() {
      final pokemon = _deck.removeAt(0);
      if (capture) _captured.add(pokemon);
      if (star) _stars.add(pokemon.id);
      _history.add(pokemon);
    });
    _save();
  }

  // Desfazer: o último que saiu volta para a frente do monte.
  // Se ele tinha sido capturado (ou ganhou super like), sai da mochila.
  void _undo() {
    setState(() {
      final pokemon = _history.removeLast();
      _captured.remove(pokemon);
      _stars.remove(pokemon.id);
      _deck.insert(0, pokemon);
    });
    _save();
  }

  // Navigator.push empilha uma nova tela sobre a atual.
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProfilePage(pokemon: _deck.first, service: widget.service),
      ),
    );
  }

  // Escolheu um tipo no menu: guarda e busca o monte de novo.
  void _filter(String type) {
    setState(() {
      _type = type;
      _future = _loadDeck();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_type.isEmpty ? 'PokéMatch' : 'PokéMatch: $_type'),
        actions: [
          // Desfazer: desligado (null) quando nada saiu do monte ainda.
          IconButton(
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: 'Desfazer',
            disabledColor: Colors.white38,
          ),
          // Menu do filtro: "todos" e cada um dos tipos.
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por tipo',
            onSelected: _filter,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: '',
                checked: _type.isEmpty,
                child: const Text('todos'),
              ),
              for (final type in pokemonTypes)
                CheckedPopupMenuItem(
                  value: type,
                  checked: _type == type,
                  child: Text(type),
                ),
            ],
          ),
          // Contador da mochila: tocar abre a Minha Pokédex.
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MyPokedexPage(captured: _captured, stars: _stars),
              ),
            ),
            child: Text(
              '🎒 ${_captured.length}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
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
                          // O card da frente dá para arrastar. A key faz o
                          // Flutter criar um SwipeCard novo a cada Pokémon.
                          SwipeCard(
                            key: ValueKey(_deck.first.id),
                            onSwipe: _swipe,
                            // Tocar no card (sem arrastar) abre o perfil.
                            child: GestureDetector(
                              onTap: _openProfile,
                              child: PokemonCard(pokemon: _deck.first),
                            ),
                          ),
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
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => _swipe(true, star: true),
                    icon: const Icon(Icons.star, color: Colors.blue, size: 48),
                  ),
                  const SizedBox(width: 24),
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
