#!/usr/bin/env bash
set -euo pipefail

# hey-codex installer / updater
# Usage: curl -fsSL https://raw.githubusercontent.com/osaxyz/hey-codex/main/install.sh | bash

REPO="osaxyz/hey-codex"
BRANCH="main"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/VERSION"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

# Detect install target
if [ -d ".claude" ]; then
  INSTALL_DIR=".claude/hey-codex"
  COMMANDS_DIR=".claude/commands"
elif [ -d "${HOME}/.claude" ]; then
  INSTALL_DIR="${HOME}/.claude/hey-codex"
  COMMANDS_DIR="${HOME}/.claude/commands"
else
  mkdir -p "${HOME}/.claude"
  INSTALL_DIR="${HOME}/.claude/hey-codex"
  COMMANDS_DIR="${HOME}/.claude/commands"
fi

echo "[hey-codex] Install dir: ${INSTALL_DIR}"
echo "[hey-codex] Commands dir: ${COMMANDS_DIR}"

# Fetch remote version
REMOTE_VERSION=$(curl -fsSL "${REMOTE_VERSION_URL}" 2>/dev/null | tr -d '[:space:]')
if [ -z "${REMOTE_VERSION}" ]; then
  echo "[hey-codex] ERROR: Could not fetch remote version"
  exit 1
fi

# Check local version
LOCAL_VERSION=""
if [ -f "${INSTALL_DIR}/VERSION" ]; then
  LOCAL_VERSION=$(cat "${INSTALL_DIR}/VERSION" | tr -d '[:space:]')
fi

echo "[hey-codex] Local version:  ${LOCAL_VERSION:-none}"
echo "[hey-codex] Remote version: ${REMOTE_VERSION}"

# Compare versions
if [ "${LOCAL_VERSION}" = "${REMOTE_VERSION}" ]; then
  echo "[hey-codex] Already up to date (${LOCAL_VERSION})"
  exit 0
fi

echo "[hey-codex] Updating ${LOCAL_VERSION:-none} -> ${REMOTE_VERSION}..."

# Download and extract
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

curl -fsSL "${TARBALL_URL}" | tar xz -C "${TMPDIR}" --strip-components=1

# Install commands
mkdir -p "${COMMANDS_DIR}/skills"
cp "${TMPDIR}/commands/hey-codex.md" "${COMMANDS_DIR}/hey-codex.md"
cp "${TMPDIR}/commands/skills/"*.md "${COMMANDS_DIR}/skills/"

# Install scripts
mkdir -p "${INSTALL_DIR}/scripts"
cp "${TMPDIR}/scripts/council.sh" "${INSTALL_DIR}/scripts/council.sh"
chmod +x "${INSTALL_DIR}/scripts/council.sh"

# Install version
cp "${TMPDIR}/VERSION" "${INSTALL_DIR}/VERSION"

# Install examples
mkdir -p "${INSTALL_DIR}/examples"
cp "${TMPDIR}/examples/"* "${INSTALL_DIR}/examples/" 2>/dev/null || true

echo "[hey-codex] Updated to ${REMOTE_VERSION}"
echo "[hey-codex] council.sh: ${INSTALL_DIR}/scripts/council.sh"
echo "[hey-codex] Skill entry: ${COMMANDS_DIR}/hey-codex.md"
