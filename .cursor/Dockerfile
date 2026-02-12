# syntax=docker/dockerfile:1.7-labs
FROM ubuntu:22.04

# 1. System setup
RUN apt-get update && apt-get install -y \
    curl git unzip make sudo g++ ca-certificates gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*

# 2. Docker CLI
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli

# 3. Bun
ENV BUN_INSTALL="/usr/local"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

# 4. Course-SDK (Using the specific steps you provided)
WORKDIR /opt
RUN git clone https://github.com/codecrafters-io/course-sdk.git
WORKDIR /opt/course-sdk
RUN bun install
RUN make install

# Create non-root user for cloud agents
RUN useradd -m -s /bin/bash ubuntu

# Set user and working directory as required for cloud agents
USER ubuntu
WORKDIR /home/ubuntu