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

echo ""
echo "  インストール先: ${INSTALL_DIR}/"
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
# 5. v0.5.0 以前の不要ファイルを削除
# ------------------------------------
HOOKS_DIR="${BASE_DIR}/hooks/hey-codex"
legacy_removed=0

# 手動コマンド (v0.6.0 で廃止)
for f in \
    "${BASE_DIR}/commands/hey-codex.md" \
    "${BASE_DIR}/commands/skills/council-protocol.md" \
    "${BASE_DIR}/commands/skills/contradiction-check.md"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        legacy_removed=$((legacy_removed + 1))
    fi
done
# 空になった commands ディレクトリを削除
rmdir "${BASE_DIR}/commands/skills" 2>/dev/null || true
rmdir "${BASE_DIR}/commands" 2>/dev/null || true

# examples (v0.6.0 で廃止)
if [ -d "${INSTALL_DIR}/examples" ]; then
    rm -rf "${INSTALL_DIR}/examples"
    legacy_removed=$((legacy_removed + 1))
fi

# Python フック → TypeScript に移行済み
for f in "${HOOKS_DIR}/"*.py; do
    [ -f "$f" ] || continue
    rm -f "$f"
    legacy_removed=$((legacy_removed + 1))
done

# settings.json から旧 python3 フックを除去
SETTINGS_FILE="${BASE_DIR}/settings.json"
if [ -f "${SETTINGS_FILE}" ]; then
    has_python=$(node -e "
const fs = require('fs');
const s = JSON.parse(fs.readFileSync('${SETTINGS_FILE}', 'utf-8'));
let found = false;
for (const entries of Object.values(s.hooks || {})) {
    for (const entry of entries) {
        for (const h of (entry.hooks || [])) {
            if ((h.command || '').includes('python3')) { found = true; }
        }
    }
}
console.log(found ? '1' : '0');
" 2>/dev/null || echo "0")

    if [ "${has_python}" = "1" ]; then
        node -e "
const fs = require('fs');
const s = JSON.parse(fs.readFileSync('${SETTINGS_FILE}', 'utf-8'));
for (const [event, entries] of Object.entries(s.hooks || {})) {
    s.hooks[event] = entries.filter(entry => {
        const hooks = entry.hooks || [];
        return !hooks.some(h => (h.command || '').includes('python3'));
    });
    if (s.hooks[event].length === 0) delete s.hooks[event];
}
fs.writeFileSync('${SETTINGS_FILE}', JSON.stringify(s, null, 2) + '\n');
" 2>/dev/null
        legacy_removed=$((legacy_removed + 1))
    fi
fi

if [ "${legacy_removed}" -gt 0 ]; then
    echo "  旧バージョンのファイルを ${legacy_removed} 件削除しました"
    echo ""
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
# 7. バージョンファイル
# ------------------------------------
if [ -f "${REMOTE_VERSION_FILE}" ]; then
    cp "${REMOTE_VERSION_FILE}" "${INSTALL_DIR}/VERSION"
fi

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

# ------------------------------------
# 9. ルールのインストール
# ------------------------------------
RULES_DIR="${BASE_DIR}/rules"
mkdir -p "${RULES_DIR}"

if [ -f "${TMP_DIR}/rules/codex-delegation.md" ]; then
    cp "${TMP_DIR}/rules/codex-delegation.md" "${RULES_DIR}/codex-delegation.md"
    echo "  ルール: ${RULES_DIR}/codex-delegation.md"
else
    echo "  警告: rules/codex-delegation.md が見つかりません"
fi

# ------------------------------------
# 10. フックのインストール
# ------------------------------------
mkdir -p "${HOOKS_DIR}"

if [ -d "${TMP_DIR}/hooks" ]; then
    for hook_file in "${TMP_DIR}/hooks/"*.ts; do
        [ -f "${hook_file}" ] || continue
        hook_name="$(basename "${hook_file}")"
        cp "${hook_file}" "${HOOKS_DIR}/${hook_name}"
        chmod +x "${HOOKS_DIR}/${hook_name}"
    done
    echo "  フック: ${HOOKS_DIR}/"
else
    echo "  警告: hooks/ ディレクトリが見つかりません"
fi

# ------------------------------------
# 11. settings.json マージ
# ------------------------------------
HOOKS_TEMPLATE="${TMP_DIR}/settings/hooks.json"

if [ -f "${HOOKS_TEMPLATE}" ]; then
    # Replace __HOOKS_DIR__ placeholder with actual path
    HOOKS_DIR_ESCAPED=$(echo "${HOOKS_DIR}" | sed 's/[&/\]/\\&/g')
    MERGED_TEMPLATE=$(mktemp /tmp/hey-codex-hooks-XXXXXX.json)
    sed "s|__HOOKS_DIR__|${HOOKS_DIR}|g" "${HOOKS_TEMPLATE}" > "${MERGED_TEMPLATE}"

    if [ ! -f "${SETTINGS_FILE}" ]; then
        # No existing settings — use template directly
        cp "${MERGED_TEMPLATE}" "${SETTINGS_FILE}"
        echo "  設定: ${SETTINGS_FILE} (新規作成)"
    else
        # Existing settings — deep merge with node
        cp "${SETTINGS_FILE}" "${SETTINGS_FILE}.bak.hey-codex"
        node -e "
const fs = require('fs');

const existing = JSON.parse(fs.readFileSync('${SETTINGS_FILE}', 'utf-8'));
const newHooks = JSON.parse(fs.readFileSync('${MERGED_TEMPLATE}', 'utf-8'));

// Ensure hooks key exists
if (!existing.hooks) existing.hooks = {};

// Merge each event type
for (const [event, eventEntries] of Object.entries(newHooks.hooks || {})) {
    if (!existing.hooks[event]) {
        existing.hooks[event] = eventEntries;
        continue;
    }

    // Check for duplicates by command path
    const existingCommands = new Set();
    for (const entry of existing.hooks[event]) {
        for (const h of (entry.hooks || [])) {
            existingCommands.add(h.command || '');
        }
    }

    for (const newEntry of eventEntries) {
        let isDup = false;
        for (const h of (newEntry.hooks || [])) {
            if (existingCommands.has(h.command || '')) {
                isDup = true;
                break;
            }
        }
        if (!isDup) existing.hooks[event].push(newEntry);
    }
}

fs.writeFileSync('${SETTINGS_FILE}', JSON.stringify(existing, null, 2) + '\n');
console.log('  設定: ${SETTINGS_FILE} (マージ完了)');
" 2>&1
    fi

    rm -f "${MERGED_TEMPLATE}"
else
    echo "  警告: settings/hooks.json テンプレートが見つかりません"
fi

echo ""
echo "  [hey-codex] インストール完了 (${remote_version})"
echo ""
echo "  自動委譲が有効になりました（hooks + rules）"
echo ""
echo "  無効化:"
echo "    rm ${RULES_DIR}/codex-delegation.md"
echo "    rm -rf ${HOOKS_DIR}"
echo ""
