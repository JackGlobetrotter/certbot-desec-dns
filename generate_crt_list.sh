#!/bin/sh
HAPROXY_CFG_LOCAL_PATH
CERT_DIR="/etc/letsencrypt/live"
CERT_DEST="${HAPROXY_CFG_LOCAL}/certs"
CERT_REMOTE_DEST="${HAPROXY_CFG_REMOTE}/certs"
: "${DESEC_CREDENTIALS:=/usr/local/etc/haproxy}"
CRT_LIST_PATH="${HAPROXY_CFG_LOCAL}/crt-list.txt"

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
    pem_combined_crt_list="$CERT_REMOTE_DEST/${domain_name}.pem"

    if [ -f "$fullchain" ] && [ -f "$privkey" ]; then
        echo "[INFO] Creating combined PEM: $pem_combined"
        mkdir -p /etc/haproxy/certs
        cat "$fullchain" "$privkey" > "$pem_combined"

        # Add to crt-list
        echo "$pem_combined $domain_name " >> "$CRT_LIST_PATH"
    fi
done

echo "[INFO] crt-list.txt generated at: $CRT_LIST_PATH"
