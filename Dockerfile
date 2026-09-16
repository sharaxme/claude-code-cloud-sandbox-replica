FROM ubuntu:24.04
LABEL note="Replica of Claude Code cloud environment (Ubuntu 24.04.4, x86_64)"

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# ---------------------------------------------------------------------------
# Base tools + databases + build essentials
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git jq ripgrep tmux vim nano gnupg ca-certificates unzip \
    build-essential cmake ninja-build \
    postgresql redis-server \
    software-properties-common \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Node.js 22.22.2 (+ nvm) and global tools matching the reported inventory
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g \
        yarn@1.22.22 \
        pnpm@10.33.0 \
        eslint@10.1.0 \
        prettier@3.8.1 \
        corepack@0.34.6 \
        ts-node@10.9.2 \
        typescript@6.0.2 \
        nodemon@3.1.14 \
        http-server@14.1.1 \
        serve@14.2.6 \
        playwright@1.56.1 \
        chromedriver@147.0.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# ---------------------------------------------------------------------------
# Java 21 + Maven + Gradle
# ---------------------------------------------------------------------------

RUN apt-get update && apt-get install -y openjdk-21-jdk maven \
    && rm -rf /var/lib/apt/lists/*
ENV GRADLE_VERSION=8.14.3
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle \
    && rm /tmp/gradle.zip
ENV PATH="/opt/maven/bin:/opt/gradle/bin:${PATH}"

# ---------------------------------------------------------------------------
# Go 1.24.7
# ---------------------------------------------------------------------------
RUN curl -fsSL https://go.dev/dl/go1.24.7.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# ---------------------------------------------------------------------------
# Rust (rustc/cargo 1.94.1)
# ---------------------------------------------------------------------------
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.94.1
ENV PATH="/root/.cargo/bin:${PATH}"

# ---------------------------------------------------------------------------
# Ruby 3.3.6 via rbenv
# ---------------------------------------------------------------------------
RUN git clone https://github.com/rbenv/rbenv.git /opt/rbenv \
    && git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build
ENV PATH="/opt/rbenv/bin:/opt/rbenv/shims:${PATH}"
RUN eval "$(rbenv init -)" \
    && rbenv install 3.3.6 \
    && rbenv global 3.3.6

# ---------------------------------------------------------------------------
# PHP 8.4
# ---------------------------------------------------------------------------
RUN add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php8.4-cli php8.4-common \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ---------------------------------------------------------------------------
# Bun and Deno
# ---------------------------------------------------------------------------
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
ENV BUN_OPTIONS="--smol"

# ---------------------------------------------------------------------------
# Docker CLI (for docker compose; not full docker-in-docker)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://get.docker.com | sh

# ---------------------------------------------------------------------------
# Python: package managers + linters matching the reported versions
# ---------------------------------------------------------------------------
RUN pip3 install --break-system-packages --no-cache-dir \
    poetry==2.3.3 \
    uv==0.8.17 \
    black==26.3.1 \
    mypy==1.19.1 \
    pytest==9.0.2 \
    ruff==0.15.8 \
    conan==2.27.0 \
    cryptography==41.0.7 \
    requests==2.33.1 \
    urllib3==2.6.3 \
    Jinja2==3.1.6 \
    PyYAML==6.0.1 \
    yq==3.1.0 \
    xmltodict==0.13.0

# ---------------------------------------------------------------------------
# Equivalent environment variables (no secrets/tokens)
# ---------------------------------------------------------------------------
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
ENV IS_SANDBOX=yes
ENV HOME=/root

WORKDIR /workspace
CMD ["/bin/bash"]
