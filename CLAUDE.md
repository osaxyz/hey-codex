# hey-codex: Claude Code × Codex CLI Council

このプロジェクトは Claude Code と Codex CLI の合議・委譲スキルです。

## Auto-delegation Setup

council.sh を使って Codex CLI に自動委譲を行います。

### council.sh のパス

```
# 優先順位:
1. .claude/hey-codex/scripts/council.sh  (プロジェクトローカル)
2. ~/.claude/hey-codex/scripts/council.sh (ユーザーグローバル)
3. scripts/council.sh                     (開発時)
```

### 使い方

```bash
# ステータス確認
council.sh status

# 合議（読み取り専用）
council.sh consult /tmp/codex-prompt.txt /path/to/project

# 実装委譲（書き込み可能）
council.sh implement /tmp/codex-prompt.txt /path/to/project
```

### 自動委譲フロー

1. プロンプトファイルを `/tmp/codex-prompt-XXXXX.txt` に書き出し
2. `council.sh <mode> <prompt_file> <workdir>` を実行
3. 結果を読み取り、Codex Council Report フォーマットで報告

### 委譲判断基準

詳細は `commands/skills/council-protocol.md` を参照。

- **合議 (consult)**: アーキテクチャ判断、トレードオフ不明確、セキュリティ判断
- **実装委譲 (implement)**: ボイラープレート生成、大量コード、パターン反復

## Development

```bash
# テスト実行
scripts/council.sh status

# ローカルインストール
bash install.sh
```
