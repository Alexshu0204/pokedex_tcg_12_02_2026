# Pokedex TCG (Flutter)

Application Flutter de recherche/exploration de cartes Pokémon TCG.

## Pourquoi il y a un proxy ?

Sur Flutter Web, les appels HTTP directs vers certaines routes de l’API cartes peuvent être bloqués par le navigateur (CORS) ou renvoyer des erreurs réseau selon l’environnement.

Le proxy local (`proxy/pokemon_proxy.js`) sert d’intermédiaire :

- l’app Web appelle `http://localhost:8787/cards`
- le proxy appelle l’API distante Pokémon TCG
- le proxy renvoie la réponse JSON au navigateur avec les bons headers CORS

En résumé : le proxy existe pour rendre la recherche stable en Web local.

## Ce que fait le proxy

- endpoint local : `GET /cards?name=<pokemon>&pageSize=<n>`
- forward vers `https://api.pokemontcg.io/v2/cards?q=name:<pokemon>&pageSize=<n>`
- optionnel : ajoute la clé API via `POKEMON_TCG_API_KEY`

## Lancer le projet (Web)

1. Installer les dépendances Flutter :

```bash
flutter pub get
```

2. Démarrer le proxy (terminal 1) :

```bash
node proxy/pokemon_proxy.js
```

3. Lancer Flutter Web (terminal 2) :

```bash
flutter run -d chrome
```

## Variables utiles

- `POKEMON_TCG_API_KEY` : clé API utilisée par le proxy (optionnelle)
- `POKEMON_PROXY_URL` : URL du proxy côté app Flutter Web (défaut: `http://localhost:8787`)

Exemple PowerShell :

```powershell
$env:POKEMON_TCG_API_KEY="votre_cle"
node proxy/pokemon_proxy.js
```

## Note sur les données

L’application filtre les cartes incomplètes/inconnues pour éviter d’afficher des entrées sans nom exploitable ni image.
