# PokéMatch — aula de Flutter

App no estilo Tinder feito durante uma aula de introdução ao Flutter. Aparece um card de Pokémon: arraste para a direita para capturar ou para a esquerda para rejeitar. Tocar no card abre o perfil do Pokémon, e os capturados ficam na sua Minha Pokédex, salvos no aparelho.

## Requisitos

- Flutter 3.32 ou mais novo (Dart 3.8+) para as etapas 1 a 6.
- A etapa 0 é a saída pura do `flutter create` e precisa de Flutter 3.47+.
- Confira com `flutter --version` nas máquinas antes da aula.

## Como rodar

```bash
flutter pub get
flutter run -d chrome
```

Na etapa 6, para ver que os capturados ficaram salvos, aperte F5 no Chrome com o app rodando. Não pare o `flutter run`: cada vez que ele começa, abre um Chrome limpo, sem nada salvo.

## Etapas (branches)

Cada branch parte da anterior. Se você se perder, troque para a branch da etapa atual.

| Branch | O que você aprende |
|---|---|
| `etapa-0-projeto-base` | Projeto criado e rodando no Chrome |
| `etapa-1-primeiro-widget` | `StatelessWidget`, hot reload, tema e barra do app |
| `etapa-2-card-pokemon` | Classe `Pokemon` e um card com dados fixos |
| `etapa-3-monte-api` | Pacote `http`, `PokeApiService`, `FutureBuilder`, monte embaralhado e botões de capturar e rejeitar |
| `etapa-4-arrastar` | `GestureDetector` e `AnimatedContainer`: o card segue o mouse, inclina e voa |
| `etapa-5-perfil-e-pokedex` | `Navigator.push` para o perfil e para a Minha Pokédex em grade |
| `etapa-6-salvar` | Pacote `shared_preferences` guardando os capturados |
| `main` | Versão final do app |

Se se perder, use:

```bash
git checkout <branch-da-etapa>
```

## Links úteis

- Documentação do Flutter: https://docs.flutter.dev
- API de Pokémon (PokeAPI): https://pokeapi.co
- Testar código Dart no navegador: https://dartpad.dev
