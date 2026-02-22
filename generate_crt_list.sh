#!/bin/sh

CERT_DIR="/etc/letsencrypt/live"
CERT_DEST="${HAPROXY_CFG_LOCAL}/certs"
CERT_REMOTE_DEST="${HAPROXY_CFG_REMOTE}/certs"
: "${DESEC_CREDENTIALS:=/usr/local/etc/haproxy}"
CRT_LIST_PATH="${HAPROXY_CFG_LOCAL}/crt-list.txt"


: "${COMBINE_CERTIFICATES:=false}"   # Default: combine certs
: "${USE_HAPROXY:=false}"            # Default: generate crt-list

echo "[INFO] Processing certificates from: $CERT_DIR"
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
        if [ "$COMBINE_CERTIFICATES" = "true" ]; then
            echo "[INFO] Creating combined PEM: $pem_combined"
            cat "$fullchain" "$privkey" > "$pem_combined"
        else
            echo "[INFO] Skipping PEM combination for $domain_name"
        fi

        if [ "$USE_HAPROXY" = "true" ]; then
            echo "$pem_combined_crt_list $domain_name" >> "$CRT_LIST_PATH"
        fi
    fi

done

if [ "$USE_HAPROXY" = "true" ]; then
    echo "[INFO] crt-list.txt generated at: $CRT_LIST_PATH"
else
    echo "[INFO] crt-list.txt generation skipped (USE_HAPROXY=false)"
fi

echo "[INFO] crt-list.txt generated at: $CRT_LIST_PATH"
