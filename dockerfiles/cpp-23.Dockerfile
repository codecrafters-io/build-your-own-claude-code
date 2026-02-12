# syntax=docker/dockerfile:1.7-labs
FROM gcc:15.2.0-trixie

# Ensures the container is re-built if dependency files change
ENV CODECRAFTERS_DEPENDENCY_FILE_PATHS="CMakeLists.txt,vcpkg.json,vcpkg-configuration.json"

RUN apt-get update && \
    apt-get install --no-install-recommends -y zip=3.* g++=4:* build-essential=12.* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget --progress=dot:giga https://github.com/Kitware/CMake/releases/download/v3.30.5/cmake-3.30.5-Linux-x86_64.tar.gz && \
    tar -xzvf cmake-3.30.5-Linux-x86_64.tar.gz && \
    mv cmake-3.30.5-linux-x86_64/ /cmake && \
    rm cmake-3.30.5-Linux-x86_64.tar.gz && \
    git clone https://github.com/microsoft/vcpkg.git && \
    ./vcpkg/bootstrap-vcpkg.sh -disableMetrics

ENV CMAKE_BIN="/cmake/bin"
ENV VCPKG_ROOT="/vcpkg"
ENV PATH="${CMAKE_BIN}:${VCPKG_ROOT}:$PATH"

WORKDIR /app

# .git & README.md are unique per-repository. We ignore them on first copy to prevent cache misses
COPY --exclude=.git --exclude=README.md . /app

RUN vcpkg install --no-print-usage && \
    sed -i '1s/^/set(VCPKG_INSTALL_OPTIONS --no-print-usage)\n/' ${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake && \
    .codecrafters/compile.sh && \
    mkdir -p /app-cached && \
    if [ -d "/app/vcpkg_installed" ]; then mv /app/vcpkg_installed /app-cached; fi && \
    if [ -d "/app/build" ]; then mv /app/build /app-cached; fi
