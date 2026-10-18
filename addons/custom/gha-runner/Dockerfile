FROM ubuntu:25.10

# Set environment variables
ENV VERSION=2.334.0
ENV RUNNER_ARCH=x64
ENV RUNNER_HASH=048024cd2c848eb6f14d5646d56c13a4def2ae7ee3ad12122bee960c56f3d271
ENV DEBIAN_FRONTEND=noninteractive
ENV HELM_VERSION=4.1.4
ENV HELM_ARCH=amd64
ENV HELM_HASH=70b2c30a19da4db264dfd68c8a3664e05093a361cefd89572ffb36f8abfa3d09

# Install dependencies
RUN  apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        jq \
        git \
        iproute2 \
        tar \
        bash \
        libkrb5-3 \
        libicu74 \
        zlib1g \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Install helm
RUN curl -o helm-linux-${HELM_ARCH}-${HELM_VERSION}.tar.gz -L \
    https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
    echo "${HELM_HASH} *helm-linux-${HELM_ARCH}-${HELM_VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf ./helm-linux-${HELM_ARCH}-${HELM_VERSION}.tar.gz && \
    chmod +x linux-${HELM_ARCH}/helm && \
    cp linux-${HELM_ARCH}/helm /usr/local/bin && \
    rm helm-linux-${HELM_ARCH}-${HELM_VERSION}.tar.gz && \
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
