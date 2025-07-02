#!/bin/sh

HAPROXY_CFG="/etc/haproxy/haproxy.cfg"

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
tr ' ' '\n' | \
sort -u
