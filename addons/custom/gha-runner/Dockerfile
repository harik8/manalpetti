FROM ubuntu:24.04

# Set environment variables
ENV VERSION=2.332.0
ENV RUNNER_ARCH=x64
ENV RUNNER_HASH=f2094522a6b9afeab07ffb586d1eb3f190b6457074282796c497ce7dce9e0f2a
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        jq \
        git \
        iproute2 \
        tar \
        bash \
        libicu66 \
        libkrb5-3 \
        zlib1g \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create runner user
RUN useradd -m runner && mkdir -p /actions-runner && chown runner:runner /actions-runner
WORKDIR /actions-runner

# Download and extract runner
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${RUNNER_ARCH}-${VERSION}.tar.gz && \
    echo "${RUNNER_HASH} *actions-runner-linux-${RUNNER_ARCH}-${VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${VERSION}.tar.gz && \
    rm actions-runner-linux-${RUNNER_ARCH}-${VERSION}.tar.gz

# Add entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
