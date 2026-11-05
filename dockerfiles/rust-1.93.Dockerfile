# syntax=docker/dockerfile:1.7-labs
FROM rust:1.93-trixie

# Rebuild the container if these files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="Cargo.toml,Cargo.lock"

# Python runs the shared LSP invoice tests in every language runtime.
RUN apt-get update && \
    apt-get install --no-install-recommends -y python3=3.* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# This runs cargo build
RUN .codecrafters/compile.sh
