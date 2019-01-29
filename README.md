# Nginx with built in support for TLS 1.3
Nginx and openssl built from source in a Docker image to provide out of the box TLS 1.3 support.

* Image includes pre-built, self signed key and certificate
* Container runs as non-root (user `nginx` is created and used) 

## Build
Build Docker image
```bash
docker build -t nginx-tls13:0.1 .
```

## Run
Start the Docker container with ports 80 and 443 exposed
```bash
docker run --name nginx -p 80:80 -p 443:443 nginx-tls13:0.1
```

## Openssl
For supporting the TLS 1.3, openssl 1.1.1 is needed

## Nginx
Current Nginx version is 1.15.8
