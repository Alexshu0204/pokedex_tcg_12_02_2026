import 'package:flutter/foundation.dart';

// Ceci est un ViewModel pour la page d'accueil de l'application. Il gère l'état 
// du titre affiché à l'utilisateur et fournit des méthodes pour le mettre à jour 
// ou le réinitialiser. En utilisant ChangeNotifier, il permet aux widgets qui écoutent 
// ce ViewModel de se reconstruire automatiquement lorsque le titre change.

// Permet de notifier les widgets quand l'état change
class HomeViewModel extends ChangeNotifier {
  String _title = 'Bienvenu dresseur !';

  // Getter pour accéder au titre actuel
  String get title => _title;

 // Méthode pour mettre à jour le titre et notifier les auditeurs
  void setTitle(String newTitle) {
    _title = newTitle;
    notifyListeners(); // Signal à Flutter de reconstruire les widgets dépendants
  }

  void resetTitle() {
    _title = 'Bienvenu dresseur !'; 
    notifyListeners(); // Signal à Flutter de reconstruire les widgets dépendants
  }
}