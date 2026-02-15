import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pokemon_tcg_12_02_2026/models/pokemon.dart';

class ExploreViewModel extends ChangeNotifier {
  static const int _pageSize = 20;

  final List<Pokemon> _allCards = [];
  List<Pokemon> _visibleCards = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _errorMessage;

  List<Pokemon> get cards => _visibleCards;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _visibleCards.length < _allCards.length;

  ExploreViewModel() {
    loadInitialCards();
  }

  Future<void> loadInitialCards() async {
    _loading = true;
    _errorMessage = null;
    _allCards.clear();
    _visibleCards = [];
    notifyListeners();

    try {
      final uri = Uri.https('api.tcgdex.net', '/v2/en/cards');
      final response = await http.get(uri, headers: const {'Accept': 'application/json'});

      if (response.statusCode != 200) {
        _errorMessage = 'Erreur API exploration (code ${response.statusCode})';
        _loading = false;
        notifyListeners();
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        _errorMessage = 'Réponse API invalide';
        _loading = false;
        notifyListeners();
        return;
      }

      _allCards.addAll(
        decoded.whereType<Map<String, dynamic>>().map((item) {
          final image = _normalizeTcgdexImage(item['image']?.toString(), highQuality: false);
          return Pokemon(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            imageSmall: image,
            imageLarge: _normalizeTcgdexImage(item['image']?.toString(), highQuality: true),
          );
        }).where((pokemon) => pokemon.isKnownCard),
      );

      _visibleCards = _allCards.take(_pageSize).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) {
      return;
    }

    _loadingMore = true;
    notifyListeners();

    final nextCount = (_visibleCards.length + _pageSize).clamp(0, _allCards.length);
    _visibleCards = _allCards.take(nextCount).toList();

    _loadingMore = false;
    notifyListeners();
  }

  String? _normalizeTcgdexImage(String? image, {required bool highQuality}) {
    if (image == null || image.isEmpty) {
      return null;
    }

    if (image.endsWith('.png') || image.endsWith('.jpg') || image.endsWith('.webp')) {
      return image;
    }

    return '$image/${highQuality ? 'high' : 'low'}.webp';
  }
}
