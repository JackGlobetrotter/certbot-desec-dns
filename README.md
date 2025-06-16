##Environment 
Settings can be changed in .env file

##Run

```
docker build -t certbot/certbot-dns-desec:latest .

```

##Build

```
docker run -d \
  --name certbot-desec \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /etc/haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg:ro \
  -v /etc/letsencrypt/desec.ini:/secrets/desec.ini:ro \
  certbot/certbot-dns-desec:latest
```
