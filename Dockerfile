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
        # Playwright / Xvfb deps \
        xvfb \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libgbm1 \
        libpango-1.0-0 \
        libcairo2 \
        libasound2 \
        libxshmfence1 \
        libx11-xcb1 \
        fonts-liberation \
        libdrm2 \
        libxkbcommon0 \
        libwayland-client0 \
        # a few extra ones that --with-deps usually pulls
        libgtk-3-0 \
        libdbus-1-3 \
        libxtst6 \
    && sed -i 's/# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Make zsh the default shell for the node user
RUN chsh -s /bin/zsh node

# ---------- Playwright (as root) ----------
# Install system deps + browsers once, into a shared location
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN mkdir -p /ms-playwright \
 && npx -y playwright@1.64.1 install --with-deps chromium firefox webkit \
 && chmod -R 777 /ms-playwright

# (optional) also keep the classic cache location working
RUN mkdir -p /home/node/.cache \
 && ln -s /ms-playwright /home/node/.cache/ms-playwright \
 && chown -R node:node /home/node/.cache

USER node
ENV HOME=/home/node \
    SHELL=/bin/zsh \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

WORKDIR /workspace
ENV npm_config_cache=/home/node/.npm

# Pre-create XDG base dirs as the node user
RUN mkdir -p \
      /home/node/.cache \
      /home/node/.config \
      /home/node/.local/share \
      /home/node/.local/state

# ---------- Agent CLIs ----------
RUN curl -fsSL https://opencode.ai/v2/install | bash

# ---------- Playwright env ----------
# For full/headful rendering via Xvfb
ENV DISPLAY=:99

## Default command keeps the container alive for `docker compose exec`
#CMD ["sleep", "infinity"]
# Default command: start Xvfb so headful tests work, then stay alive
CMD ["sh", "-c", "Xvfb :99 -screen 0 1280x720x16 & sleep infinity"]