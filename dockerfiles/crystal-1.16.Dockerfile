# syntax=docker/dockerfile:1.7-labs
FROM crystallang/crystal:1.16-alpine

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="shard.yml,shard.lock"

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# Install dependencies if shard.yml exists
RUN if [ -f shard.yml ]; then shards install; fi
