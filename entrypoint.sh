#!/bin/sh

# Default values
: "${DESEC_PROPAGATION_SECONDS:=80}"
: "${SLEEP_TIME:=43200}"
: "${DESEC_CREDENTIALS:=/app/desec.ini}"

STATUS_FILE="/app/status"
echo "unknown" > /app/status 
set_status() {
  printf "%s" "$1" > "$STATUS_FILE"
  echo "[STATUS] $1"
}

# Graceful shutdown
cleanup() {
  echo "[INFO] Caught signal. Exiting gracefully..."
  exit 0
}
trap cleanup INT TERM

set_status "starting"

# Create credentials file if needed
if [ ! -f "$DESEC_CREDENTIALS" ]; then
  if touch "$DESEC_CREDENTIALS" 2>/dev/null; then
    echo "dns_desec_token = $DESEC_API_KEY" > "$DESEC_CREDENTIALS"
    chmod 600 "$DESEC_CREDENTIALS"
    echo "[INFO] Created credentials file at $DESEC_CREDENTIALS"
  else
    echo "[WARN] Cannot write to $DESEC_CREDENTIALS; assuming it's mounted"
  fi
else
  echo "[INFO] Using existing credentials file at $DESEC_CREDENTIALS"
fi

# Gather domains
ALL_DOMAINS=""

# From DOMAINS env
if [ -n "$DOMAINS" ]; then
  echo "[INFO] Adding domains from DOMAINS env"
  ALL_DOMAINS="$ALL_DOMAINS $DOMAINS"
fi

# From HAProxy config
if [ "$USE_HAPROXY" = "true" ]; then
  if [ -f /etc/haproxy/haproxy.cfg ]; then
    echo "[INFO] Extracting domains from HAProxy config..."
    HAPROXY_DOMAINS=$(sh /app/extract_domains.sh)
    ALL_DOMAINS="$ALL_DOMAINS $HAPROXY_DOMAINS"
  else
    echo "[WARN] USE_HAPROXY is true but /etc/haproxy/haproxy.cfg not found."
  fi
fi

# Deduplicate and trim
UNIQ_DOMAINS=$(echo "$ALL_DOMAINS" | tr ' ' '\n' | awk NF | sort -u)

# Ensure at least one source
if [ -z "$UNIQ_DOMAINS" ]; then
  echo "[ERROR] No domains found. You must set DOMAINS or USE_HAPROXY=true."
  exit 1
fi

# Issue certificates for new domains
for DOMAIN in $UNIQ_DOMAINS; do
  if ! certbot certificates | grep -q "Domains:.*\b$DOMAIN\b"; then
    echo "[INFO] Issuing cert for new domain: $DOMAIN"
    certbot certonly \
      --authenticator dns-desec \
      --dns-desec-credentials "$DESEC_CREDENTIALS" \
      --dns-desec-propagation-seconds "$DESEC_PROPAGATION_SECONDS" \
      --non-interactive --agree-tos \
      -d "$DOMAIN"
    if  [ "$USE_HAPROXY" = "true" ] || [ "$COMBINE_CERTIFICATES" = "true" ]; then
      /app/generate_crt_list.sh
    fi
  else
    echo "[INFO] Cert for $DOMAIN already exists. Skipping."
  fi
done

# Renewal loop
while true; do
  echo "[INFO] Running certbot renew..."
  set_status "renewing"
  certbot renew \
    --authenticator dns-desec \
    --dns-desec-credentials "$DESEC_CREDENTIALS" \
    --dns-desec-propagation-seconds "$DESEC_PROPAGATION_SECONDS"
  set_status "healthy"
  if [ "$USE_HAPROXY" = "true" ]; then
    /app/generate_crt_list.sh
  fi
  echo "[INFO] Sleeping for ${SLEEP_TIME} seconds..."
  sleep "$SLEEP_TIME" &
  wait $!
done
