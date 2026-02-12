FROM eclipse-temurin:24-jdk-alpine

ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="build.sbt,project/assembly.sbt,project/build.properties"

RUN apk add --no-cache bash curl git && \
    curl -fsSL "https://github.com/sbt/sbt/releases/download/v1.11.7/sbt-1.11.7.tgz" | tar xz -C /opt && \
    ln -s /opt/sbt/bin/sbt /usr/local/bin/sbt

WORKDIR /app

COPY . /app

RUN .codecrafters/compile.sh
