FROM certbot/certbot:latest

LABEL maintainer="JackGlobetrotter <JackGlobetrotter@gmail.com>"
LABEL description="Certbot with the certbot-dns-desec plugin and HAProxy integration"

# Install the deSEC DNS plugin
RUN pip install --no-cache-dir certbot-dns-desec

# Copy scripts
COPY extract_domains.sh /app/extract_domains.sh
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/*.sh

# Entrypoint: checks & daemonizes
ENTRYPOINT ["/app/entrypoint.sh"]
