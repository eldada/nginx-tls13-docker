# Docker image for Nginx with built in support for TLS 1.3
Nginx and openssl built from source in a Docker image to provide out of the box TLS 1.3 support.

* Image includes pre-built, self signed key and certificate
* Container runs as non-root (user `nginx` is created and used)
* Support for mounting custom configurations

## Build
Build Docker image
```bash
docker build -t nginx-tls13:0.1 .
```

## Run
### Simple setup
Start the Docker container with ports 80 and 443 exposed
```bash
docker run --name nginx -p 80:80 -p 443:443 nginx-tls13:0.1
```

### Override config
You can override default configuration files [nginx.conf](conf/nginx.conf) and [mime.types](conf/mime.types).
1. Create your custom `nginx.conf`
2. Mount the custom file to `/etc/nginx/nginx.conf`q
```bash
docker run --name nginx -p 80:80 -p 443:443 -v ${CUSTOM_NGINX_CONF}:/etc/nginx/nginx.conf nginx-tls13:0.1
```
Follow the same procedure to override `mime.types`.

### Add custom configuration
You can add custom configuration files to nginx
1. Prepare a directory for your configuration files
2. Prepare one or more configuration files with the `.conf` extension in the configuration directory
3. Mount the configuration directory to container's `/etc/nginx/conf.d`
```bash
docker run --name nginx -p 80:80 -p 443:443 -v ${PATH_TO_CONFIG_DIR}:/etc/nginx/conf.d nginx-tls13:0.1
```

### Add custom html
You can add a custom html directory
1. Prepare a directory with your custom html files (and any other resources needed)
2. Mount the htm directory to container's `/etc/nginx/html`
```bash
docker run --name nginx -p 80:80 -p 443:443 -v ${PATH_TO_HTML}:/etc/nginx/html nginx-tls13:0.1
```

## Openssl
For supporting the TLS 1.3, openssl 1.1.1 is used

## Nginx
Current Nginx version is 1.15.8
