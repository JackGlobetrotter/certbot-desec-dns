#!/bin/sh

CERT_DIR="/etc/letsencrypt/live"
CRT_LIST_PATH="/etc/haproxy/crt-list.txt"

echo "[INFO] Generating HAProxy crt-list from: $CERT_DIR"
mkdir -p "$(dirname "$CRT_LIST_PATH")"
> "$CRT_LIST_PATH"

for domain in "$CERT_DIR"/*; do
    [ -d "$domain" ] || continue
    domain_name=$(basename "$domain")

    fullchain="$domain/fullchain.pem"
    privkey="$domain/privkey.pem"
    pem_combined="/etc/haproxy/certs/${domain_name}.pem"

    if [ -f "$fullchain" ] && [ -f "$privkey" ]; then
        echo "[INFO] Creating combined PEM: $pem_combined"
        mkdir -p /etc/haproxy/certs
        cat "$fullchain" "$privkey" > "$pem_combined"

        # Add to crt-list
        echo "$domain_name $pem_combined" >> "$CRT_LIST_PATH"
    fi
done

echo "[INFO] crt-list.txt generated at: $CRT_LIST_PATH"
