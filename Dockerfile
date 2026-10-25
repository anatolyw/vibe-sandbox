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

# Pre-create XDG base dirs as the node user (uid 1000).
# Required when bind-mounting into *subdirs* of these paths (e.g.
# ~/.cache/opencode): if the parent does not exist, Docker creates it as root
# and tools like oh-my-zsh then fail with
#   mkdir: cannot create directory ‘/home/node/.cache/oh-my-zsh’: Permission denied
RUN mkdir -p \
      /home/node/.cache \
      /home/node/.config \
      /home/node/.local/share \
      /home/node/.local/state

# ---------- Agent CLIs (bake into image so PATH is ready after rebuild) ----------
# OpenCode is the default example. To add another CLI the same way, install it
# here as USER node (or system-wide as root) and, if needed, extend PATH in
# .vibe-home/.bash_profile. Example pattern:
#   RUN curl -fsSL https://example.com/install | bash
#   # or: RUN npm install -g @some/cli
# Persist that tool's config/cache under .vibe-home/* and mount it in
# docker-compose.yml (see OpenCode mounts for the pattern).
RUN curl -fsSL https://opencode.ai/v2/install | bash

# Default command keeps the container alive for `docker compose exec`
CMD ["sleep", "infinity"]
