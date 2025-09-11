#!/bin/sh

HAPROXY_CFG="$HAPROXY_CFG_LOCAL/haproxy.cfg"

# --- 1. Extract domains from frontends with SSL ---
awk '
  BEGIN {
    in_frontend = 0
    has_ssl = 0
  }
  /^[ \t]*frontend[ \t]/ {
    in_frontend = 1
    has_ssl = 0
    next
  }
  /^[^ \t]/ {
    # New top-level block (e.g., backend)
    in_frontend = 0
    has_ssl = 0
  }
  in_frontend && /bind .* ssl/ {
    has_ssl = 1
  }
  in_frontend && has_ssl {
    print
  }
' "$HAPROXY_CFG" | \
grep -E 'hdr\(host\).* -i ' | \
sed -nE 's|.*-i (.*)|\1|p' | \
tr ' ' '\n' > /tmp/domains_frontend.txt

# --- 2. Extract domains from map files referenced in haproxy.cfg ---
# Extract map files
MAP_FILES=$(grep -oE 'map\([^)]*\)' "$HAPROXY_CFG" | sed -E 's/map\(([^)]*)\)/\1/')

: > /tmp/domains_map.txt
for f in $MAP_FILES; do
    # Remove HAProxy container prefix
    f="${f#$HAPROXY_CFG_REMOTE}"
    # Strip everything after the first comma (default backend)
    f="${f%%,*}"
    # Prepend certbot container prefix
    f="$HAPROXY_CFG_LOCAL$f"

    # Only process if file exists
    [ -f "$f" ] && awk '{sub(/#.*/,"")} NF {print $1}' "$f" >> /tmp/domains_map.txt
done

# --- 3. Combine, deduplicate, sort ---
cat /tmp/domains_frontend.txt /tmp/domains_map.txt | sort -u