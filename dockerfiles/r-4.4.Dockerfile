# syntax=docker/dockerfile:1.7-labs
FROM debian:bookworm

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="install_packages.R"

# Install R and build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    r-base \
    build-essential \
    pkg-config \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# Install R packages
RUN Rscript install_packages.R
