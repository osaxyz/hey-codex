# /hey-codex - Claude Code × Codex CLI

Claude Code 向けの Codex CLI 合議・実装委譲スキル。
`/hey-codex` コマンドで起動し、設計判断やコード生成を Codex CLI に自動委譲する。

## 概要

Claude Code での作業中、設計判断やコード生成で [Codex CLI](https://github.com/openai/codex)（GPT-5.3-Codex）にセカンドオピニオンを求めたり、実装を委譲するスキル。MCP 不使用、Bash ツールで `codex exec` を直接実行する。

**主な機能:**

- **合議 (Consult)** — アーキテクチャ・設計判断を Codex に相談し、Claude Code の見解と比較
- **実装委譲 (Implement)** — ボイラープレートや大量コード生成を Codex に委譲
- **矛盾チェック (Check)** — AGENTS.md と CLAUDE.md の矛盾を検出・報告
- AGENTS.md があれば Codex がそれに従う（プロンプトに自動注入）
- 起動時に VERSION チェックで自動アップデート

## インストール

```bash
curl -fsSL https://osa.xyz/hey-codex/install.sh | bash
```

インストール先を自動検出:

1. リポジトリ直下（`.claude/commands/`）— `.claude/` が存在する場合
2. ユーザーホーム（`~/.claude/commands/`）— それ以外

### 前提条件: Codex CLI のセットアップ

> **Codex CLI が未インストールでも `/hey-codex` は起動可能。** 起動時に未検出なら、インストールするか確認される。

#### 1. Codex CLI のインストール

```bash
npm install -g @openai/codex    # latest: 0.99.0
```

> Node.js 22+ が必要。

#### 2. 認証

```bash
# ブラウザ認証（ChatGPT / OpenAI アカウント）
codex login

# または API キー
export OPENAI_API_KEY="sk-..."
```

#### 3. `~/.codex/config.toml`（オプション）

未設定でもデフォルト値で動作する。モデルを変えたい場合のみ:

```toml
model = "gpt-5.3-codex"    # デフォルト: gpt-5.3-codex
```

## 使い方

Claude Code 内で以下のコマンドを実行:

```
/hey-codex
```

起動後のフロー:

1. **アップデートチェック** — VERSION 比較で最新版に自動更新
2. **Codex CLI ステータス確認** — バージョン、モデル、認証状態
3. **モード選択**:
   - **Consult（合議）** — 設計・アーキテクチャの相談
   - **Implement（実装委譲）** — コード生成を Codex に任せる
   - **Check（矛盾チェック）** — AGENTS.md と CLAUDE.md の比較
4. **実行と報告** — Codex Council Report フォーマットで結果を表示

## スキル構成

```
commands/
    hey-codex.md                # エントリポイント（/hey-codex で起動）
    skills/
        council-protocol.md     # 委譲プロトコル（いつ・どのように委譲するか）
        contradiction-check.md  # 矛盾検出プロトコル
scripts/
    council.sh                  # codex exec ラッパースクリプト
examples/
    AGENTS.md                   # プロジェクト用テンプレート（英語）
    AGENTS.ja.md                # プロジェクト用テンプレート（日本語）
```

| ファイル | 役割 |
|----------|------|
| `hey-codex.md` | エントリポイント。アップデートチェック後、モード選択・実行 |
| `council-protocol.md` | 合議・実装委譲の判断基準とプロンプトテンプレート |
| `contradiction-check.md` | AGENTS.md と CLAUDE.md の矛盾検出・報告手順 |
| `council.sh` | Codex CLI ラッパー。AGENTS.md 自動検出・プロンプト合成・実行 |

## council.sh

Codex CLI の実行を抽象化するラッパースクリプト。

```bash
# ステータス確認
council.sh status

# 合議（読み取り専用サンドボックス）
council.sh consult prompt.txt /path/to/project

# 実装委譲（ワークスペース書き込み可）
council.sh implement prompt.txt /path/to/project
```

**AGENTS.md 自動検出:** プロジェクトに `AGENTS.md` または `.agents/rules/base.md` があれば、プロンプトの先頭に自動注入される。

## 委譲判断基準

### 合議 (Consult) すべき場面

- アーキテクチャの大きな判断（DB、フレームワーク、設計パターン選定）
- 複数アプローチがあり、トレードオフが不明確
- セキュリティ・パフォーマンスに関わる設計判断

### 実装委譲 (Implement) すべき場面

- ボイラープレート生成（CRUD、設定ファイル、テストスケルトン）
- 大量のコード生成が必要で、要件が明確
- コンテキストウィンドウを節約したい大きな実装

## AGENTS.md テンプレート

プロジェクトに `AGENTS.md` を配置すると、Codex CLI がそれに従って作業する。テンプレートは `examples/` に用意:

- `examples/AGENTS.md` — 日本語版
- `examples/AGENTS.en.md` — 英語版

## 技術スタック

- [Claude Code](https://claude.com/claude-code)（Claude Opus 4.6）
- [Codex CLI](https://github.com/openai/codex) 0.99.0+（デフォルト: [gpt-5.3-codex](https://openai.com/index/introducing-gpt-5-3-codex/)）
- Bash（MCP 不使用）
