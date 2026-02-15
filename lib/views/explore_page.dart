import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_tcg_12_02_2026/models/pokemon.dart';
import 'package:pokemon_tcg_12_02_2026/viewmodels/explore_viewmodel.dart';
import 'package:pokemon_tcg_12_02_2026/widgets/app_drawer.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ExploreViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreViewModel(),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<ExploreViewModel>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Explorer les cartes'),
            ),
            drawer: const AppDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(viewModel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ExploreViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text(viewModel.errorMessage!));
    }

    if (viewModel.cards.isEmpty) {
      return const Center(child: Text('Aucune carte disponible.'));
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: viewModel.cards.length + (viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= viewModel.cards.length) {
          return const Center(child: CircularProgressIndicator());
        }

        return _PokemonCard(pokemon: viewModel.cards[index]);
      },
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const _PokemonCard({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final imageUrl = pokemon.imageSmall;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
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
            child: Text(
              pokemon.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
