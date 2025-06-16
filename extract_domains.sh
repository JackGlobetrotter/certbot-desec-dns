#!/bin/sh
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"

# Extract domains from crt or acl rules
grep -E 'crt |hdr\(host\)' "$HAPROXY_CFG" | \
  sed -nE 's|.*crt /etc/ssl/private/([^ ]+)\.pem.*|\1|p; s|.*-i ([^ ]+).*|\1|p' | \
  sort -u
