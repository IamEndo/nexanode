# Small, modern base with needed libs
FROM ubuntu:22.04

# Create non-root user (safety) and folders
RUN useradd -m -u 10001 app && mkdir -p /data /opt/nexa && chown -R app:app /data /opt/nexa

# Minimal runtime deps + tools to verify/download
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

# Set Nexa version here (update when new releases come out)
ENV NEXA_VERSION=2.0.0.0
ENV NEXA_TARBALL=https://bitcoinunlimited.info/nexa/${NEXA_VERSION}/nexa-${NEXA_VERSION}-linux64.tar.gz

# Download and install the official linux64 binaries
RUN curl -L "$NEXA_TAR_
