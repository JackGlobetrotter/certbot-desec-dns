FROM certbot/certbot:latest

LABEL org.opencontainers.image.authors="JackGlobetrotter <JackGlobetrotter@gmail.com>"
LABEL org.opencontainers.image.description="Certbot with the certbot-dns-desec plugin and HAProxy integration"

# Install the deSEC DNS plugin
RUN pip install --no-cache-dir certbot-dns-desec

# Copy scripts
COPY extract_domains.sh /app/extract_domains.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY generate_crt_list.sh /app/generate_crt_list.sh
COPY healthcheck.sh /app/healthcheck.sh

RUN chmod +x /app/*.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh
  
# Entrypoint: checks & daemonizes
ENTRYPOINT ["/app/entrypoint.sh"]
