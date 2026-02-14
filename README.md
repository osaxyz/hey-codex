# hey-codex — Codex CLI Auto-Delegation for Claude Code

Claude Code の **hooks** と **rules** を活用し、[Codex CLI](https://github.com/openai/codex)（GPT-5.3-Codex）への自動委譲を行うスキル。MCP 不使用、Bash ツールで `codex exec` を直接実行する。

## 概要

Claude Code での作業中、hooks がイベント駆動で Codex CLI への委譲を判定し、rules が常時適用の判断基準を提供します。

**委譲判断の3段階:**

| レベル | 条件 | 動作 |
|--------|------|------|
| **MUST** | ターミナル操作、CI/CD、プロトタイプ、2回以上の失敗 | 自動委譲を推奨 |
| **SHOULD** | 設計レビュー、3+ファイル新機能、並行処理、API統合 | ユーザーに提案 |
| **MUST NOT** | リファクタリング、セキュリティ、レガシー移行、単純編集 | Claude で処理 |

## インストール

```bash
curl -fsSL https://osa.xyz/hey-codex/install.sh | bash
```

### 前提条件

- [Claude Code](https://claude.com/claude-code)
- Node.js 22+（`npx tsx` でフック実行）
- [Codex CLI](https://github.com/openai/codex) 0.99.0+（オプション — 未インストールでもフックは動作）

```bash
# Codex CLI のインストール
npm install -g @openai/codex

# 認証
codex login                    # ブラウザ認証
# または
export OPENAI_API_KEY="sk-..."  # API キー
```

## アーキテクチャ

```
rules/
    codex-delegation.md         # 常時適用の委譲ルール (MUST/SHOULD/MUST NOT)
hooks/
    agent-router.ts             # UserPromptSubmit: キーワードから委譲レベルを判定
    check-codex-before-write.ts # PreToolUse: CI/CD・シェルスクリプト編集時にリマインド
    post-implementation-review.ts # PostToolUse: 3+ファイル編集後にレビュー提案
settings/
    hooks.json                  # フック登録テンプレート
scripts/
    council.sh                  # codex exec ラッパースクリプト
```

## Hooks

### agent-router.ts (UserPromptSubmit)

ユーザー入力のキーワードから委譲レベルを判定。

- `ci/cd`, `shell script`, `prototype` 等 → **MUST delegate**
- `設計`, `review`, `performance` 等 → **SHOULD delegate**
- `refactor`, `security`, `auth` 等 → **KEEP**（委譲しない）

### check-codex-before-write.ts (PreToolUse)

ファイル書き込み前にパスをチェック。

- `.github/workflows/*` → CI/CD リマインド
- `*.sh`, `*.bash` → シェルスクリプト リマインド
- `Dockerfile`, `docker-compose.*` → インフラ リマインド

### post-implementation-review.ts (PostToolUse)

編集ファイル数を追跡し、閾値でレビューを提案。

- 3ファイル以上編集 → Codex レビュー提案
- CI/CD・シェルスクリプト変更 → 検証提案

## council.sh

Codex CLI の実行を抽象化するラッパースクリプト。

```bash
# ステータス確認
council.sh status

# 合議（read-only サンドボックス）
council.sh consult prompt.txt /path/to/project

# 実装委譲（workspace-write サンドボックス）
council.sh implement prompt.txt /path/to/project
```

**AGENTS.md 自動検出:** プロジェクトに `AGENTS.md` があれば、プロンプトの先頭に自動注入。

## 無効化

```bash
# ルールのみ無効化
rm .claude/rules/codex-delegation.md

# フックのみ無効化
rm -rf .claude/hooks/hey-codex/

# 完全に無効化 (settings.json のフック登録も手動削除)
```

## 技術スタック

- [Claude Code](https://claude.com/claude-code)（Claude Opus 4.6）
- [Codex CLI](https://github.com/openai/codex) 0.99.0+（デフォルト: [gpt-5.3-codex](https://openai.com/index/introducing-gpt-5-3-codex/)）
- TypeScript（hooks）+ Bash（council.sh）
