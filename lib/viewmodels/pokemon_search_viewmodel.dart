import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pokemon_tcg_12_02_2026/models/pokemon.dart';

class PokemonSearchViewModel extends ChangeNotifier {
  final String _apiKey = const String.fromEnvironment('API_KEY');
  static const String _webProxyBaseUrl = String.fromEnvironment(
    'POKEMON_PROXY_URL',
    defaultValue: 'http://localhost:8787',
  );

  PokemonSearchViewModel();

  String _pokemonName = '';
  List<Pokemon> _results = [];
  bool _loading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  // Getters
  String get pokemonName => _pokemonName;
  List<Pokemon> get results => _results;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;

  /// Met à jour le nom du Pokémon à rechercher.
  void setPokemonName(String name) {
    _pokemonName = name;
    notifyListeners();
  }

  /// Recherche un Pokémon en utilisant l'API Pokémon TCG.
  Future<void> searchPokemon() async {
    if (_pokemonName.isEmpty) {
      _errorMessage = 'Veuillez entrer un nom de Pokémon';
      _results = [];
      _hasSearched = true;
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    _results = [];
    _hasSearched = true;
    notifyListeners();

    try {
      final response = await _fetchResponse();

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body) as Map<String, dynamic>;
        final data = decodedResponse['data'];

        if (data is List) {
          _results = data
              .whereType<Map<String, dynamic>>()
              .map(Pokemon.fromJson)
              .toList();
          _errorMessage = null;
        } else {
          _results = [];
          _errorMessage = 'Pokémon non trouvé';
        }
      } else if (response.statusCode == 504) {
        await _searchWithTcgdexFallback();
      } else {
        _results = [];
        _errorMessage =
            'Erreur lors de la requête (code ${response.statusCode})';
      }
    } catch (e) {
      _results = [];
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        _errorMessage =
            'Proxy local indisponible. Lance le proxy avec: node proxy/pokemon_proxy.js';
      } else {
        _errorMessage = 'Erreur: $e';
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Réinitialise les données et les erreurs.
  void clearSearch() {
    _pokemonName = '';
    _results = [];
    _errorMessage = null;
    _loading = false;
    _hasSearched = false;
    notifyListeners();
  }

  Future<http.Response> _fetchResponse() async {
    if (kIsWeb) {
      final proxyUri = Uri.parse('$_webProxyBaseUrl/cards').replace(
        queryParameters: {
          'name': _pokemonName.trim(),
          'pageSize': '24',
        },
      );
      return http.get(proxyUri, headers: const {'Accept': 'application/json'});
    }

    final directUri = Uri.https(
      'api.pokemontcg.io',
      '/v2/cards',
      {
        'q': 'name:${_pokemonName.trim()}',
        'pageSize': '24',
      },
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (_apiKey.isNotEmpty) 'X-Api-Key': _apiKey,
    };

    return http.get(directUri, headers: headers);
  }

  Future<void> _searchWithTcgdexFallback() async {
    final fallbackUri = Uri.https('api.tcgdex.net', '/v2/en/cards', {
      'name': _pokemonName.trim(),
    });

    final fallbackResponse = await http.get(
      fallbackUri,
      headers: const {'Accept': 'application/json'},
    );

    if (fallbackResponse.statusCode != 200) {
      _results = [];
      _errorMessage =
          'Erreur API principale (504) et fallback indisponible (${fallbackResponse.statusCode})';
      return;
    }

    final decoded = json.decode(fallbackResponse.body);
    if (decoded is! List) {
      _results = [];
      _errorMessage = 'Réponse fallback invalide';
      return;
    }

    _results = decoded.whereType<Map<String, dynamic>>().map((item) {
      final image = item['image']?.toString();
      final imageUrl = _normalizeTcgdexImage(image, highQuality: false);
      return Pokemon(
        id: item['id']?.toString() ?? '',
        name: item['name']?.toString() ?? '',
        imageSmall: imageUrl,
        imageLarge: _normalizeTcgdexImage(image, highQuality: true),
      );
    }).toList();

    _errorMessage = null;
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