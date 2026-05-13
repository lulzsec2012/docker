ARG UBUNTU_VERSION=24.04
ARG DEBIAN_FRONTEND="noninteractive"

FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND

RUN apt-get update && apt-get install -y --no-install-recommends \
    emacs-nox \
    git ca-certificates openssh-client \
    curl wget \
    ripgrep fd-find \
    jq \
    python3 python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN emacs --version && \
    emacs -Q --batch --eval="(message \"native-comp: %s\" (if (native-comp-available-p) \"yes\" \"no\"))" && \
    emacs -Q --batch --eval="(message \"tree-sitter: %s\" (if (treesit-available-p) \"yes\" \"no\"))"

CMD ["emacs", "-nw"]
