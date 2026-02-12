# syntax=docker/dockerfile:1.7-labs
FROM php:8.5-cli-alpine3.22

# For ext-sockets installation
RUN apk add linux-headers=~6.14.2-r0 --no-cache

RUN docker-php-ext-install pcntl sockets

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="composer.json,composer.lock"

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

# Install dependencies
RUN composer install --no-dev --no-interaction --optimize-autoloader
