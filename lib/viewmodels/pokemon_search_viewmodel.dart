import 'dart:async';
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
  List<String> _suggestions = [];
  bool _loading = false;
  bool _loadingSuggestions = false;
  String? _errorMessage;
  bool _hasSearched = false;
  Timer? _suggestionDebounce;
  int _suggestionRequestId = 0;

  // Getters
  String get pokemonName => _pokemonName;
  List<Pokemon> get results => _results;
  List<String> get suggestions => _suggestions;
  bool get loading => _loading;
  bool get loadingSuggestions => _loadingSuggestions;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;

  /// Met à jour le nom du Pokémon à rechercher.
  void setPokemonName(String name) {
    _pokemonName = name;
    notifyListeners();
  }

  void onSearchInputChanged(String name) {
    _pokemonName = name;
    _debounceSuggestions();
    notifyListeners();
  }

  void selectSuggestion(String name) {
    _pokemonName = name;
    _suggestions = [];
    notifyListeners();
  }

  void _debounceSuggestions() {
    _suggestionDebounce?.cancel();

    final query = _pokemonName.trim();
    if (query.length < 2) {
      _loadingSuggestions = false;
      _suggestions = [];
      return;
    }

    _loadingSuggestions = true;
    _suggestionDebounce = Timer(const Duration(milliseconds: 320), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final currentRequestId = ++_suggestionRequestId;

    try {
      final uri = Uri.https('api.tcgdex.net', '/v2/en/cards', {'name': query});
      final response = await http.get(uri, headers: const {'Accept': 'application/json'});

      if (currentRequestId != _suggestionRequestId) {
        return;
      }

      if (response.statusCode != 200) {
        _suggestions = [];
        _loadingSuggestions = false;
        notifyListeners();
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        _suggestions = [];
        _loadingSuggestions = false;
        notifyListeners();
        return;
      }

      final normalizedQuery = query.toLowerCase();
      final names = <String>[];
      final seen = <String>{};

      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        final rawName = item['name']?.toString().trim();
        if (rawName == null || rawName.isEmpty) {
          continue;
        }

        final lower = rawName.toLowerCase();
        if (seen.contains(lower)) {
          continue;
        }

        if (!lower.contains(normalizedQuery)) {
          continue;
        }

        seen.add(lower);
        names.add(rawName);
      }

      names.sort((a, b) {
        final aStarts = a.toLowerCase().startsWith(normalizedQuery);
        final bStarts = b.toLowerCase().startsWith(normalizedQuery);
        if (aStarts == bStarts) {
          return a.compareTo(b);
        }
        return aStarts ? -1 : 1;
      });

      _suggestions = names.take(8).toList();
    } catch (_) {
      _suggestions = [];
    } finally {
      if (currentRequestId == _suggestionRequestId) {
        _loadingSuggestions = false;
        notifyListeners();
      }
    }
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
    _suggestions = [];
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
              .where((pokemon) => pokemon.isKnownCard)
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
    _suggestionDebounce?.cancel();
    _pokemonName = '';
    _results = [];
    _suggestions = [];
    _loadingSuggestions = false;
    _errorMessage = null;
    _loading = false;
    _hasSearched = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    super.dispose();
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
    }).where((pokemon) => pokemon.isKnownCard).toList();

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