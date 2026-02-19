#!/usr/bin/env bash
set -euxo pipefail

NODE_MAJOR="${NODE_MAJOR:-22}"
INSTALL_ZSH="${INSTALL_ZSH:-true}"

# =====================
# System deps (root)
# =====================
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates git sudo
rm -rf /var/lib/apt/lists/*

if [ "${INSTALL_ZSH}" = "true" ]; then
  apt-get update
  apt-get install -y --no-install-recommends zsh
  rm -rf /var/lib/apt/lists/*
fi

# =====================
# Node fallback
# =====================
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get update
  apt-get install -y --no-install-recommends nodejs
  rm -rf /var/lib/apt/lists/*
  corepack enable || true
fi

# =====================
# Global CLI (root OK)
# =====================
npm install -g --omit=dev @openai/codex opencode-ai
npm cache clean --force || true


# =====================================================
# ⭐ Claude Code user-level install
# =====================================================

# Devcontainer 会注入 _REMOTE_USER
REMOTE_USER="${_REMOTE_USER}"
REMOTE_HOME="$(getent passwd "${REMOTE_USER}" | cut -d: -f6)"

echo "[INFO] Installing Claude Code for user: ${REMOTE_USER}"
echo "[INFO] HOME: ${REMOTE_HOME}"

if [ -z "${REMOTE_HOME}" ]; then
  echo "WARN: Cannot detect user home. Skipping Claude install."
else
  # 确保用户 home 权限
  mkdir -p "${REMOTE_HOME}"
  chown -R "${REMOTE_USER}:${REMOTE_USER}" "${REMOTE_HOME}"

  # ⭐ 使用 sudo -u + -H 切换 HOME
  sudo -u "${REMOTE_USER}" -H bash <<EOF
set -euxo pipefail

export HOME="${REMOTE_HOME}"
export PATH="\$HOME/.local/bin:\$PATH"

# 官方 installer
curl -fsSL https://claude.ai/install.sh | bash

EOF
fi


# =====================
# zsh default shell
# =====================
if id "${REMOTE_USER}" >/dev/null 2>&1 && [ "${INSTALL_ZSH}" = "true" ]; then
  chsh -s /usr/bin/zsh "${REMOTE_USER}" || true
fi


# =====================
# zshrc install
# =====================
INSTALL_ZSHRC="${INSTALL_ZSHRC:-true}"
OVERWRITE_ZSHRC="${OVERWRITE_ZSHRC:-false}"

if [ "${INSTALL_ZSHRC}" = "true" ]; then

  if [ -z "${REMOTE_HOME}" ]; then
    echo "WARN: Could not determine home for ${REMOTE_USER}; skipping zshrc."
  else
    TARGET="${REMOTE_HOME}/.zshrc"

    if [ -f "${TARGET}" ] && [ "${OVERWRITE_ZSHRC}" != "true" ]; then
      echo "INFO: ${TARGET} exists; not overwriting."
    else
      install -m 0644 ./zshrc.min "${TARGET}"
      chown "${REMOTE_USER}:${REMOTE_USER}" "${TARGET}" || true
      echo "INFO: Installed minimal zshrc."
    fi
  fi
fi
