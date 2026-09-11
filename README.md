# Containerised Toolbox — Exchange Rate Feeder

## What it does
`feeder` is a shell script, packaged in its own Docker image, that every
30 seconds:

1. Fetches the current USD/DKK exchange rate from
   [Frankfurter](https://www.frankfurter.app) — a free, key-free currency
   API backed by ECB reference rates.
2. Parses the rate and date out of the JSON response with `jq`.
3. Writes that data into a small static HTML page in a folder shared with
   `web` (nginx).
4. Curls `web` itself to confirm nginx is actually serving the page with a
   2xx status, logging the result.

If the fetch to Frankfurter fails (timeout, bad response, unexpected JSON
shape), the script logs the failure, keeps the previously-generated page in
place, and tries again next cycle — it never crashes the loop.

## Services
- **web** — `nginx:alpine`. Serves whatever `feeder` has written into
  `./data/www`. Mounted read-only, since nginx should only ever *read*
  this content. Exposed on `localhost:8080`.
- **feeder** — our own image, built from `Dockerfile`, running
  `feeder.sh`. Reaches `web` at `http://web/` by Compose service name.
  Talks to the outside internet only to reach the Frankfurter API.

## How to run it
```bash
docker compose up --build
```
Then open `http://localhost:8080` in a browser to see the generated rate
page, or watch the log:
```bash
tail -f data/feeder.log
```
Stop everything with:
```bash
docker compose down
```

## Changing the currency pair or data source
Edit `API_URL` in `docker-compose.yml`, e.g.
`https://api.frankfurter.app/latest?from=EUR&to=GBP`. To switch to crypto
prices instead, point `API_URL` at CoinGecko
(`https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd`)
and adjust the `jq` filters in `feeder.sh` to match its JSON shape.

## Files
- `feeder.sh` — fetches the exchange rate, writes the HTML page, and
  self-checks that nginx serves it. Configurable via `API_URL`,
  `WEB_CHECK_URL`, and `FEED_INTERVAL` environment variables.
- `Dockerfile` — Debian-based image with `curl` and `jq` installed.
- `docker-compose.yml` — wires `feeder` and `web` together, sharing
  `./data/www` so feeder's output becomes nginx's content.

