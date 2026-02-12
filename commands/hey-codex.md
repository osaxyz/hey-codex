---
name: hey-codex
description: Codex CLIと合議・実装委譲を行うスキル
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion
---

# hey-codex: Claude Code x Codex CLI Council

Codex CLIと合議・実装委譲を行うスキルです。

## Startup Flow

このスキルが呼び出されたら、以下の手順で起動してください:

### 1. Update Check

```bash
curl -fsSL https://raw.githubusercontent.com/osaxyz/hey-codex/main/install.sh | bash
```

アップデートチェックが失敗しても続行してください（ネットワーク不通の場合など）。

### 2. Codex CLI Status Check

council.sh のパスを特定し、ステータスを確認してください:

```bash
# インストール先の候補（優先順）:
# 1. プロジェクト直下: .claude/hey-codex/scripts/council.sh
# 2. ユーザーホーム: ~/.claude/hey-codex/scripts/council.sh
# 3. リポジトリ直下: scripts/council.sh (開発時)

council.sh status
```

#### Codex CLI が未インストールの場合

`council.sh status` の出力に `CODEX_NOT_INSTALLED` が含まれていたら、以下のフローを実行:

1. AskUserQuestion でユーザーに通知・確認:
   - **Install now** — `npm install -g @openai/codex` を実行してインストール
   - **Skip** — Codex なしで続行（矛盾チェックモードのみ利用可能）

2. Install now を選択された場合:
   ```bash
   npm install -g @openai/codex
   ```

3. インストール後、認証が必要。AskUserQuestion で認証方法を確認:
   - **API Key** — `OPENAI_API_KEY` 環境変数が設定済みなら `printenv OPENAI_API_KEY | codex login --with-api-key` を実行
   - **Skip auth** — 環境変数に `OPENAI_API_KEY` が既に設定されていればログイン不要で動作する場合がある。スキップして続行

   **注意:** `codex login`（ブラウザ認証）はターミナルからのリダイレクトが必要なため、Claude Code 内からは実行しない。ブラウザ認証が必要な場合はユーザーに手動実行を案内する。

4. `council.sh status` を再実行して確認

### 3. Load Skill Modules

以下のスキルモジュールを読み込んでください:

- `commands/skills/council-protocol.md` — 委譲プロトコル
- `commands/skills/contradiction-check.md` — 矛盾検出プロトコル

### 4. Mode Selection

AskUserQuestion でモードを選択してください:

**Options:**
- **Consult (合議)** — 設計・アーキテクチャの相談。Codexに意見を求め、Claude Codeの見解と比較して推奨を報告
- **Implement (実装委譲)** — コード生成をCodexに任せる。要件を明確にしてプロンプトを作成し、結果を報告
- **Check (矛盾チェック)** — AGENTS.md と CLAUDE.md の矛盾を検出・報告

### 5. Execute

選択されたモードに応じて実行してください:

#### Consult Mode
1. ユーザーの質問・相談内容を確認
2. プロンプトファイルを `/tmp/codex-prompt-XXXXX.txt` に書き出し
3. `council.sh consult <prompt_file> <workdir>` を実行
4. 結果を読み取り、Codex Council Report フォーマットで報告

#### Implement Mode
1. 実装要件を確認・明確化
2. プロンプトファイルを `/tmp/codex-prompt-XXXXX.txt` に書き出し
3. `council.sh implement <prompt_file> <workdir>` を実行
4. 変更されたファイルを確認し、Codex Council Report フォーマットで報告

#### Check Mode
1. `contradiction-check.md` の手順に従い矛盾を検出
2. 結果を報告

## Report Format

```markdown
## Codex Council Report

**Mode**: consult / implement
**Task**: [委譲した内容の要約]
**AGENTS.md**: detected / not found

### Codex Response
[Codexの回答]

### My Assessment (合議の場合)
[Claude Codeの見解との比較・推奨]

### Files Changed (実装委譲の場合)
[変更されたファイル一覧]
```

## council.sh Location

council.sh を見つけるために以下の順序で探索:
1. `.claude/hey-codex/scripts/council.sh` (プロジェクトローカル)
2. `~/.claude/hey-codex/scripts/council.sh` (ユーザーグローバル)
3. このリポジトリの `scripts/council.sh` (開発時)
