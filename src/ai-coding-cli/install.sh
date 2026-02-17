#!/usr/bin/env bash
set -euxo pipefail

NODE_MAJOR="${NODE_MAJOR:-22}"
INSTALL_ZSH="${INSTALL_ZSH:-true}"

apt-get update
apt-get install -y --no-install-recommends curl ca-certificates git
rm -rf /var/lib/apt/lists/*

if [ "${INSTALL_ZSH}" = "true" ]; then
  apt-get update
  apt-get install -y --no-install-recommends zsh
  rm -rf /var/lib/apt/lists/*
fi

# Fallback: install node if missing
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get update
  apt-get install -y --no-install-recommends nodejs
  rm -rf /var/lib/apt/lists/*
  corepack enable || true
fi

# Codex & OpenCode via npm
npm install -g --omit=dev @openai/codex opencode-ai
npm cache clean --force || true

# Claude Code via official installer script
curl -fsSL https://claude.ai/install.sh | bash

# Prefer zsh
if id vscode >/dev/null 2>&1 && [ "${INSTALL_ZSH}" = "true" ]; then
  chsh -s /usr/bin/zsh vscode || true
fi
