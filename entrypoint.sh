#!/bin/sh

# Default values
: "${DESEC_PROPAGATION_SECONDS:=80}"
: "${SLEEP_TIME:=43200}"
: "${DESEC_CREDENTIALS:=/app/desec.ini}"

# Graceful shutdown handler
cleanup() {
  echo "[INFO] Caught signal. Exiting gracefully..."
  exit 0
}

# Trap common termination signals
trap cleanup INT TERM

# Create credentials file if not mounted and file doesn't exist
if [ ! -f "$DESEC_CREDENTIALS" ]; then
  if touch "$DESEC_CREDENTIALS" 2>/dev/null; then
    echo "dns_desec_token = $DESEC_API_KEY" > "$DESEC_CREDENTIALS"
    chmod 600 "$DESEC_CREDENTIALS"
    echo "[INFO] Created credentials file at $DESEC_CREDENTIALS"
  else
    echo "[WARN] Cannot write to $DESEC_CREDENTIALS; assuming it's mounted or provided"
  fi
else
  echo "[INFO] Using existing credentials file at $DESEC_CREDENTIALS"
fi

echo "[INFO] Extracting domains from HAProxy config..."
DOMAINS=$(sh /app/extract_domains.sh)

for DOMAIN in $DOMAINS; do
  if ! certbot certificates | grep -q "Domains:.*\b$DOMAIN\b"; then
    echo "[INFO] Issuing cert for new domain: $DOMAIN"
    certbot certonly \
      --authenticator dns-desec \
      --dns-desec-credentials "$DESEC_CREDENTIALS" \
      --dns-desec-propagation-seconds "$DESEC_PROPAGATION_SECONDS" \
      --non-interactive --agree-tos \
      -d "$DOMAIN"
  else
    echo "[INFO] Cert for $DOMAIN already exists. Skipping."
  fi
done

# Auto-renew loop with graceful termination
while true; do
  echo "[INFO] Running certbot renew..."
  certbot renew \
    --authenticator dns-desec \
    --dns-desec-credentials "$DESEC_CREDENTIALS" \
    --dns-desec-propagation-seconds "$DESEC_PROPAGATION_SECONDS"

  echo "[INFO] Sleeping for ${SLEEP_TIME} seconds..."
  sleep "$SLEEP_TIME" &
  wait $!  # Wait on sleep so signal traps are respected
done
