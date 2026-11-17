# ---------------------------------------------------------------------------
# Stage 1: build nexad / nexa-cli from source (unreleased fixes after 2.2.0.0)
# ---------------------------------------------------------------------------
FROM debian:bookworm AS builder

# Pinned commit on the official dev branch (https://gitlab.com/nexa/nexa).
# 2026-11-09: includes the INV2 whitelist fix and libevent 2.1.13 bump.
ENV NEXA_REPO=https://gitlab.com/nexa/nexa.git
ENV NEXA_COMMIT=df4ff0e5ba34882d53601398eff49710bc2a78a6
ENV NEXA_HOST=x86_64-pc-linux-gnu

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libtool autotools-dev autoconf automake pkg-config \
    bsdmainutils git curl ca-certificates python3 bison patch \
    xz-utils bzip2 unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone "$NEXA_REPO" nexa \
 && cd nexa \
 && git checkout --detach "$NEXA_COMMIT" \
 && test "$(git rev-parse HEAD)" = "$NEXA_COMMIT"

WORKDIR /src/nexa

# Official dependency build (static boost, libevent 2.1.13, bdb, zeromq, gmp...)
RUN JOBS="$(nproc)"; [ "$JOBS" -gt 8 ] && JOBS=8; \
    make -C depends HOST="$NEXA_HOST" NO_QT=1 NO_RUST=1 -j"$JOBS"

RUN JOBS="$(nproc)"; [ "$JOBS" -gt 8 ] && JOBS=8; \
    ./autogen.sh \
 && ./configure --prefix="$PWD/depends/$NEXA_HOST" \
      --with-gui=no --disable-tests --disable-bench --enable-reduce-exports \
 && make -j"$JOBS" \
 && strip src/nexad src/nexa-cli \
 && ./src/nexad -version \
 && ./src/nexa-cli -version

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

COPY --from=builder /src/nexa/src/nexad /usr/local/bin/nexad
COPY --from=builder /src/nexa/src/nexa-cli /usr/local/bin/nexa-cli

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
