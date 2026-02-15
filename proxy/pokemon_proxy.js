const http = require('http');
const { URL } = require('url');

const PORT = process.env.PORT || 8787;
const API_KEY = process.env.POKEMON_TCG_API_KEY || '';

function writeJson(res, status, body) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(JSON.stringify(body));
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    res.end();
    return;
  }

  const reqUrl = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === 'GET' && reqUrl.pathname === '/cards') {
    const name = (reqUrl.searchParams.get('name') || '').trim();
    const pageSize = reqUrl.searchParams.get('pageSize') || '24';

    if (!name) {
      writeJson(res, 400, { error: 'Missing query parameter: name' });
      return;
    }

    const apiUrl = new URL('https://api.pokemontcg.io/v2/cards');
    apiUrl.searchParams.set('q', `name:${name}`);
    apiUrl.searchParams.set('pageSize', pageSize);

    try {
      const headers = { Accept: 'application/json' };
      if (API_KEY) headers['X-Api-Key'] = API_KEY;

      const apiResponse = await fetch(apiUrl, { headers });
      const text = await apiResponse.text();

      res.writeHead(apiResponse.status, {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
      res.end(text);
    } catch (error) {
      writeJson(res, 502, { error: `Proxy fetch failed: ${String(error)}` });
    }
    return;
  }

  writeJson(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`Pokemon proxy listening on http://localhost:${PORT}`);
});
