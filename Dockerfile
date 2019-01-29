FROM debian:9.6-slim as builder

ARG PCRE_VERSION="8.42"
ARG PCRE_CHECKSUM="69acbc2fbdefb955d42a4c606dfde800c2885711d2979e356c0636efde9ec3b5"

ARG ZLIB_VERSION="1.2.11"
ARG ZLIB_CHECKSUM="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"

ARG OPENSSL_VERSION="1.1.1a"
ARG OPENSSL_CHECKSUM="fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41"

ARG NGINX_VERSION="1.15.8"
ARG NGINX_CHECKSUM="a8bdafbca87eb99813ae4fcac1ad0875bf725ce19eb265d28268c309b2b40787"
ARG NGINX_CONFIG="\
    --sbin-path=/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/tmp/nginx.pid \
    --http-log-path=/dev/stdout \
    --error-log-path=/dev/stdout \
    --http-client-body-temp-path=/tmp/client_temp \
    --http-proxy-temp-path=/tmp/proxy_temp \
    --http-fastcgi-temp-path=/tmp/fastcgi_temp \
    --http-uwsgi-temp-path=/tmp/uwsgi_temp \
    --http-scgi-temp-path=/tmp/scgi_temp \
    --with-pcre=/tmp/pcre-$PCRE_VERSION \
    --with-openssl=/tmp/openssl-$OPENSSL_VERSION \
    --with-zlib=/tmp/zlib-$ZLIB_VERSION \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --add-module=/tmp/ngx_brotli"

ADD https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VERSION.tar.gz /tmp/pcre.tar.gz
ADD https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz /tmp/openssl.tar.gz
ADD https://zlib.net/zlib-$ZLIB_VERSION.tar.gz /tmp/zlib.tar.gz
ADD https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz /tmp/nginx.tar.gz

# Download sources needed for the builds
WORKDIR /tmp
RUN if [ "$PCRE_CHECKSUM" != "$(sha256sum /tmp/pcre.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/pcre.tar.gz && \
    if [ "$ZLIB_CHECKSUM" != "$(sha256sum /tmp/zlib.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/zlib.tar.gz && \
    if [ "$OPENSSL_CHECKSUM" != "$(sha256sum /tmp/openssl.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/openssl.tar.gz && \
    if [ "$NGINX_CHECKSUM" != "$(sha256sum /tmp/nginx.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/nginx.tar.gz && \
    mv /tmp/nginx-$NGINX_VERSION /tmp/nginx

# Install required packages
RUN apt-get update && apt-get install -y git gcc g++ make curl build-essential checkinstall zlib1g-dev

# Build openssl from sources
WORKDIR /tmp/openssl-$OPENSSL_VERSION
RUN ./config --prefix=/usr/local --openssldir=/usr/local && \
    make && \
    make install && \
    rm -f /usr/bin/openssl && \
    ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl

# Generate self signed certificate
RUN export LD_LIBRARY_PATH=/usr/local/lib && \
    mkdir -p /etc/nginx/ssl && \
    openssl genrsa -out /etc/nginx/ssl/example.key 2048 && \
    openssl req -new -key /etc/nginx/ssl/example.key -out /etc/nginx/example.csr -subj "/C=US/ST=Alaska/L=Palmer/O=CTO/CN=localhost" && \
    openssl x509 -req -days 365 -in /etc/nginx/example.csr -signkey /etc/nginx/ssl/example.key -out /etc/nginx/ssl/example.crt

# Build nginx from sources
WORKDIR /tmp/nginx
RUN git clone --recurse-submodules https://github.com/google/ngx_brotli.git /tmp/ngx_brotli && \
    ./configure $NGINX_CONFIG && \
    make

# Build final image
FROM debian:9.6-slim

COPY --from=builder /tmp/nginx/objs/nginx /nginx
COPY --from=builder /tmp/nginx/html /etc/nginx/html
COPY --from=builder /etc/nginx/ssl /etc/nginx/ssl

COPY conf /etc/nginx

# Create the nginx user and allow it to run /nginx
RUN useradd -M -s /usr/sbin/nologin --uid 1066 --user-group nginx && \
    apt-get update && \
    apt-get install -y libcap2-bin && \
    setcap CAP_NET_BIND_SERVICE=+eip /nginx && \
    chown -R nginx. /etc/nginx

USER nginx

ENTRYPOINT ["/nginx", "-g", "daemon off;"]
