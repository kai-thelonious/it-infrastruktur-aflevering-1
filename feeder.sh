#!/bin/sh
# feeder.sh — fetches a real currency exchange rate from the internet,
# writes it as a static HTML page for nginx to serve, then re-checks
# nginx actually serves it correctly.

set -u

# Frankfurter: free, no API key required. Change from/to for other pairs.
API_URL="${API_URL:-https://api.frankfurter.app/latest?from=USD&to=DKK}"
WEB_CHECK_URL="${WEB_CHECK_URL:-http://web/}"
INTERVAL="${FEED_INTERVAL:-30}"
HTML_DIR="${HTML_DIR:-/data/www}"
LOGFILE="${LOGFILE:-/data/feeder.log}"

mkdir -p "$HTML_DIR" "$(dirname "$LOGFILE")"

log() {
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "$ts $1" | tee -a "$LOGFILE"
}

log "Starting feeder: api=$API_URL interval=${INTERVAL}s"

while true; do
  # --- 1. Fetch real data from the internet ---
  json=$(curl -sL --max-time 5 "$API_URL")
  fetch_exit=$?

  if [ "$fetch_exit" -ne 0 ] || [ -z "$json" ]; then
    log "FETCH_FAIL reason=curl-error-or-empty (keeping last known page)"
  elif ! echo "$json" | jq -e . >/dev/null 2>&1; then
    log "FETCH_FAIL reason=invalid-json (keeping last known page)"
  else
    base=$(echo "$json" | jq -r '.base // "unknown"')
    date_field=$(echo "$json" | jq -r '.date // "unknown"')
    # rates is an object like {"DKK": 6.9} — grab its single value+key generically
    quote_ccy=$(echo "$json" | jq -r '.rates | keys[0] // "unknown"')
    rate=$(echo "$json" | jq -r '.rates | .[keys[0]] // "unknown"')

    if [ "$rate" = "unknown" ] || [ "$rate" = "null" ]; then
      log "FETCH_FAIL reason=unexpected-json-shape"
    else
      # --- 2. Turn it into a page nginx can serve ---
      cat > "$HTML_DIR/index.html" <<HTML
<!DOCTYPE html>
<html>
<head><title>Exchange rate feed</title></head>
<body>
  <h1>${base} / ${quote_ccy} exchange rate</h1>
  <p>1 ${base} = ${rate} ${quote_ccy}</p>
  <p>Rate date: ${date_field}</p>
  <p><small>Fetched by feeder.sh at $(date -u +"%Y-%m-%dT%H:%M:%SZ")</small></p>
</body>
</html>
HTML
      log "FETCH_OK base=${base} quote=${quote_ccy} rate=${rate} date=${date_field}"
    fi
  fi

  # --- 3. Re-check that nginx is actually serving it correctly ---
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$WEB_CHECK_URL")
  check_exit=$?

  if [ "$check_exit" -ne 0 ]; then
    log "SERVE_DOWN reason=curl-error-or-timeout"
  elif [ "$status" -ge 200 ] && [ "$status" -lt 300 ]; then
    log "SERVE_OK status=$status"
  else
    log "SERVE_WARN status=$status"
  fi

  sleep "$INTERVAL"
done
