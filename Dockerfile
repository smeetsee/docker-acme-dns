FROM golang:latest AS builder

# Based on https://github.com/smeetsee/docker-xteve/blob/5aec1fd39de1c6bcf50118dda5beeac9c75b1dd5/Dockerfile.pterodactyl
RUN git clone https://github.com/joohoi/acme-dns /opt/acme-dns && \
    cd /opt/acme-dns && \
    export GOPATH=/tmp/acme-dns && \
    go build


FROM alpine:3.18

# bash for entrypoint script, and also based on https://github.com/joohoi/acme-dns/blob/27e8251d11ba0a08c9b576fc04d61c1c7ba9b500/Dockerfile and https://github.com/containous/traefik-library-image/pull/84/files
RUN apk add --no-cache bash ca-certificates libcap && update-ca-certificates
# Based on https://stackoverflow.com/a/49955098/2378368 and https://stackoverflow.com/a/63110882/2378368
RUN addgroup -g 2001 -S acme-dns && adduser -D -h /home/container -u 1001 -S container -G acme-dns
# Partially based on https://github.com/alturismo/xteve/blob/master/Dockerfile
VOLUME /home/container


# Symlink configuration directories into /home/container
RUN ln -s /home/container/etc /etc/acme-dns && ln -s /home/container/var/lib /var/lib/acme-dns

# Copy acme-dns binary
COPY --from=builder /opt/acme-dns/acme-dns /usr/local/bin/acme-dns
# Give permissions to bind to well-known ports for non-root users
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/acme-dns

EXPOSE 53 80 443
EXPOSE 53/udp

# Set user, based on https://stackoverflow.com/a/49955098/2378368
USER container
ENV  USER=container HOME=/home/container

WORKDIR /home/container
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]