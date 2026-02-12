# syntax=docker/dockerfile:1.7-labs
FROM julia:1.11-alpine

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="Project.toml,Manifest.toml"

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# Install dependencies and precompile
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
