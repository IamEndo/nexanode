FROM debian:bookworm-slim

# Ensure standard PATH is present for all users, all shells
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Create data dir (we'll run as root to avoid volume permission issues)
RUN mkdir -p /data /opt/nexa

# Minimal deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

# Nexa version & URL 2.1
ENV NEXA_VERSION=2.1.0.0
ENV NEXA_TARBALL=https://www.bitcoinunlimited.info/nexa/${NEXA_VERSION}/nexa-${NEXA_VERSION}-linux64.tar.gz

# Install nexad and nexa-cli
RUN curl -fL "$NEXA_TARBALL" -o /tmp/nexa.tar.gz \
 && tar -xzf /tmp/nexa.tar.gz -C /tmp \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexad /usr/local/bin/nexad \
 && install -m 0755 /tmp/nexa-${NEXA_VERSION}/bin/nexa-cli /usr/local/bin/nexa-cli \
 && rm -rf /tmp/nexa* \
 # Build-time sanity checks (fail build if missing)
 && /usr/local/bin/nexad -version \
 && /usr/local/bin/nexa-cli -version || true

EXPOSE 7228/tcp 7227/tcp

# IMPORTANT: use absolute path so Railway never needs PATH to find it
ENTRYPOINT ["/usr/local/bin/nexad"]
CMD [ \
  "-printtoconsole", \
  "-datadir=/data", \
  "-listen=1", \
  "-server=1", \
  "-rpcbind=127.0.0.1", \
  "-rpcallowip=127.0.0.1", \
  "-rpcport=7227" \
]
