# syntax=docker/dockerfile:1.7-labs
FROM r-base:4.4.2

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="install_packages.R"

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# Install R packages
RUN Rscript install_packages.R
