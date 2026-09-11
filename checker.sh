#!/bin/sh
# checker.sh — periodically curl a web service and log its health.
# Handles: service not up yet, timeouts, non-200 responses.

set -u

TARGET="${TARGET_URL:-http://web/}"
INTERVAL="${CHECK_INTERVAL:-5}"
LOGFILE="${LOGFILE:-/data/checker.log}"

mkdir -p "$(dirname "$LOGFILE")"

echo "Starting checker: target=$TARGET interval=${INTERVAL}s" | tee -a "$LOGFILE"

while true; do
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # -s silent, -o discard body, -w print status+time, --max-time avoid hanging forever
  response=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 5 "$TARGET" 2>/dev/null)
  curl_exit=$?

  if [ "$curl_exit" -ne 0 ]; then
    echo "$timestamp DOWN target=$TARGET reason=curl-error-or-timeout" | tee -a "$LOGFILE"
  else
    http_code=$(echo "$response" | cut -d' ' -f1)
    time_total=$(echo "$response" | cut -d' ' -f2)

    if [ "$http_code" = "000" ]; then
      echo "$timestamp DOWN target=$TARGET reason=no-response" | tee -a "$LOGFILE"
    elif [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
      echo "$timestamp OK status=$http_code time=${time_total}s" | tee -a "$LOGFILE"
    else
      echo "$timestamp WARN status=$http_code time=${time_total}s" | tee -a "$LOGFILE"
    fi
  fi

  sleep "$INTERVAL"
done
