#!/usr/bin/env bash
set -euo pipefail

# council.sh - Codex CLI wrapper for hey-codex skill
# Usage: council.sh <mode> <prompt_file> [workdir]
# Modes: consult, implement, status

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-}"
PROMPT_FILE="${2:-}"
WORKDIR="${3:-.}"

# Resolve workdir to absolute path
WORKDIR="$(cd "${WORKDIR}" && pwd)"

usage() {
  cat <<'USAGE'
Usage: council.sh <mode> <prompt_file> [workdir]

Modes:
  consult    - Read-only consultation (sandbox: read-only)
  implement  - Implementation delegation (sandbox: workspace-write)
  status     - Check Codex CLI availability and auth status

Arguments:
  prompt_file  - Path to file containing the prompt/task description
  workdir      - Working directory for Codex (default: current dir)
USAGE
  exit 1
}

# --- Check Codex CLI availability ---
# Returns: 0 = installed, 1 = not installed
# Output: JSON-like status to stdout
check_codex() {
  if command -v codex &>/dev/null; then
    return 0
  fi
  return 1
}

# --- Status mode ---
do_status() {
  echo "=== Codex CLI Status ==="

  if ! check_codex; then
    echo "CODEX_NOT_INSTALLED"
    echo "Codex CLI is not installed."
    echo ""
    echo "To install:"
    echo "  npm install -g @openai/codex"
    echo ""
    echo "After install, authenticate with one of:"
    echo "  codex login                                        # Browser-based (ChatGPT account)"
    echo "  printenv OPENAI_API_KEY | codex login --with-api-key  # API key"
    exit 1
  fi

  # Version
  echo "Version: $(codex --version 2>&1 || echo 'unknown')"

  # Auth status
  local auth_status
  auth_status=$(codex login status 2>&1 || true)
  echo "Auth: ${auth_status}"

  # Config (optional)
  CODEX_CONFIG="${HOME}/.codex/config.toml"
  if [ -f "${CODEX_CONFIG}" ]; then
    echo "Config: ${CODEX_CONFIG} (found)"
    MODEL=$(grep '^model ' "${CODEX_CONFIG}" | head -1 | sed 's/model *= *"\([^"]*\)"/\1/')
    echo "Model: ${MODEL:-default}"
  else
    echo "Config: none (using defaults)"
  fi

  # Check AGENTS.md in workdir
  if [ -f "${WORKDIR}/AGENTS.md" ]; then
    echo "AGENTS.md: detected (${WORKDIR}/AGENTS.md)"
  else
    echo "AGENTS.md: not found in ${WORKDIR}"
  fi

  echo "=== Ready ==="
  exit 0
}

# --- Find AGENTS.md ---
find_agents_md() {
  local dir="$1"
  # Check standard locations
  if [ -f "${dir}/AGENTS.md" ]; then
    echo "${dir}/AGENTS.md"
    return 0
  fi
  if [ -f "${dir}/.agents/rules/base.md" ]; then
    echo "${dir}/.agents/rules/base.md"
    return 0
  fi
  return 1
}

# --- Merge prompt with AGENTS.md ---
merge_prompt() {
  local prompt_file="$1"
  local workdir="$2"
  local merged_file

  merged_file=$(mktemp /tmp/codex-merged-XXXXXX)

  # Try to find AGENTS.md
  local agents_md
  if agents_md=$(find_agents_md "${workdir}"); then
    echo "[council] AGENTS.md detected: ${agents_md}" >&2
    {
      echo "=== Project Instructions (AGENTS.md) ==="
      echo ""
      cat "${agents_md}"
      echo ""
      echo "---"
      echo ""
      echo "=== Task ==="
      echo ""
      cat "${prompt_file}"
    } > "${merged_file}"
  else
    echo "[council] No AGENTS.md found, using prompt as-is" >&2
    cp "${prompt_file}" "${merged_file}"
  fi

  echo "${merged_file}"
}

# --- Run Codex ---
do_codex() {
  local mode="$1"
  local prompt_file="$2"
  local workdir="$3"
  local sandbox_flag

  # Check codex is available
  if ! check_codex; then
    echo "CODEX_NOT_INSTALLED"
    echo "ERROR: Codex CLI is not installed. Run: npm install -g @openai/codex"
    exit 1
  fi

  # Validate prompt file
  if [ ! -f "${prompt_file}" ]; then
    echo "ERROR: Prompt file not found: ${prompt_file}"
    exit 1
  fi

  # Set sandbox mode
  case "${mode}" in
    consult)
      sandbox_flag="read-only"
      ;;
    implement)
      sandbox_flag="workspace-write"
      ;;
    *)
      echo "ERROR: Unknown mode: ${mode}"
      usage
      ;;
  esac

  # Merge prompt with AGENTS.md
  local merged_prompt
  merged_prompt=$(merge_prompt "${prompt_file}" "${workdir}")

  # Output file for Codex response
  local output_file
  output_file=$(mktemp /tmp/codex-output-XXXXXX)

  echo "[council] Mode: ${mode} (sandbox: ${sandbox_flag})"
  echo "[council] Workdir: ${workdir}"
  echo "[council] Prompt: ${prompt_file}"
  echo "[council] Merged prompt: ${merged_prompt}"
  echo "[council] Output: ${output_file}"
  echo "---"

  # Run codex
  local exit_code=0
  codex exec - \
    -C "${workdir}" \
    --full-auto \
    --skip-git-repo-check \
    -o "${output_file}" \
    < "${merged_prompt}" || exit_code=$?

  echo "---"

  # Output results
  if [ -f "${output_file}" ] && [ -s "${output_file}" ]; then
    echo "[council] Codex response:"
    echo ""
    cat "${output_file}"
    echo ""
    echo "[council] Output saved: ${output_file}"
  else
    echo "[council] No output from Codex"
  fi

  # Cleanup merged prompt (keep output for Claude Code to read)
  rm -f "${merged_prompt}"

  echo "[council] Exit code: ${exit_code}"
  return "${exit_code}"
}

# --- Main ---
case "${MODE}" in
  status)
    do_status
    ;;
  consult|implement)
    if [ -z "${PROMPT_FILE}" ]; then
      echo "ERROR: prompt_file is required for ${MODE} mode"
      usage
    fi
    do_codex "${MODE}" "${PROMPT_FILE}" "${WORKDIR}"
    ;;
  *)
    echo "ERROR: Unknown mode: ${MODE}"
    usage
    ;;
esac
