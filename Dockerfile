FROM node:22-bookworm

# ---------- system packages ----------
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
        zsh \
        git \
        curl \
        ca-certificates \
        openssh-client \
        less \
        vim-tiny \
        unzip \
        zip \
        build-essential \
        python3 \
        mc \
    && sed -i 's/# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Make zsh the default shell for the node user
RUN chsh -s /bin/zsh node

USER node
ENV HOME=/home/node \
    SHELL=/bin/zsh

WORKDIR /workspace
ENV npm_config_cache=/home/node/.npm

# ---------- OpenCode CLI ----------
# Install into the node user's home so PATH from .bash_profile finds it.
RUN curl -fsSL https://opencode.ai/v2/install | bash

# Default command keeps the container alive for `docker compose exec`
CMD ["sleep", "infinity"]
