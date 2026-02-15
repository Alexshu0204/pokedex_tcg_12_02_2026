import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_tcg_12_02_2026/models/pokemon.dart';
import 'package:pokemon_tcg_12_02_2026/viewmodels/pokemon_search_viewmodel.dart';
import 'package:pokemon_tcg_12_02_2026/widgets/app_drawer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PokemonSearchViewModel(),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<PokemonSearchViewModel>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Rechercher un Pokémon'),
            ),
            drawer: const AppDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: viewModel.setPokemonName,
                          onSubmitted: (_) => viewModel.searchPokemon(),
                          decoration: const InputDecoration(
                            labelText: 'Nom du Pokémon',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            viewModel.loading ? null : () => viewModel.searchPokemon(),
                        child: const Text('Rechercher'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildBody(viewModel)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(PokemonSearchViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text(viewModel.errorMessage!));
    }

    if (!viewModel.hasSearched) {
      return const Center(child: Text('Entrez un nom pour rechercher des cartes.'));
    }

    if (viewModel.results.isEmpty) {
      return const Center(child: Text('Aucun résultat.'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: viewModel.results.length,
      itemBuilder: (context, index) {
        final pokemon = viewModel.results[index];
        return _PokemonCard(pokemon: pokemon);
      },
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const _PokemonCard({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: pokemon.imageSmall != null && pokemon.imageSmall!.isNotEmpty
                ? Image.network(
                    pokemon.imageSmall!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.image_not_supported)),
                  )
                : const Center(child: Icon(Icons.catching_pokemon, size: 36)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pokemon.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  pokemon.setName ?? 'Set inconnu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}