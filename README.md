# Containerised Toolbox — Web Service Checker

## What it does
`checker` is a small shell script, packaged in its own Docker image, that
polls a web service (`web`) every 5 seconds via `curl`. For each request it
logs a timestamp, the HTTP status code, and the response time to
`/data/checker.log`. If the service is unreachable, times out, or returns a
non-2xx status, it logs that as a failure instead of crashing.

## Services
- **web** — `nginx:alpine`, the service being monitored. Exposed on
  `localhost:8080`.
- **checker** — our own image, built from `Dockerfile`, running
  `checker.sh`. Talks to `web` over the Compose network at `http://web/`
  (by service name, not by IP or hardcoded port).

## How to run it
```bash
docker compose up --build
```
Then watch the log grow:
```bash
tail -f data/checker.log
```
Stop everything with:
```bash
docker compose down
```

## Files
- `checker.sh` — the polling loop. Configurable via `TARGET_URL` and
  `CHECK_INTERVAL` environment variables.
- `Dockerfile` — builds a small Debian-based image with `curl` installed
  and `checker.sh` as the entrypoint.
- `docker-compose.yml` — wires `checker` and `web` together on one
  network and mounts `./data` so the log survives container restarts.

## Group members
- <name 1>
- <name 2>
- <name 3>
