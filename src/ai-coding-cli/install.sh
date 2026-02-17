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
npm install -g --omit=dev @anthropic-ai/claude-code @openai/codex opencode-ai
npm cache clean --force || true

# Claude Code via official installer script
# curl -fsSL https://claude.ai/install.sh | bash

# Prefer zsh
if id vscode >/dev/null 2>&1 && [ "${INSTALL_ZSH}" = "true" ]; then
  chsh -s /usr/bin/zsh vscode || true
fi

INSTALL_ZSHRC="${INSTALL_ZSHRC:-true}"
OVERWRITE_ZSHRC="${OVERWRITE_ZSHRC:-false}"

if [ "${INSTALL_ZSHRC}" = "true" ]; then
  # Determine remote user (Dev Containers sets _REMOTE_USER; fall back to vscode)
  echo "[DEBUG] env _REMOTE_USER ${_REMOTE_USER}"
  REMOTE_USER="${_REMOTE_USER:-vscode}"
  REMOTE_HOME="$(getent passwd "${REMOTE_USER}" | cut -d: -f6 || true)"

  if [ -z "${REMOTE_HOME}" ]; then
    echo "WARN: Could not determine home for ${REMOTE_USER}; skipping zshrc install."
  else
    mkdir -p "${REMOTE_HOME}"
    TARGET="${REMOTE_HOME}/.zshrc"

    if [ -f "${TARGET}" ] && [ "${OVERWRITE_ZSHRC}" != "true" ]; then
      echo "INFO: ${TARGET} exists; not overwriting (set overwriteZshrc=true to overwrite)."
    else
      install -m 0644 ./zshrc.min "${TARGET}"
      chown "${REMOTE_USER}:${REMOTE_USER}" "${TARGET}" || true
      echo "INFO: Installed minimal zshrc to ${TARGET}"
    fi
  fi
fi
