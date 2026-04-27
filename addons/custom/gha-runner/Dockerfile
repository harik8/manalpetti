FROM ubuntu:24.04

# Set environment variables
ENV VERSION=2.332.0
ENV RUNNER_ARCH=x64
ENV RUNNER_HASH=f2094522a6b9afeab07ffb586d1eb3f190b6457074282796c497ce7dce9e0f2a
ENV DEBIAN_FRONTEND=noninteractive
ENV HELM_VERSION=4.1.4
ENV HELM_ARCH=amd64

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
        libkrb5-3 \
        zlib1g \
        wget \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Helm CLI
RUN curl -o helm-v${HELM_VERSION}.tar.gz -L \
    https://get.helm.sh/helm-v${HELM_VERSION}.tar.gz && \
    tar -zxvf helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
    chmod +x linux-${HELM_ARCH}/helm && \
    cp linux-${HELM_ARCH}/helm /usr/local/bin && \
    rm helm-v${HELM_VERSION}.tar.gz && \
    rm -rf linux-${HELM_ARCH}


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
