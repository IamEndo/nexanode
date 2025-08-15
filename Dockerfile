# ---- Base: clean, no VOLUME baked in ----
FROM ubuntu:22.04

# ---- Create non-root user & dirs ----
RUN useradd -m -u 10001 app \
 && mkdir -p /data /opt/nexa \
 && chown -R app:app /data /opt/nexa

# ---- Minimal runtime deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

# ---- Pin Nexa version (update when a new release ships) ----
ENV NEXA_VERSION=2.0.0.0
ENV NEXA_TARBALL=https://bitcoinunlimited.info/nexa/${NEXA_VERSION}/nexa-${NEXA_VERSION}-linux64.tar.gz

# ---- Download & install official binaries ----
RUN curl -L "$NEXA_TARBALL" -o /tmp/nexa.tar.gz \
 && tar -xzf /tmp/nexa.tar.gz -C /tmp \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexad /usr/local/bin/nexad \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexacli /usr/local/bin/nexacli \
 && rm -rf /tmp/nexa* 

# Document P2P port (actual exposure happens via Railway TCP Proxy)
EXPOSE 7228/tcp

# ---- Run as non-root ----
USER app

# ---- Default: P2P-only relay; RPC local-only for health checks ----
ENTRYPOINT ["nexad"]
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
