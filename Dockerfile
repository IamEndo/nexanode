# ---------------------------------------------------------------------------
# Stage 1: download the official Nexa release and verify its checksum.
# The download credentials are used only in this stage, so they never end up
# in the runtime image.
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS fetch

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

# Nexa version, download URL and expected sha256 of the linux64 tarball
ENV NEXA_VERSION=2.2.0.1
ENV NEXA_TARBALL=https://nexa.org/api/node/private/download/nexa-${NEXA_VERSION}-linux64.tar.gz
ENV NEXA_SHA256=f95c2e14e1fa8601a1ecb5afc54c317fe4647019489bf4180ec1840b436db698

# Login for the private download area. Set these as Railway service variables
# (NEXA_DL_USER / NEXA_DL_PASS); they are NOT stored in this repository.
# Leave them unset once the release is on a public URL.
ARG NEXA_DL_USER=""
ARG NEXA_DL_PASS=""

RUN set -eu; \
    if [ -n "$NEXA_DL_USER" ]; then \
      printf 'user = "%s:%s"\n' "$NEXA_DL_USER" "$NEXA_DL_PASS" > /tmp/curl.auth; \
    else \
      : > /tmp/curl.auth; \
    fi; \
    curl -fL --config /tmp/curl.auth "$NEXA_TARBALL" -o /tmp/nexa.tar.gz; \
    rm -f /tmp/curl.auth; \
    echo "${NEXA_SHA256}  /tmp/nexa.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/nexa; \
    tar -xzf /tmp/nexa.tar.gz -C /opt/nexa --strip-components=1; \
    /opt/nexa/bin/nexad -version; \
    /opt/nexa/bin/nexa-cli -version

# ---------------------------------------------------------------------------
# Stage 2: runtime image
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim

# Ensure standard PATH is present for all users, all shells
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Create data dir (we'll run as root to avoid volume permission issues)
RUN mkdir -p /data /opt/nexa

# Minimal deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

COPY --from=fetch /opt/nexa/bin/nexad /usr/local/bin/nexad
COPY --from=fetch /opt/nexa/bin/nexa-cli /usr/local/bin/nexa-cli

# Sanity checks in the runtime image (fail the build if a binary cannot run)
RUN /usr/local/bin/nexad -version && /usr/local/bin/nexa-cli -version

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
