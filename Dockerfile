FROM debian:bookworm-slim

# Create non-root user & directories
RUN useradd -m -u 10001 app \
 && mkdir -p /data /opt/nexa \
 && chown -R app:app /data /opt/nexa

# Minimal deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

# Set Nexa version (2.0.0.0 is the mandatory upgrade series)
ENV NEXA_VERSION=2.0.0.0
ENV NEXA_TARBALL=https://www.bitcoinunlimited.info/nexa/${NEXA_VERSION}/nexa-${NEXA_VERSION}-linux64.tar.gz

# Download & install Nexa
RUN curl -fL "$NEXA_TARBALL" -o /tmp/nexa.tar.gz \
 && tar -xzf /tmp/nexa.tar.gz -C /tmp \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexad /usr/local/bin/nexad \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexa-cli /usr/local/bin/nexa-cli \
 && rm -rf /tmp/nexa* \
 # ----- Build-time sanity checks -----
 && /usr/local/bin/nexad -version \
 && /usr/local/bin/nexa-cli -version || true

EXPOSE 7228/tcp 7227/tcp

USER app

# Keep defaults simple; Railway can pass extra args
ENTRYPOINT ["/usr/local/bin/nexad"]
CMD ["-printtoconsole",
     "-datadir=/data",
     "-listen=1",
     "-port=7228",
     "-dnsseed=1",
     "-upnp=0",
     "-txindex=0",
     "-dbcache=600",
     "-maxconnections=96",
     "-server=1",
     "-rpcbind=127.0.0.1",
     "-rpcallowip=127.0.0.1",
     "-rpcport=7227"]
