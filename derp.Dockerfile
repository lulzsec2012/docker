FROM golang:alpine AS builder
ARG TAILSCALE_VERSION=v1.92.2

RUN apk add --no-cache git
RUN git clone --branch ${TAILSCALE_VERSION} --depth 1 https://github.com/tailscale/tailscale.git /tailscale
WORKDIR /tailscale

# Force STUN to use IPv4-only socket (required for environments without IPv6, e.g. Tencent Cloud)
RUN sed -i 's/"udp",/"udp4",/' net/stunserver/stunserver.go

RUN go install ./cmd/derper ./cmd/tailscaled ./cmd/tailscale

FROM alpine
WORKDIR /app

# ========= DERP Configuration =========
# Override these at `docker run -e` for your environment
ENV DERP_DOMAIN your-hostname.com
ENV DERP_ADDR 0.0.0.0:443
ENV DERP_HTTP_PORT 80
ENV DERP_HOST=127.0.0.1
ENV DERP_CERTS=/app/certs
ENV DERP_STUN true
ENV DERP_VERIFY_CLIENTS false
# ======================================

RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/* /usr/bin/
COPY scripts/build_cert.sh /app/

# build_cert.sh: generates self-signed certs, authenticates tailscale, then hands off to derper
CMD sh /app/build_cert.sh && \
    derper \
    --hostname=$DERP_DOMAIN \
    --certmode=manual \
    --certdir=$DERP_CERTS \
    --stun=$DERP_STUN  \
    --a=$DERP_ADDR \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS
