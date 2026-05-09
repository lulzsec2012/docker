# ENV DERP_DOMAIN your-hostname.com

FROM golang:alpine AS builder
ARG TAILSCALE_VERSION=v1.88.4

RUN apk add --no-cache git
RUN git clone --branch ${TAILSCALE_VERSION} --depth 1 https://github.com/tailscale/tailscale.git /tailscale
WORKDIR /tailscale

RUN sed -i 's/"udp",/"udp4",/' net/stunserver/stunserver.go

RUN go install ./cmd/derper
RUN go install ./cmd/tailscaled
RUN go install ./cmd/tailscale

# FROM alpine
FROM alpine
WORKDIR /app

# ========= CONFIG =========
# - derper args
ENV DERP_DOMAIN your-hostname.com
ENV DERP_ADDR 0.0.0.0:443
ENV DERP_HTTP_PORT 80
ENV DERP_HOST=127.0.0.1
ENV DERP_CERTS=/app/certs
ENV DERP_STUN true
ENV DERP_VERIFY_CLIENTS false
# =========================

RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/* /usr/bin/
COPY scripts/build_cert.sh /app/

# build self-signed certs && start derper
CMD sh /app/build_cert.sh && \
    # https://github.com/tailscale/tailscale/issues/2794
    derper \
    --hostname=$DERP_DOMAIN \
    --certmode=manual \
    --certdir=$DERP_CERTS \
    --stun=$DERP_STUN  \
    --a=$DERP_ADDR \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS
