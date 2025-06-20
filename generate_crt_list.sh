#!/bin/sh

CERT_DIR="/etc/letsencrypt/live"
CERT_DEST="/etc/haproxy/certs"
: "${DESEC_CREDENTIALS:=/usr/local/etc/haproxy}"
CRT_LIST_PATH="${HAPROXY_CFG_DIR}/crt-list.txt"

echo "[INFO] Generating HAProxy crt-list from: $CERT_DIR"
mkdir -p "$(dirname "$CRT_LIST_PATH")"
mkdir -p "$CERT_DEST"
> "$CRT_LIST_PATH"  # Clear existing list

for domain in "$CERT_DIR"/*; do
    [ -d "$domain" ] || continue
    domain_name=$(basename "$domain")

    fullchain="$domain/fullchain.pem"
    privkey="$domain/privkey.pem"
    pem_combined="$CERT_DEST/${domain_name}.pem"

    if [ -f "$fullchain" ] && [ -f "$privkey" ]; then
        echo "[INFO] Creating combined PEM: $pem_combined"
        mkdir -p /etc/haproxy/certs
        cat "$fullchain" "$privkey" > "$pem_combined"

        # Add to crt-list
        echo "$pem_combined $domain_name " >> "$CRT_LIST_PATH"
    fi
done

echo "[INFO] crt-list.txt generated at: $CRT_LIST_PATH"
