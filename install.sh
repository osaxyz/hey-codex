#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/osaxyz/hey-codex"
BRANCH="main"
TARBALL_URL="${REPO_URL}/archive/refs/heads/${BRANCH}.tar.gz"
TMP_DIR="$(mktemp -d)"

# ------------------------------------
# 非対話モード検出
# /dev/tty が使えない場合 (Claude Code 等) は非対話モードで動作
# 環境変数 HEY_CODEX_INSTALL_DIR で制御可能:
#   "local"  → .claude/ (デフォルト)
#   "global" → ~/.claude/
# HEY_CODEX_INSTALL_CODEX=1 で Codex CLI も自動インストール
# ------------------------------------
IS_INTERACTIVE=true
if ! exec 9>/dev/tty 2>/dev/null; then
    IS_INTERACTIVE=false
else
    exec 9>&-
fi

cleanup() {
    if [ "${IS_INTERACTIVE}" = true ]; then
        printf '\e[?25h' > /dev/tty 2>/dev/null || true
    fi
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo ""
echo "  [hey-codex] Claude Code × Codex CLI Council — Installer"
echo ""

# ------------------------------------
# 1. 対話メニュー (矢印キー / vim / Enter)
#    非対話モードでは使用されない
# ------------------------------------
select_option() {
    local options=("$@")
    local count=${#options[@]}
    local selected=0

    printf '\e[?25l' > /dev/tty

    draw_menu() {
        local i
        for ((i = 0; i < count; i++)); do
            if [ $i -eq $selected ]; then
                printf '\r\e[K  \e[1;36m❯ %s\e[0m\n' "${options[$i]}" > /dev/tty
            else
                printf '\r\e[K    %s\n' "${options[$i]}" > /dev/tty
            fi
        done
    }

    draw_menu

    while true; do
        read -rsn1 key < /dev/tty
        case "$key" in
            $'\x1b')
                read -rsn2 rest < /dev/tty
                case "$rest" in
                    '[A') ((selected > 0)) && ((selected--)) ;;
                    '[B') ((selected < count - 1)) && ((selected++)) ;;
                esac
                ;;
            'k') ((selected > 0)) && ((selected--)) ;;
            'j') ((selected < count - 1)) && ((selected++)) ;;
            '') break ;;
        esac
        printf '\e[%dA' "$count" > /dev/tty
        draw_menu
    done

    printf '\e[?25h' > /dev/tty
    return $selected
}

# ------------------------------------
# 2. インストール先の選択
# ------------------------------------
if [ "${IS_INTERACTIVE}" = true ]; then
    echo "インストール先を選択してください (↑↓/jk で移動, Enter で決定):"
    echo ""

    select_option \
        "このリポジトリ直下 (.claude/)" \
        "ユーザーホーム (~/.claude/)"
    choice=$?

    case "${choice}" in
        0)
            BASE_DIR="$(pwd)/.claude"
            ;;
        1)
            BASE_DIR="${HOME}/.claude"
            ;;
    esac
else
    # 非対話モード: 環境変数 or デフォルト(local)
    case "${HEY_CODEX_INSTALL_DIR:-local}" in
        global)
            BASE_DIR="${HOME}/.claude"
            echo "  インストール先: ~/.claude/ (非対話モード: global)"
            ;;
        *)
            BASE_DIR="$(pwd)/.claude"
            echo "  インストール先: .claude/ (非対話モード: local)"
            ;;
    esac
fi

INSTALL_DIR="${BASE_DIR}/hey-codex"
COMMANDS_DIR="${BASE_DIR}/commands"

echo ""
echo "  コマンド: ${COMMANDS_DIR}/"
echo "  スクリプト: ${INSTALL_DIR}/"
echo ""

# ------------------------------------
# 3. 最新版のダウンロード
# ------------------------------------
echo "最新版をダウンロード中..."
curl -fsSL "${TARBALL_URL}" -o "${TMP_DIR}/hey-codex.tar.gz"
tar -xzf "${TMP_DIR}/hey-codex.tar.gz" -C "${TMP_DIR}" --strip-components=1

# ------------------------------------
# 4. バージョン比較
# ------------------------------------
REMOTE_VERSION_FILE="${TMP_DIR}/VERSION"
LOCAL_VERSION_FILE="${INSTALL_DIR}/VERSION"

remote_version="unknown"
local_version="none"

if [ -f "${REMOTE_VERSION_FILE}" ]; then
    remote_version="$(tr -d '[:space:]' < "${REMOTE_VERSION_FILE}")"
fi

if [ -f "${LOCAL_VERSION_FILE}" ]; then
    local_version="$(tr -d '[:space:]' < "${LOCAL_VERSION_FILE}")"
fi

if [ "${remote_version}" = "${local_version}" ]; then
    echo ""
    echo "  すでに最新バージョン (${local_version}) です。"
    exit 0
fi

echo "  ローカル: ${local_version}"
echo "  リモート: ${remote_version}"
echo ""

# ------------------------------------
# 5. コマンドファイルのインストール
# ------------------------------------
mkdir -p "${COMMANDS_DIR}/skills"

if [ -d "${TMP_DIR}/commands" ]; then
    cp "${TMP_DIR}/commands/hey-codex.md" "${COMMANDS_DIR}/hey-codex.md"
    cp "${TMP_DIR}/commands/skills/"*.md "${COMMANDS_DIR}/skills/"
else
    echo "  警告: commands/ ディレクトリが見つかりません"
fi

# ------------------------------------
# 6. スクリプトのインストール
# ------------------------------------
mkdir -p "${INSTALL_DIR}/scripts"

if [ -d "${TMP_DIR}/scripts" ]; then
    cp "${TMP_DIR}/scripts/council.sh" "${INSTALL_DIR}/scripts/council.sh"
    chmod +x "${INSTALL_DIR}/scripts/council.sh"
fi

# ------------------------------------
# 7. バージョンファイル + examples
# ------------------------------------
if [ -f "${REMOTE_VERSION_FILE}" ]; then
    cp "${REMOTE_VERSION_FILE}" "${INSTALL_DIR}/VERSION"
fi

mkdir -p "${INSTALL_DIR}/examples"
cp "${TMP_DIR}/examples/"* "${INSTALL_DIR}/examples/" 2>/dev/null || true

# ------------------------------------
# 8. Codex CLI チェック
# ------------------------------------
echo ""
if command -v codex &>/dev/null; then
    codex_ver="$(codex --version 2>&1 || echo 'unknown')"
    echo "  Codex CLI: ${codex_ver}"
else
    echo "  Codex CLI: 未インストール"

    if [ "${IS_INTERACTIVE}" = true ]; then
        echo ""
        echo "  Codex CLI をインストールしますか? (↑↓/jk で移動, Enter で決定):"
        echo ""

        select_option \
            "はい (npm install -g @openai/codex)" \
            "スキップ"
        codex_choice=$?

        if [ "${codex_choice}" -eq 0 ]; then
            echo ""
            echo "  Codex CLI をインストール中..."
            npm install -g @openai/codex
            echo ""
            codex_ver="$(codex --version 2>&1 || echo 'unknown')"
            echo "  Codex CLI: ${codex_ver}"
        else
            echo ""
            echo "  スキップしました。後で npm install -g @openai/codex で入れてください。"
        fi
    elif [ "${HEY_CODEX_INSTALL_CODEX:-0}" = "1" ]; then
        echo ""
        echo "  Codex CLI をインストール中... (非対話モード)"
        npm install -g @openai/codex
        echo ""
        codex_ver="$(codex --version 2>&1 || echo 'unknown')"
        echo "  Codex CLI: ${codex_ver}"
    else
        echo "  スキップ (非対話モード: HEY_CODEX_INSTALL_CODEX=1 で自動インストール)"
    fi
fi

echo ""
echo "  [hey-codex] インストール完了 (${remote_version})"
echo ""
echo "  使い方: Claude Code 内で /hey-codex を実行"
echo ""
