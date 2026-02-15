import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_tcg_12_02_2026/viewmodels/home_viewmodel.dart';
import 'package:pokemon_tcg_12_02_2026/widgets/app_drawer.dart';

// Page d'accueil avec un titre dynamique, utilisant un ViewModel pour 
// gérer l'état du titre et un Drawer pour la navigation.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override 
  Widget build(BuildContext context) {
    // Rend le ViewModel disponible aux descendants de HomePageContent
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const HomePageContent(),
    );
  }
}

// Contenu de la page d'accueil, affichant le titre et un message de 
// bienvenue. // Il écoute les changements du HomeViewModel pour 
// mettre à jour le titre en temps réel.
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.title),
      ),
      drawer: const AppDrawer(),
      body: Center(
       child: Text('Bienvenue sur la page d\'accueil'),
      ),
    );
  }
}